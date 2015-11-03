//
//  VideoMakerRootViewController.swift
//  VideoMaker
//
//  Created by Tom on 10/24/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit
import NKRecorder

class ExampleVideoMakerViewController: UIViewController {
    var videoMakerVC: VideoMakerViewController = VideoMakerViewController.mainController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoMakerVC.videoMakerDelegate = self
        addChildViewController(videoMakerVC)
        view.addSubview(videoMakerVC.view)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

extension ExampleVideoMakerViewController: VideoMakerDelegate {
    func videoMakerWillStartRecording(videoMaker: VideoMakerViewController) {
        
    }
    
    func videoMakerDidCancelRecording(videoMaker: VideoMakerViewController) {
        
    }
    
    func videoMaker(videoMaker: VideoMakerViewController, didProduceVideoSession session: VideoSession) {
        videoMakerVC.freezeAndShowIndicator()
        session.export() { (outputURL) in
            UISaveVideoAtPathToSavedPhotosAlbum(outputURL.path!, self, "video:didFinishSavingWithError:contextInfo:", nil)
        }
    }
    
    func video(videoPath: NSString?, didFinishSavingWithError error: NSError?, contextInfo: UnsafePointer<()>) {
        videoMakerVC.unfreezeAndHideIndicator()
        if (error == nil) {
            UIAlertView(title: "Saved to camera roll", message:"", delegate: nil, cancelButtonTitle: "Done").show()
        } else {
            UIAlertView(title: "Failed to save", message: "'", delegate: nil, cancelButtonTitle: "Okay").show()
        }
    }
}
