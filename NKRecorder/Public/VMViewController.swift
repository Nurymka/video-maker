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
    public static var shouldLoadFontsAtLaunch = true
    public weak var videoMakerDelegate: VideoMakerDelegate?
    
    public var topOffset: CGFloat = 0.0 { // controls the offset of the recorder ui elements at the top
        didSet {
            if recorderVC != nil && videoPlaybackVC != nil {
                if recorderVC.UIElementsTopConstraint != nil && videoPlaybackVC.UIElementsTopConstraint != nil {
                    recorderVC.UIElementsTopConstraint.constant = topOffset
                    videoPlaybackVC.UIElementsTopConstraint.constant = topOffset
                }
            }
        }
    }
    
    // fonts
    public static var regularWeightFontName = UIFont.systemFontOfSize(10).fontName {
        didSet {
            FontKit.regularWeightFontName = regularWeightFontName
        }
    }
    public static var mediumWeightFontName = UIFont.boldSystemFontOfSize(10).fontName {
        didSet {
            FontKit.mediumWeightFontName = mediumWeightFontName
        }
    }
    public static var boldWeightFontName = UIFont.boldSystemFontOfSize(10).fontName {
        didSet {
            FontKit.boldWeightFontName = boldWeightFontName
        }
    }
    
    var recorderVC: RecordViewController!
    var videoPlaybackVC: VideoPlaybackViewController!
    var currentFilter: SCFilter?
    @IBOutlet weak var activityIndicatorContainer: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    static let currentBundle = NSBundle(forClass: VideoMakerViewController.self)
    
    // available to recordViewController
    var sharedRecordSession: SCRecordSession?
    
    
// MARK: - Public
    public class func preloadRecorderAsynchronously() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == .Authorized {
                let recorder = SCRecorder.sharedRecorder()
                recorder.captureSessionPreset = AVCaptureSessionPreset640x480
                recorder.keepMirroringOnWrite = true
                recorder.startRunning()
                let session = SCRecordSession()
                session.fileType = AVFileTypeMPEG4
                recorder.session = session
            }
        }
    }
    
    public class func mainController() -> VideoMakerViewController {
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
        recorderVC = storyboard!.instantiateViewControllerWithIdentifier("Recorder") as! RecordViewController
        videoPlaybackVC = storyboard!.instantiateViewControllerWithIdentifier("Video Playback") as! VideoPlaybackViewController
        recorderVC.topOffsetConstant = topOffset
        videoPlaybackVC.topOffsetConstant = topOffset
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
        videoPlaybackVC.recordingDuration = recorder.scaledRecordedDuration
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
    let duration: NSTimeInterval
    
    public func export(completion: (NSURL, NSTimeInterval) -> ()) {
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
                completion(assetExport.outputUrl!, self.duration)
            }
            else {
                print("Video couldn't be exported: \(assetExport.error)")
            }
        })
    }
    
    public func exportWithFirstFrame(completion: (NSURL, UIImage, NSTimeInterval) -> ()) {
        export { exportedVideoURL, duration in
            
            let asset = AVURLAsset(URL: exportedVideoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            do {
                let CGImage = try imageGenerator.copyCGImageAtTime(CMTimeMake(0, 1), actualTime: nil)
                let image = UIImage(CGImage: CGImage)
                completion(exportedVideoURL, image, duration)
            } catch {
                print("AVAssetImageGenerator couldn't create a CGImage, completion block won't run: \(error)")
            }
        }
    }
}
