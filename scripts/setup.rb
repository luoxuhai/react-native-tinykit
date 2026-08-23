module ReactNativeTinykit
  FEATURES = %w[
    Restart
    ThermalState
    Review
    KeepAwake
    ColorPicker
    Haptics
    Mail
  ].freeze

  ENV_KEY = "REACT_NATIVE_TINYKIT_FEATURES"
end

def setup_tinykit(features)
  unless features.is_a?(Array) && features.all? { |feature| feature.is_a?(String) }
    raise ArgumentError, "setup_tinykit expects an Array of feature names"
  end

  selected_features = features.uniq
  unknown_features = selected_features - ReactNativeTinykit::FEATURES

  unless unknown_features.empty?
    raise ArgumentError,
      "Unknown react-native-tinykit features: #{unknown_features.join(', ')}. " \
      "Available features: #{ReactNativeTinykit::FEATURES.join(', ')}"
  end

  ENV[ReactNativeTinykit::ENV_KEY] = selected_features.join(",")

  if defined?(Pod::UI)
    selection = selected_features.empty? ? "Core only" : selected_features.join(", ")
    Pod::UI.puts "[TinyKit] Enabled features: #{selection}"
  end
end
