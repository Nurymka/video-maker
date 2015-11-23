//
//  ViewController.swift
//  VideoMaker
//
//  Created by Tom on 9/3/15.
//  Copyright (c) 2015 Tom. All rights reserved.
//

import UIKit
import SCRecorder

protocol RecordViewControllerDelegate: class {
    func recorderWillStartRecording(recorder: RecordViewController)
    func recorderDidCancelRecording(recorder: RecordViewController)
    func recorder(recorder: RecordViewController, didRecordSession session: SCRecordSession)
}

class RecordViewController: BaseViewController {
    weak var delegate: RecordViewControllerDelegate?
    let kMaximumRecordingLength = 15.0
    let kMinimumRecordingLength = 1.0
    
    var varMaximumRecordingLength = 15.0
    @IBOutlet weak var UIElementsContainerView: UIElementsContainer!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var recordButton: RecordButton!
    @IBOutlet weak var timescaleButton: UIButton!
    @IBOutlet weak var deleteLastSegmentButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var audioTypeButton: AudioTypeButton!
    @IBOutlet weak var timescaleSegmentedControl: TimescaleSegmentedControl!
    @IBOutlet weak var timescaleSegmentedControlWrapper: TimescaleSegmentedControlWrapper!
    
    @IBOutlet weak var trackNameLabel: TrackNameLabel!
    @IBOutlet weak var trackNameLabelBG: UIView!
    @IBOutlet weak var editAudioButton: UIButton!

    @IBOutlet weak var snailImageView: UIImageView!
    @IBOutlet weak var horseImageView: UIImageView!

    @IBOutlet weak var UIElementsTopConstraint: NSLayoutConstraint!
    var topOffsetConstant: CGFloat = 0.0
    
    var recorder = SCRecorder.sharedRecorder()
    var recordSession: SCRecordSession?
    var player: AVAudioPlayer? // used for playing embedded music during recording
    
    // for storing the scaled recording duration
    var scaledRecordedDuration: Double = 0.0
    var previousDuration: CMTime?
    var recordedDurationRatio: Float {
        return Float(scaledRecordedDuration / varMaximumRecordingLength)
    }
    
    // microphone permissions
    var shouldShowMicrophoneNotEnabledAlert = false
    var microphoneNotEnabledAlert: UIAlertController?
    

    
// MARK: - View Controller Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        varMaximumRecordingLength = kMaximumRecordingLength
        
        //recorder.captureSessionPreset = SCRecorderTools.bestCaptureSessionPresetCompatibleWithAllDevices()
        recorder.previewView = previewView
        recorder.delegate = self
        recordButton.addGestureRecognizer(RecordButtonTouchGestureRecognizer(target: self, action: "recordViewTouchDetected:"))
        
        UILabel.my_appearanceWhenContainedIn(UIAlertController).setAppearanceFontForAlertController(nil)
        
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "doubleTapRecognized:")
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        previewView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        UIElementsTopConstraint.constant = topOffsetConstant
        
        prepareSession()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //navigationController?.setNavigationBarHidden(true, animated: true)
        print("musicTrackInfo: \(musicTrackInfo)")
        checkForMicrophoneAlert()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        recorder.previewViewFrameChanged()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        checkCamera()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareSession() {
        if (recordSession?.duration == kCMTimeZero) {
            scaledRecordedDuration = 0.0
            previousDuration = nil
            hideNavigationControlButtons()
            updateRecordingTime()
        }
        configureTrackNameLabelAndPlayer()
    }
    
    func checkForMicrophoneAlert() {
        let authStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio)
        if authStatus != .Authorized {
            self.microphoneNotEnabledAlert = UIAlertController(title: "Unable to access microphone", message: "Please remove restrictions on the microphone to have sound in your videos (Settings -> Privacy -> Microphone -> On).", preferredStyle: .Alert)
            
            self.microphoneNotEnabledAlert!.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
            shouldShowMicrophoneNotEnabledAlert = true
        } else if authStatus == .Authorized {
            shouldShowMicrophoneNotEnabledAlert = false
        }
    }
    
