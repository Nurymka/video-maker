Pod::Spec.new do |s|

  s.name         = "NKRecorder"
  s.version      = "0.1.0"
  s.summary      = "An enchanced video recording experience for Taylr."
  s.description  = <<-DESC
                   DESC
  s.homepage     = "http://github.com/s10tv/video-maker"
  s.license      = "DUNNO"
  s.author             = { "Nurishka" => "nurim98@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "http://github.com/s10tv/video-maker.git", :tag => "#{s.version}" }
  s.source_files  = "NKRecorder/**/*.{swift,h,m}"

  s.resources = "NKRecorder/**/*.{storyboard,pdf,png,jpeg,jpg,ttf}"
  s.preserve_paths = "NKRecorder/**/*.xcassets"

  s.framework  = "UIKit"

  s.dependency 'SCRecorder', '~> 2.5'
  s.dependency 'Alamofire', '~> 3.1'
  s.dependency 'SDWebImage', '~> 3.7'
  s.dependency 'EZAudio', '~> 1.1.2'


end
