#
# Be sure to run `pod lib lint FeathersjsClientSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FeathersjsClientSwift'
  s.version          = '1.0.0'
  s.summary          = 'Feathersjs Client for iOS wrote in swift 3.0'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Feathersjs Client for iOS wrote in swift 3.0. Working on socketIO iOS under the hood. The framework stable.
 This verions still under development because Feathersjs response has plenty ogf different formats and I still working on Response parser to handle it carefully. I set deployment target to 9.0 but it is possible to downgrade it if any requests will occure.
                       DESC

  s.homepage         = 'https://github.com/truebucha/FeathersjsClientSwift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Kanstantsin Bucha' => 'truebucha@gmail.com' }
  s.source           = { :git => 'https://github.com/truebucha/FeathersjsClientSwift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/truebucha'

  s.ios.deployment_target = '8.0'

  s.source_files = 'FeathersjsClientSwift/Classes/**/*.{swift}'
  
  # s.resource_bundles = {
  #   'FeathersjsClientSwift' => ['FeathersjsClientSwift/Assets/*.png']
  # }


  s.frameworks = 'Foundation'
  s.dependency 'Socket.IO-Client-Swift', '8.3.3'
end
