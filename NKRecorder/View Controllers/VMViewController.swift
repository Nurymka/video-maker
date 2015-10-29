//
//  VMViewController.swift
//  VideoMaker
//
//  Created by Tom on 10/28/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit
import SCRecorder

protocol VideoMakerDelegate: class {
    func videoMakerWillStartRecording(videoMaker: VideoMakerViewController)
    func videoMakerDidCancelRecording(videoMaker: VideoMakerViewController)
    func videoMaker(videoMaker: VideoMakerViewController, didProduceVideoSession session: NKVideoSession)
}

class VideoMakerViewController: UIViewController {
    var recorderVC: RecordViewController!
    var videoPlaybackVC: VideoPlaybackViewController!
    var currentFilter: SCFilter?
    weak var videoMakerDelegate: VideoMakerDelegate?
    
    @IBOutlet weak var activityIndicatorContainer: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        recorderVC = storyboard!.instantiateViewControllerWithIdentifier("Recorder") as! RecordViewController
        videoPlaybackVC = storyboard!.instantiateViewControllerWithIdentifier("Video Playback") as! VideoPlaybackViewController
        recorderVC.delegate = self
        videoPlaybackVC.delegate = self
        
        addChildViewController(recorderVC)
        addChildViewController(videoPlaybackVC)
        recorderVC.didMoveToParentViewController(self)
        videoPlaybackVC.didMoveToParentViewController(self)
        showRecorder()
    }
    
    override func prefersStatusBarHidden() -> Bool {
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
    
    func freezeAndShowIndicator() {
        activityIndicatorContainer.hidden = false
        activityIndicatorView.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    func unfreezeAndHideIndicator() {
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
        activityIndicatorContainer.hidden = true
        activityIndicatorView.stopAnimating()
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
    
    func videoPlayback(videoPlayback: VideoPlaybackViewController, didProduceVideoSession videoSession: NKVideoSession) {
        videoMakerDelegate?.videoMaker(self, didProduceVideoSession: videoSession)
    }
}