// MARK: - Camera Permissions
    
    func checkCamera() {
        let authStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        print("Camera: \(authStatus.rawValue)")
        switch authStatus {
        case .Authorized: checkMicrophone()
        case .Denied: alertForCameraAndMicrophoneAccessViaSetting()
        case .NotDetermined: requestForCameraAccessInitially()
        default: requestForCameraAccessInitially()
        }
    }
    
    func requestForCameraAccessInitially() {
        if AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).count > 0 {
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { granted in
                if !granted {
                    self.alertForCameraAndMicrophoneAccessViaSetting()
                }
            }
        }
    }
    
    func alertForCameraAndMicrophoneAccessViaSetting() {
        let alert = UIAlertController(title: "Oops", message: "Both camera & microphone access is required for recording", preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: "Okay", style: .Cancel) { alert in
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            })
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func checkMicrophone() {
        let authStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio)
        print("Microphone: \(authStatus.rawValue)")
        switch authStatus {
        case .Authorized: break
        case .Denied: alertForCameraAndMicrophoneAccessViaSetting()
        case .NotDetermined: requestForMicrophoneAccessInitially()
        default: requestForMicrophoneAccessInitially()
        }
    }
    
    func requestForMicrophoneAccessInitially() {
        if AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio).count > 0 {
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeAudio) { granted in
                if !granted {
                    self.alertForCameraAndMicrophoneAccessViaSetting()
                }
            }
        }
    }
    
// MARK: - Button Touch Handlers
    
    @IBAction func reverseCameraButtonPressed(sender: AnyObject) {
        recorder.switchCaptureDevices()
    }
    
    @IBAction func recordingFinished(sender: AnyObject) {
        recorder.pause {
            if let session = self.recorder.session {
                self.recordSession = session
                self.showVideo()
            }
            print("recordingFinished called")
        }
    }
    
    
    // TODO: - change retake button function to delete last segment
    @IBAction func retakeButtonPressed(sender: AnyObject) {
        if (recorder.session?.duration != kCMTimeZero) {
            if (sender is VideoPlaybackViewController) {
                audioTypeButton.buttonState = .OriginalSound
                musicTrackInfo = nil
                hideNavigationControlButtons()
                resetTimescaleSegmentedControl()
                configureTrackNameLabelAndPlayer()
            }
            recordButton.progress = 0.0
            recorder.pause()
            recorder.session?.cancelSession(nil)
            prepareSession()
        }
        delegate?.recorderDidCancelRecording(self)
    }
    
    func recordViewTouchDetected(touchDetector: RecordButtonTouchGestureRecognizer) {
        if shouldShowMicrophoneNotEnabledAlert {
            presentViewController(microphoneNotEnabledAlert!, animated: true, completion: nil)
            shouldShowMicrophoneNotEnabledAlert = false
        } else {
            if (touchDetector.state == .Began) {
                delegate?.recorderWillStartRecording(self)
                recorder.record()
                timescaleSegmentedControl.enabled = false
                if musicTrackInfo != nil {
                    player?.rate = getVideoTimeScaleFromUISegment(timescaleSegmentedControl.selectedSegmentIndex)
                    player?.play()
                }
            }
            else if (touchDetector.state == .Ended) {
                recorder.pause()
                timescaleSegmentedControl.enabled = true
                if musicTrackInfo != nil {
                    player?.pause()
                }
            }
        }
    }
    
    @IBAction func recordingSpeedValueChanged(sender: AnyObject) {
        let segmentedControl = sender as! UISegmentedControl
        print("Current timeScale: \(getVideoTimeScaleFromUISegment(segmentedControl.selectedSegmentIndex))")
    }
    
    // TODO: - make an acceptable pop out animation for segmented control
    @IBAction func timescaleButtonPressed(sender: AnyObject) {
        if timescaleSegmentedControlWrapper.layer.opacity == 0.0 {
            let fadeInAnim = AnimationKit.fadeIn()
            
            timescaleSegmentedControlWrapper.layer.addAnimation(fadeInAnim, forKey: "fadeIn")
            snailImageView.layer.addAnimation(fadeInAnim, forKey: "fadeIn")
            horseImageView.layer.addAnimation(fadeInAnim, forKey: "fadeIn")
            
            configureTimescaleSegmentedControlOpacity()
        } else if timescaleSegmentedControlWrapper.layer.opacity == 1.0 {
            let fadeOutAnim = AnimationKit.fadeOut()
            
            timescaleSegmentedControlWrapper.layer.addAnimation(fadeOutAnim, forKey: "fadeOut")
            snailImageView.layer.addAnimation(fadeOutAnim, forKey: "fadeOut")
            horseImageView.layer.addAnimation(fadeOutAnim, forKey: "fadeOut")
            
            configureTimescaleSegmentedControlOpacity()
        }
    }
    
    @IBAction func audioTypeButtonPressed(sender: AnyObject) {
        let actionSheetController = UIAlertController(title: nil, message: "You can only pick a song if you didn't record anything yet", preferredStyle: .ActionSheet)
        actionSheetController.view.tintColor = StyleKit.lightPurple

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            actionSheetController.dismissViewControllerAnimated(true, completion: nil)
        }
        actionSheetController.addAction(cancelAction)
        
        let originalSoundAction = UIAlertAction(title: "Original Sound", style: .Default) { (action) in
            self.audioTypeButton.buttonState = .OriginalSound
            self.musicTrackInfo = nil
            self.configureTrackNameLabelAndPlayer()
        }
        actionSheetController.addAction(originalSoundAction)
        
        let addMusicAction = UIAlertAction(title: "Pick a Song", style: .Default) { (action) in
            self.performSegueWithIdentifier("Choose Music Playlist", sender: self)
        }
        addMusicAction.enabled = (recorder.session?.duration == kCMTimeZero)
        actionSheetController.addAction(addMusicAction)
        
        let noSoundAction = UIAlertAction(title: "No Sound", style: .Default) { (action) in
            self.audioTypeButton.buttonState = .NoSound
            self.musicTrackInfo = nil
            self.configureTrackNameLabelAndPlayer()
        }
        actionSheetController.addAction(noSoundAction)
        
        presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    @IBAction func flashButtonPressed(sender: AnyObject) {
        recorder.flashMode = recorder.flashMode == .Off ? .Light : .Off
    }
    
    func doubleTapRecognized(recoginzer: UITapGestureRecognizer) {
        reverseCameraButtonPressed(self)
    }
    
