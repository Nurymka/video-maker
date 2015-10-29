platform :ios, '8.0'

source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
use_frameworks!

target :NKRecorder do
    link_with 'NKRecorder'
    pod 'SCRecorder', '2.5.3' # aspect fill doesn't work on 2.6.1 + crashes on 8.x.
    pod 'Alamofire', '~> 3.1'
    pod 'EZAudio', '~> 1.1.2'
    pod 'SDWebImage', '~> 3.7'
    target :VideoMaker do
        link_with 'VideoMaker'
        pod 'NKRecorder', :path => '~/Documents/Taylr/video-maker/'
    end

end
