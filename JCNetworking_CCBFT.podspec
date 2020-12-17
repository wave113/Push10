#
# Be sure to run `pod lib lint JCNetworking_CCBFT.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JCNetworking_CCBFT'
  s.version          = '0.2.7'
  s.summary          = 'A short description of JCNetworking_CCBFT.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/qinzixin/JCNetworking_CCBFT'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'qinzixin' => 'qinzixin.zb@ccbft.com' }
  s.source           = { :git => 'ssh://git@code.ccbft.cloud:22480/cocoapods/jcnetworking.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'JCNetworking_CCBFT/Classes/**/*'
  
  s.public_header_files = 'JCNetworking_CCBFT/Classes/**/*.h'
#  s.dependency 'JCFoundation'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  s.frameworks = "Foundation", "Security", "CoreTelephony", "UIKit", "SystemConfiguration", "MobileCoreServices", "CoreServices", "CoreGraphics", "WebKit"
end