require "minitest/autorun"
require "tmpdir"
require "cocoapods"
require_relative "../scripts/overlay_pods"

# React Native's own dependencies are outside this Pod-selection regression test.
def install_modules_dependencies(spec); end

class OverlayPodsTest < Minitest::Test
  EXPECTED = {
    "Toast" => ["SPIndicator", "1.6.4", "1.6.5"],
    "Alert" => ["SPAlert", "5.1.8", "5.1.9"],
    "Confetti" => ["SPConfetti", "1.4.0", "1.4.2"],
  }.freeze

  def with_config(config)
    Dir.mktmpdir("tinykit-pod-test") do |directory|
      File.write(File.join(directory, "package.json"), JSON.generate(config))
      previous_path = ENV["APP_PATH"]
      ENV["APP_PATH"] = directory
      begin
        yield directory
      ensure
        previous_path.nil? ? ENV.delete("APP_PATH") : ENV["APP_PATH"] = previous_path
      end
    end
  end

  def check_selection(config, selected)
    with_config(config) do |directory|
      podfile = Pod::Podfile.new do
        target "App" do
          tinykit_overlay_pods!(app_path: directory)
        end
      end
      spec = Pod::Specification.from_file(File.expand_path("../react-native-tinykit.podspec", __dir__))
      expected_names = selected.map { |feature| EXPECTED.fetch(feature).first }.sort
      assert_equal expected_names, podfile.dependencies.map(&:name).sort
      assert_equal expected_names, spec.dependencies.map(&:name).sort

      selected.each do |feature|
        name, version, tag = EXPECTED.fetch(feature)
        dependency = podfile.dependencies.find { |item| item.name == name }
        assert_equal tag, dependency.external_source[:tag]
        assert_match %r{\Ahttps://github.com/}, dependency.external_source[:git]
        assert spec.dependencies.find { |item| item.name == name }.requirement.satisfied_by?(Pod::Version.new(version))
        assert_includes spec.attributes_hash.fetch("source_files"), "ios/#{feature}/**/*.{h,m,mm,swift,cpp}"
      end
      (EXPECTED.keys - selected).each do |feature|
        refute_includes spec.attributes_hash.fetch("source_files"), "ios/#{feature}/**/*.{h,m,mm,swift,cpp}"
      end
    end
  end

  def test_every_overlay_subset_selects_matching_sources_and_git_dependencies
    (0...8).each do |mask|
      selected = EXPECTED.keys.each_with_index.filter_map { |feature, index| feature if mask[index] == 1 }
      check_selection({ "react-native-tinykit" => { "features" => selected } }, selected)
    end
  end

  def test_default_enables_all_overlays
    check_selection({}, EXPECTED.keys)
  end

  def test_existing_features_do_not_install_overlay_dependencies
    check_selection({ "react-native-tinykit" => { "features" => ["Haptics", "Mail"] } }, [])
  end

  def test_invalid_feature_configuration_fails_early
    with_config({ "react-native-tinykit" => { "features" => "Toast" } }) do |directory|
      error = assert_raises(RuntimeError) { tinykit_overlay_pods!(app_path: directory) }
      assert_match(/must be an array of strings/, error.message)
    end
  end

  def test_translation_uses_only_system_frameworks_and_can_be_excluded
    check_selection({ "react-native-tinykit" => { "features" => ["Translation"] } }, [])
    [[], ["Translation"]].each do |features|
      with_config({ "react-native-tinykit" => { "features" => features } }) do
        spec = Pod::Specification.from_file(File.expand_path("../react-native-tinykit.podspec", __dir__))
        attributes = spec.attributes_hash
        enabled = features.include?("Translation")
        assert_equal enabled, attributes.fetch("source_files").include?("ios/Translation/**/*.{h,m,mm,swift,cpp}")
        assert_equal enabled, attributes.fetch("frameworks", []).include?("SwiftUI")
        assert_equal enabled, attributes.fetch("weak_frameworks", []).include?("Translation")
        assert_equal enabled, attributes.fetch("pod_target_xcconfig").fetch("GCC_PREPROCESSOR_DEFINITIONS").include?("TINYKIT_FEATURE_TRANSLATION=1")
        assert_empty spec.dependencies
      end
    end
  end
end
