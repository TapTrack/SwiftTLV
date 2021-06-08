#
# Be sure to run `pod lib lint SwiftTLV.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftTLV'
  s.version          = '1.0.0'
  s.summary          = 'Swift library for working with Tag-Length-Value (TLV) encoded data'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Tag-Length-Value (TLV) encoded data is a useful format for encoding multi-field data into byte (UInt8) arrays.  This library provides tools for working with TLV data both in byte array and struct forms (including methods to convert between forms). This library supports both single byte and dual byte tags as well as single byte and dual byte tags.
                       DESC

  s.homepage         = 'https://github.com/TapTrack/SwiftTLV'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { 'dshalaby' => 'dave@taptrack.com' }
  s.source           = { :git => 'https://github.com/TapTrack/SwiftTLV.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/TapTrack'

  s.ios.deployment_target = '12.0'
  s.swift_versions = "5.0"

  s.source_files = 'SwiftTLV/Classes/**/*'
end
