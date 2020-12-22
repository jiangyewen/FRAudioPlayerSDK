#
#  Be sure to run `pod spec lint FRAudioPlayerSDK.podspec.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
  spec.name         = "FRAudioPlayerSDK"
  spec.version      = "0.0.1"
  spec.summary      = "A audio player build on AVPlayer"
  spec.description  = "A audio player build on AVPlayer"
  spec.homepage     = "https://github.com/jiangyewen/FRAudioPlayerSDK/"
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  spec.author             = { "yewenk" => "yewenk@gmail.com" }
  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/jiangyewen/FRAudioPlayerSDK.git", :branch => "master"} #:tag => "#{spec.version}" }

  spec.subspec 'source' do |ss|
    puts '.....FRAudioPlayerSDK..source........'
    ss.source_files = ["FRAudioPlayerSDK/**/*.{h,m,mm}"]
    ss.public_header_files = ["FRAudioPlayerSDK/**/*.h"]
  end

  spec.subspec 'framework' do |ss|
    puts '------FRAudioPlayerSDK-binary-------'
    ss.ios.vendored_framework   = 'framework/FRAudioPlayerSDK.framework'
  end
end
