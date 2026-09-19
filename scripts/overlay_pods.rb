require "json"

module TinykitOverlayPods
  # Upstream release tags contain newer source code, but still declare the
  # previous CocoaPods version. Keep that metadata version for resolution and
  # pin the official Git tag below to actually install the latest release.
  DEPENDENCIES = {
    "Toast" => {
      :name => "SPIndicator", :version => "1.6.4", :tag => "1.6.5",
      :git => "https://github.com/ivanvorobei/SPIndicator.git",
    },
    "Alert" => {
      :name => "SPAlert", :version => "5.1.8", :tag => "5.1.9",
      :git => "https://github.com/sparrowcode/AlertKit.git",
    },
    "Confetti" => {
      :name => "SPConfetti", :version => "1.4.0", :tag => "1.4.2",
      :git => "https://github.com/ivanvorobei/SPConfetti.git",
    },
  }.freeze
end

# Call inside the application's Podfile target before use_native_modules!.
def tinykit_overlay_pods!(app_path:)
  package_path = File.join(File.expand_path(app_path), "package.json")
  package = JSON.parse(File.read(package_path))
  config = package["react-native-tinykit"]
  features = nil

  unless config.nil?
    unless config.is_a?(Hash) && config["features"].is_a?(Array) &&
        config["features"].all? { |feature| feature.is_a?(String) }
      raise "react-native-tinykit.features in #{package_path} must be an array of strings"
    end
    features = config["features"]
  end

  TinykitOverlayPods::DEPENDENCIES.each do |feature, dependency|
    next unless features.nil? || features.include?(feature)

    pod dependency[:name], :git => dependency[:git], :tag => dependency[:tag]
  end
end
