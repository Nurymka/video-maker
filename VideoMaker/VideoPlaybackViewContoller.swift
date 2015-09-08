//
//  VideoPlaybackViewContoller.swift
//  VideoMaker
//
//  Created by Tom on 9/7/15.
//  Copyright (c) 2015 Tom. All rights reserved.
//

import Foundation
import UIKit

class VideoPlaybackViewController: UIViewController {
    
    @IBOutlet weak var videoPlaybackView: UIView!
    var recordSession: SCRecordSession?
    var player: SCPlayer?
    var playerLayer: AVPlayerLayer?

// MARK: - View Controller Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        player = SCPlayer()
        player?.setItemByAsset(recordSession?.assetRepresentingSegments())
        player?.loopEnabled = true
        playerLayer = AVPlayerLayer(player: player)
        videoPlaybackView.layer.addSublayer(playerLayer)
        
        // add "save to camera roll" button on the right side
        var btnSaveToCameraRoll = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveToCameraRollPressed:")
        navigationItem.rightBarButtonItem = btnSaveToCameraRoll
    }
    
    override func viewWillAppear(animated: Bool) {
        player?.play()
    }
    
    override func viewDidLayoutSubviews() {
        playerLayer?.frame = videoPlaybackView.bounds
    }
    
    override func viewWillDisappear(animated: Bool) {
        player?.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - Button Touch Handlers
    
    func saveToCameraRollPressed(sender: AnyObject)
    {
        player?.pause()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        let segmentsAsset = recordSession?.assetRepresentingSegments()
        var assetExport = SCAssetExportSession()
        if let asset = segmentsAsset {
            assetExport = SCAssetExportSession(asset: asset)
        }
        assetExport.outputUrl = recordSession?.outputUrl
        assetExport.outputFileType = AVFileTypeMPEG4
        assetExport.videoConfiguration.preset = SCPresetHighestQuality
        
        let timestamp = CACurrentMediaTime()
        assetExport.exportAsynchronouslyWithCompletionHandler({
            println(String(format: "Completed compression in %fs", CACurrentMediaTime() - timestamp))
            if (assetExport.error == nil) {
                UISaveVideoAtPathToSavedPhotosAlbum(assetExport.outputUrl?.path, self, "video:didFinishSavingWithError:contextInfo:", nil)
            }
            else {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                UIAlertView(title: "Failed to save", message:assetExport.error?.localizedDescription, delegate: nil, cancelButtonTitle: "Okay").show()
            }
        })
    }
    
// MARK: - Misc
    
    func video(videoPath: NSString?, didFinishSavingWithError error: NSError?, contextInfo: UnsafePointer<()>) {
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
        
        if (error == nil) {
            UIAlertView(title: "Saved to camera roll", message:"", delegate: nil, cancelButtonTitle: "Done").show()
        } else {
            UIAlertView(title: "Failed to save", message: "'", delegate: nil, cancelButtonTitle: "Okay").show()
        }
    }
}