// MARK: - Segue Related
    
    func showVideo() {
        delegate?.recorder(self, didRecordSession: self.recordSession!)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
// REMINDER: Show Video Playback segue is replaced with VideoMakerViewController's showVideoPlayback() method
//        if (segue.identifier == "Show Video Playback") {
//            let videoPlaybackViewController: VideoPlaybackViewController = segue.destinationViewController as! VideoPlaybackViewController
//            videoPlaybackViewController.recordSession = recordSession
//            videoPlaybackViewController.musicTrackInfo = musicTrackInfo
//            videoPlaybackViewController.initialAudioTypeButtonState = audioTypeButton.buttonState
//            videoPlaybackViewController.recordingDuration = scaledRecordedDuration
//
//        }
        if segue.identifier == "Choose Music Playlist" {
            let targetNavController = segue.destinationViewController as! UINavigationController
            let choosePlaylistViewController = targetNavController.topViewController as! ChoosePlaylistCollectionViewController
            choosePlaylistViewController.segueBackViewController = self
        }
    }

// MARK: - Time Related
    
    func updateRecordingTime() {
        if let duration = recorder.session?.duration {
            if let previousDuration = previousDuration {
                let deltaDuration = CMTimeSubtract(duration, previousDuration)
                scaledRecordedDuration += Double(CMTimeGetSeconds(deltaDuration)) * Double(getVideoTimeScaleFromUISegment(timescaleSegmentedControl.selectedSegmentIndex))
                recordButton.progress = recordedDurationRatio
                self.previousDuration = duration
            } else {
                previousDuration = duration
            }
        }
        
        if scaledRecordedDuration >= kMinimumRecordingLength {
            showNavigationControlButtons()
        }
        
        if scaledRecordedDuration >= varMaximumRecordingLength {
            recordingFinished(self)
        }
    }

    
    func getVideoTimeScaleFromUISegment(index: Int) -> Float {
        switch (index) {
        case TimescaleSegmentedControlIndex.x025.rawValue: return 4.0
        case TimescaleSegmentedControlIndex.x05.rawValue: return 2.0
        case TimescaleSegmentedControlIndex.x1.rawValue: return 1.0
        case TimescaleSegmentedControlIndex.x15.rawValue: return 0.75
        case TimescaleSegmentedControlIndex.x20.rawValue: return 0.5
        default: return 1.0
        }
    }
    
