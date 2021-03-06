#
# Be sure to run `pod lib lint JSApiSdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JSApiSdk'
  s.version          = '1.1.2'
  s.summary          = 'JSApiSdk contains the structure of API calling and easy to use it.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/jinals9999/JSApiSdk'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jinals9999' => 'jinal.s@cearsinfotech.com' }
  s.source           = { :git => 'https://github.com/jinals9999/JSApiSdk.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '12.1'

  s.source_files = 'Classes/**/*'

  s.dependency 'Alamofire', '~> 5.2'
  
  # s.resource_bundles = {
  #   'JSApiSdk' => ['JSApiSdk/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
