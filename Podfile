platform :ios, '8.0'

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/s10tv/video-maker.git'

inhibit_all_warnings!
use_frameworks!

target :NKRecorder do
    link_with 'NKRecorder'
    pod 'SCRecorder'
    pod 'Alamofire', '~> 2.0'
    pod 'SwiftyJSON'
    pod 'AlamofireImage', '~> 1.0'
    pod 'RBBAnimation', '0.4.0'
    pod 'EZAudio', '~> 1.1.2'

    target :VideoMaker do
        link_with 'VideoMaker'
        pod 'NKRecorder', :path => '~/Documents/Taylr/video-maker/'
    end

end