// MARK: - UI Related
    func configureTrackNameLabelAndPlayer() {
        if let musicTrackInfo = musicTrackInfo, musicDataURL = LocalMusicManager.returnMusicDataFromTrackId(trackId: musicTrackInfo.id) {
            audioTypeButton.buttonState = .PickSong
            trackNameLabel.changeScrollableTextTo(String.presentableArtistAndSongName(musicTrackInfo.artistName, songName: musicTrackInfo.trackName))
            trackNameLabel.layer.opacity = 1.0
            trackNameLabelBG.layer.opacity = 1.0
            editAudioButton.layer.opacity = 1.0
            do {
                try player = AVAudioPlayer(contentsOfURL: musicDataURL)
                player?.prepareToPlay()
                player?.enableRate = true
                if let duration = player?.duration {
                    varMaximumRecordingLength = duration < kMaximumRecordingLength ? duration : kMaximumRecordingLength
                }
            } catch {
                print("AVAudioPlayer couldn't be inited: \(error)")
            }
        } else {
            varMaximumRecordingLength = kMaximumRecordingLength
            trackNameLabel.changeScrollableTextTo("")
            trackNameLabel.layer.opacity = 0.0
            trackNameLabelBG.layer.opacity = 0.0
            editAudioButton.layer.opacity = 0.0
        }
    }
    
    func showNavigationControlButtons() {
        doneButton.layer.opacity = 1.0
        deleteLastSegmentButton.layer.opacity = 1.0
    }
    
    func hideNavigationControlButtons() {
        doneButton.layer.opacity = 0.0
        deleteLastSegmentButton.layer.opacity = 0.0
    }
    
    func configureTimescaleSegmentedControlOpacity() {
        if timescaleSegmentedControlWrapper.layer.opacity == 0.0 {
            timescaleSegmentedControlWrapper.layer.opacity = 1.0
            snailImageView.layer.opacity = 1.0
            horseImageView.layer.opacity = 1.0
        } else if timescaleSegmentedControlWrapper.layer.opacity == 1.0 {
            timescaleSegmentedControlWrapper.layer.opacity = 0.0
            snailImageView.layer.opacity = 0.0
            horseImageView.layer.opacity = 0.0
        }
    }
    
    func resetTimescaleSegmentedControl() {
        timescaleSegmentedControlWrapper.layer.opacity = 1.0
        configureTimescaleSegmentedControlOpacity()
        timescaleSegmentedControl.selectedSegmentIndex = TimescaleSegmentedControlIndex.x1.rawValue
    }
}

extension RecordViewController: SCRecorderDelegate {
    
    func recorder(recorder: SCRecorder, didReconfigureAudioInput audioInputError: NSError?) {
        print("Reconfigured audio input: \(audioInputError)")
    }
    
    func recorder(recorder: SCRecorder, didReconfigureVideoInput videoInputError: NSError?) {
        print("Reconfigured video input: \(videoInputError)")
    }
    
    func recorder(recorder: SCRecorder, didSkipVideoSampleBufferInSession session: SCRecordSession) {
        print("Skipped video buffer")
    }

    func recorder(recorder: SCRecorder, didAppendVideoSampleBufferInSession session: SCRecordSession) {
        updateRecordingTime()
    }
    
    func recorder(recorder: SCRecorder, didCompleteSegment segment: SCRecordSessionSegment?, inSession session: SCRecordSession, error: NSError?) {
        
    }
    
    func createSegmentInfoForRecorder(recorder: SCRecorder) -> [NSObject : AnyObject]? {
        return ["timescale" : getVideoTimeScaleFromUISegment(timescaleSegmentedControl.selectedSegmentIndex)]
    }
    
}
