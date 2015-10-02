//
//  ViewController.swift
//  VideoMaker
//
//  Created by Tom on 9/3/15.
//  Copyright (c) 2015 Tom. All rights reserved.
//

import UIKit
import SCRecorder

class RecordViewController: UIViewController {
    //let kMaximumRecordingLength = 15.0
    let kMinimumRecordingLength = 5.0
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var tapToRecordView: UIView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var recordingTimeLabel: UILabel!
    @IBOutlet weak var recordingSpeedSegmentedControl: UISegmentedControl!
    
    var recorder: SCRecorder!
    var recordSession: SCRecordSession?
    var scaledRecordedDuration: Double = 0.0
    var previousDuration: CMTime?
    // MARK: - View Controller Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        recorder = SCRecorder()
        if !recorder.startRunning() {
            print("something went wrong: \(recorder.error)")
        }
        recorder.captureSessionPreset = SCRecorderTools.bestCaptureSessionPresetCompatibleWithAllDevices()
        recorder.previewView = previewView
        recorder.delegate = self
        tapToRecordView.addGestureRecognizer(RecordButtonTouchGestureRecognizer(target: self, action: "recordViewTouchDetected:"))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBarHidden = true
        prepareSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        recorder.previewViewFrameChanged()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        recorder.startRunning()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        recorder.stopRunning()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.navigationBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Button Touch Handlers
    @IBAction func reverseCameraButtonPressed(sender: AnyObject) {
        recorder.switchCaptureDevices()
    }
    
    func recordViewTouchDetected(touchDetector: RecordButtonTouchGestureRecognizer) {
        if (touchDetector.state == .Began) {
            recorder.record()
            recordingSpeedSegmentedControl.enabled = false
        }
        else if (touchDetector.state == .Ended) {
            recorder.pause()
            recordingSpeedSegmentedControl.enabled = true
        }
    }
    
    @IBAction func recordingFinished(sender: AnyObject) {
        recorder.pause {
            if let session = self.recorder.session {
                self.recordSession = session
                self.showVideo()
            }
        }
    }
    
    @IBAction func retakeButtonPressed(sender: AnyObject) {
        if (recorder.session != nil) {
            recorder.pause()
            recorder.session?.cancelSession({})
            recorder.session = nil
            prepareSession()
        }
    }
    
    @IBAction func recordingSpeedValueChanged(sender: AnyObject) {
        let segmentedControl = sender as! UISegmentedControl
        
        print("Current timeScale: \(getVideoTimeScaleFromUISegment(segmentedControl.selectedSegmentIndex))")
    }
    
    // MARK: - Misc
    func prepareSession() {
        if (recorder.session == nil)
        {
            let session = SCRecordSession()
            session.fileType = AVFileTypeMPEG4
            recorder.session = session
            scaledRecordedDuration = 0.0
            previousDuration = nil
            updateRecordingTime()
        }
    }
    
    func showVideo() {
        performSegueWithIdentifier("Show Video", sender: self)
    }
    
    func updateRecordingTime() {
        if let duration = recorder.session?.duration {
            if let previousDuration = previousDuration {
                let deltaDuration = CMTimeSubtract(duration, previousDuration)
                scaledRecordedDuration += Double(CMTimeGetSeconds(deltaDuration)) * Double(getVideoTimeScaleFromUISegment(recordingSpeedSegmentedControl.selectedSegmentIndex))
                recordingTimeLabel.text = String(format: "Recording Time: %0.2f", scaledRecordedDuration)
                self.previousDuration = duration
            } else {
                recordingTimeLabel.text = String(format: "Recording Time: %0.2f", scaledRecordedDuration)
                previousDuration = duration
            }
        }
        
        if scaledRecordedDuration >= kMinimumRecordingLength {
            doneButton.enabled = true
        } else {
            doneButton.enabled = false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "Show Video") {
            let videoPlaybackViewController: VideoPlaybackViewController = segue.destinationViewController as! VideoPlaybackViewController
            videoPlaybackViewController.recordSession = recordSession
        }
    }
    
    func getVideoTimeScaleFromUISegment(index: Int) -> Float {
        switch (index) {
        case 0: return 4.0
        case 1: return 2.0
        case 2: return 1.0
        case 3: return 0.75
        case 4: return 0.5
        default: return 1.0
        }
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

    func recorder(recorder: SCRecorder, didAppendVideoSampleBufferInSession session: SCRecordSession)
    {
        updateRecordingTime()
    }
    
    func createSegmentInfoForRecorder(recorder: SCRecorder) -> [NSObject : AnyObject]? {
        return ["timescale" : getVideoTimeScaleFromUISegment(recordingSpeedSegmentedControl.selectedSegmentIndex)]
    }
    
}
