require "json"

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

configured_features = ENV["REACT_NATIVE_TINYKIT_FEATURES"]
selected_feature_names = if configured_features.nil?
  features.keys
else
  configured_features.split(",").map(&:strip).reject(&:empty?)
end

unknown_features = selected_feature_names - features.keys
unless unknown_features.empty?
  raise "Unknown react-native-tinykit features: #{unknown_features.join(', ')}"
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
