//
//  ViewController.swift
//  VideoMaker
//
//  Created by Tom on 9/3/15.
//  Copyright (c) 2015 Tom. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class ViewController: UIViewController, SCRecorderDelegate {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var tapToRecordView: UIView!
    var recorder: SCRecorder!
    
// MARK: - View Controller Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recorder = SCRecorder()
        if (!recorder.startRunning())
        {
            println("something went wrong: \(recorder.error)")
        }
        recorder.captureSessionPreset = SCRecorderTools.bestCaptureSessionPresetCompatibleWithAllDevices()
        recorder.previewView = previewView
        recorder.delegate = self
        
        tapToRecordView.addGestureRecognizer(RecordButtonTouchHandler(target: self, action: "recordViewTouchDetected:"))
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
// MARK: - Recorder delegate methods
    
    func recorder(recorder: SCRecorder, didSkipVideoSampleBufferInSession session: SCRecordSession) {
        println("Skipped video buffer")
    }
    
    func recorder(recorder: SCRecorder, didReconfigureAudioInput audioInputError: NSError?) {
        
        println("Reconfigured audio input: \(audioInputError)")
    }
    
    func recorder(recorder: SCRecorder, didReconfigureVideoInput videoInputError: NSError?) {
        println("Reconfigured video input: \(videoInputError)")
    }
    
// MARK: - Button Touch Handlers
    @IBAction func reverseCameraButtonPressed(sender: AnyObject) {
        recorder.switchCaptureDevices()
    }
    
    func recordViewTouchDetected(touchDetector: RecordButtonTouchHandler) {
        if (touchDetector.state == .Began) {
            recorder.record()
        }
        else if (touchDetector.state == .Ended) {
            recorder.pause()
        }
    }
    
// MARK: - Misc
    func prepareSession() {
        if (recorder.session == nil)
        {
            var session = SCRecordSession()
            session.fileType = AVFileTypeMPEG4
            recorder.session = session
        }
    }
    
}
