require "json"
require "pathname"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

features = {
  "Restart" => {
    :source_files => "ios/Restart/**/*.{h,m,mm,swift,cpp}",
    :definition => "TINYKIT_FEATURE_RESTART=1",
  },
  "ThermalState" => {
    :source_files => "ios/ThermalState/**/*.{h,m,mm,swift,cpp}",
    :definition => "TINYKIT_FEATURE_THERMAL_STATE=1",
  },
  "Review" => {
    :source_files => "ios/Review/**/*.{h,m,mm,swift,cpp}",
    :definition => "TINYKIT_FEATURE_REVIEW=1",
    :frameworks => ["StoreKit", "UIKit"],
  },
  "KeepAwake" => {
    :source_files => "ios/KeepAwake/**/*.{h,m,mm,swift,cpp}",
    :definition => "TINYKIT_FEATURE_KEEP_AWAKE=1",
    :frameworks => ["UIKit"],
  },
  "ColorPicker" => {
    :source_files => "ios/ColorPicker/**/*.{h,m,mm,swift,cpp}",
    :definition => "TINYKIT_FEATURE_COLOR_PICKER=1",
    :frameworks => ["UIKit"],
  },
  "Haptics" => {
    :source_files => "ios/Haptics/**/*.{h,m,mm,swift,cpp}",
    :definition => "TINYKIT_FEATURE_HAPTICS=1",
    :frameworks => ["UIKit"],
  },
  "Mail" => {
    :source_files => "ios/Mail/**/*.{h,m,mm,swift,cpp}",
    :definition => "TINYKIT_FEATURE_MAIL=1",
    :frameworks => ["MessageUI", "UIKit", "UniformTypeIdentifiers"],
  },
}

configured_features = nil
app_path = ENV["APP_PATH"]

unless app_path.nil? || app_path.empty?
  app_root = Pathname.new(app_path)
  unless app_root.absolute?
    app_root = Pod::Config.instance.installation_root.join(app_root)
  end

  app_package_path = app_root.join("package.json").cleanpath
  if app_package_path.file?
    app_package = JSON.parse(File.read(app_package_path))
    tinykit_config = app_package["react-native-tinykit"]

    unless tinykit_config.nil?
      unless tinykit_config.is_a?(Hash)
        raise "react-native-tinykit in #{app_package_path} must be an object"
      end

      configured_features = tinykit_config["features"]
      unless configured_features.is_a?(Array) && configured_features.all? { |feature| feature.is_a?(String) }
        raise "react-native-tinykit.features in #{app_package_path} must be an array of strings"
      end
    end
  end
end

selected_feature_names = configured_features.nil? ? features.keys : configured_features.uniq

unknown_features = selected_feature_names - features.keys
unless unknown_features.empty?
  raise "Unknown react-native-tinykit features: #{unknown_features.join(', ')}. " \
    "Available features: #{features.keys.join(', ')}"
end

if defined?(Pod::UI)
  selection = selected_feature_names.empty? ? "Core only" : selected_feature_names.join(", ")
  source = configured_features.nil? ? "defaults" : "package.json"
  Pod::UI.puts "[TinyKit] Enabled features from #{source}: #{selection}"
end

selected_features = selected_feature_names.map { |name| features.fetch(name) }
source_files = ["ios/Core/**/*.{h,m,mm,swift,cpp}"] + selected_features.map { |feature| feature[:source_files] }
definitions = selected_features.map { |feature| feature[:definition] }
frameworks = selected_features.flat_map { |feature| feature.fetch(:frameworks, []) }.uniq

Pod::Spec.new do |s|
  s.name         = "react-native-tinykit"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "16.0" }
  s.source       = { :git => "https://github.com/luoxuhai/react-native-tinykit.git", :tag => "#{s.version}" }

  s.source_files = source_files
  s.private_header_files = "ios/Core/**/*.h"
  s.frameworks = frameworks unless frameworks.empty?
  s.pod_target_xcconfig = {
    "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) #{definitions.join(' ')}",
  }

  install_modules_dependencies(s)
end
