#
# Be sure to run `pod lib lint TactileSlider.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TactileSlider'
  s.version          = '1.1.0'
  s.summary          = 'Easy-to-grab slider control inspired by Control Center and HomeKit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
A slider control designed to be easy to grab and use because it can be dragged or tapped from anywhere along its track, similar to the sliders in Control Center and HomeKit.
                       DESC

  s.homepage         = 'https://github.com/daprice/iOS-Tactile-Slider'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Dale Price' => 'daprice@mac.com' }
  s.source           = { :git => 'https://github.com/daprice/iOS-Tactile-Slider.git', :tag => s.version.to_s }
  s.social_media_url = 'https://mastodon.technology/@dale_price'

  s.ios.deployment_target = '8.0'
  s.swift_version = '4.2'

  s.source_files = 'TactileSlider/Classes/**/*'
  
  # s.resource_bundles = {
  #   'TactileSlider' => ['TactileSlider/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
