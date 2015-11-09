//
//  VMViewController.swift
//  VideoMaker
//
//  Created by Tom on 10/28/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit
import SCRecorder

public protocol VideoMakerDelegate: class {
    func videoMakerWillStartRecording(videoMaker: VideoMakerViewController)
    func videoMakerDidCancelRecording(videoMaker: VideoMakerViewController)
    func videoMaker(videoMaker: VideoMakerViewController, didProduceVideoSession session: VideoSession)
}

public final class VideoMakerViewController: UIViewController {
    var recorderVC: RecordViewController!
    var videoPlaybackVC: VideoPlaybackViewController!
    var currentFilter: SCFilter?
    public weak var videoMakerDelegate: VideoMakerDelegate?
    
    @IBOutlet weak var activityIndicatorContainer: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    public static var shouldLoadFontsAtLaunch = true
    static let currentBundle = NSBundle(forClass: VideoMakerViewController.self)
    
    // available to recordViewController
    var mainRecordSession: SCRecordSession?
// MARK: - Public
    public class func mainController() -> VideoMakerViewController {
        if shouldLoadFontsAtLaunch == true {
            var once: dispatch_once_t = 0
            dispatch_once(&once) {
                loadCustomFonts()
            }
        }
        let main = UIStoryboard(name: "Main", bundle: currentBundle)
        return main.instantiateViewControllerWithIdentifier("VideoMakerViewController") as! VideoMakerViewController
    }
    
    public func pauseVideo() {
        videoPlaybackVC.player?.pause()
    }
    
    public func resumeVideo() {
        videoPlaybackVC.player?.play()
    }
    
    // adds a spinning activity indicator
    public func freezeAndShowIndicator() {
        activityIndicatorContainer.hidden = false
        activityIndicatorView.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    // removes the spinning activity indicator
    public func unfreezeAndHideIndicator() {
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
        activityIndicatorContainer.hidden = true
        activityIndicatorView.stopAnimating()
    }
    
// MARK: - Internal
    override public func viewDidLoad() {
        super.viewDidLoad()
        mainRecordSession = SCRecordSession()
        mainRecordSession?.fileType = AVFileTypeMPEG4
        recorderVC = storyboard!.instantiateViewControllerWithIdentifier("Recorder") as! RecordViewController
        recorderVC.recordSession = mainRecordSession
        videoPlaybackVC = storyboard!.instantiateViewControllerWithIdentifier("Video Playback") as! VideoPlaybackViewController
        recorderVC.delegate = self
        videoPlaybackVC.delegate = self
        
        addChildViewController(recorderVC)
        addChildViewController(videoPlaybackVC)
        recorderVC.didMoveToParentViewController(self)
        videoPlaybackVC.didMoveToParentViewController(self)
        showRecorder()
    }
    
    override public func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func showRecorder() {
        videoPlaybackVC.view.removeFromSuperview()
        view.insertSubview(recorderVC.view, atIndex: 0)
    }
    
    func showVideoPlayback() {
        recorderVC.view.removeFromSuperview()
        view.insertSubview(videoPlaybackVC.view, atIndex: 0)
    }
    
    private static func loadCustomFonts() {
        func iterateEnum<T: Hashable>(_: T.Type) -> AnyGenerator<T> {
            var i = 0
            return anyGenerator {
                let next = withUnsafePointer(&i) { UnsafePointer<T>($0).memory }
                return next.hashValue == i++ ? next : nil
            }
        }
        
        for font in iterateEnum(R.Fonts.self) {
            let fontURL = currentBundle.URLForResource(font.rawValue, withExtension: ".ttf")
            // loading custom fonts programatically: http://www.marco.org/2012/12/21/ios-dynamic-font-loading
            if let fontData = NSData(contentsOfURL: fontURL!) {
                let provider = CGDataProviderCreateWithCFData(fontData as CFDataRef)
                let font = CGFontCreateWithDataProvider(provider)
                var error: Unmanaged<CFError>?
                if (!CTFontManagerRegisterGraphicsFont(font!, &error)) {
                    print("Failed to register font: \(error)")
                }
            }
        }
    }

}

extension VideoMakerViewController: RecordViewControllerDelegate {
    func recorderWillStartRecording(recorder: RecordViewController) {
        videoMakerDelegate?.videoMakerWillStartRecording(self)
    }
    
    func recorderDidCancelRecording(recorder: RecordViewController) {
        videoMakerDelegate?.videoMakerDidCancelRecording(self)
    }
    
    func recorder(recorder: RecordViewController, didRecordSession session: SCRecordSession) {
        videoPlaybackVC.recordSession = session
        videoPlaybackVC.musicTrackInfo = recorder.musicTrackInfo
        videoPlaybackVC.initialAudioTypeButtonState = recorder.audioTypeButton.buttonState
        showVideoPlayback()
    }
}

extension VideoMakerViewController: VideoPlaybackViewControllerDelegate {
    func videoPlaybackDidCancel(videoPlayback: VideoPlaybackViewController) {
        recorderVC.retakeButtonPressed(videoPlayback)
        showRecorder()
    }
    
    func videoPlayback(videoPlayback: VideoPlaybackViewController, didProduceVideoSession videoSession: VideoSession) {
        videoMakerDelegate?.videoMaker(self, didProduceVideoSession: videoSession)
    }
}

public struct VideoSession {
    let recordSession: SCRecordSession
    let composition: AVComposition
    let overlayImage: UIImage?
    let overlayImagePosition: CGPoint?
    let filter: SCFilter?
    
    public func export(completion: (NSURL) -> ()) {
        let assetExport = SCAssetExportSession(asset: composition)
        assetExport.outputUrl = recordSession.outputUrl
        assetExport.outputFileType = AVFileTypeMPEG4
        assetExport.audioConfiguration.preset = SCPresetHighestQuality
        //assetExport.videoConfiguration.preset = SCPresetHighestQuality
        assetExport.videoConfiguration.filter = filter
        if let overlayImage = overlayImage {
            assetExport.videoConfiguration.watermarkImage = overlayImage
            assetExport.videoConfiguration.watermarkFrame = CGRect(x: 0, y: 0, width: 480, height: 640) // FIXME: HAX - 640x480 hardcoded
        }
        assetExport.videoConfiguration.maxFrameRate = 35
        let timestamp = CACurrentMediaTime()
        assetExport.exportAsynchronouslyWithCompletionHandler({
            print(String(format: "Completed compression in %fs", CACurrentMediaTime() - timestamp))
            if (assetExport.error == nil) {
                completion(assetExport.outputUrl!)
            }
            else {
                print("Video couldn't be exported: \(assetExport.error)")
            }
        })
    }
    
    public func exportWithFirstFrame(completion: (NSURL, UIImage) -> ()) {
        export { exportedVideoURL in
            let asset = AVURLAsset(URL: exportedVideoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            do {
                let CGImage = try imageGenerator.copyCGImageAtTime(CMTimeMake(0, 1), actualTime: nil)
                let image = UIImage(CGImage: CGImage)
                completion(exportedVideoURL, image)
            } catch {
                print("AVAssetImageGenerator couldn't create a CGImage, completion block won't run: \(error)")
            }
        }
    }
}
