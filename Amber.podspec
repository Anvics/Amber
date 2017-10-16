#
# Be sure to run `pod lib lint Amber.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Amber'
  s.version          = '1.0.1'
  s.summary          = 'flexible and convenient iOS architecture based on Flex & Elm'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Amber is flexible architecture based on Elm & Flux ideas and developed specifically for iOS.
DESC

  s.homepage         = 'https://github.com/Anvics/Amber'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Nikita Arkhipov' => 'nikitarkhipov@gmail.com' }
  s.source           = { :git => 'https://github.com/Anvics/Amber.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'Amber/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Amber' => ['Amber/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
  s.dependency 'Bond', '~> 6.3.0'
end
