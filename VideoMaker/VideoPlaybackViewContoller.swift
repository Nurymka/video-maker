//
//  VideoPlaybackViewContoller.swift
//  VideoMaker
//
//  Created by Tom on 9/7/15.
//  Copyright (c) 2015 Tom. All rights reserved.
//

import Foundation
import UIKit
import SCRecorder

class VideoPlaybackViewController: UIViewController {
    
    @IBOutlet weak var filterSwipableView: SCSwipeableFilterView!
    var recordSession: SCRecordSession?
    var player: SCPlayer?
    var playerLayer: AVPlayerLayer?
    var composition: AVMutableComposition?
    var overlayCaptionView: UIView?
    
// MARK: - View Controller Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        player = SCPlayer()
        player?.loopEnabled = true
        filterSwipableView.refreshAutomaticallyWhenScrolling = false // can't tell what this does, but it is false in the examples, so better stay it
        filterSwipableView.contentMode = .ScaleAspectFit
        let emptyFilter = SCFilter()
        emptyFilter.name = "No Filter"
        filterSwipableView.filters = [emptyFilter,
                                      SCFilter(CIFilterName: "CIPhotoEffectChrome"),
                                      SCFilter(CIFilterName: "CIPhotoEffectFade"),
                                      SCFilter(CIFilterName: "CIPhotoEffectInstant"),
                                      SCFilter(CIFilterName: "CIPhotoEffectMono"),
                                      SCFilter(CIFilterName: "CIPhotoEffectNoir"),
                                      SCFilter(CIFilterName: "CIPhotoEffectProcess"),
                                      SCFilter(CIFilterName: "CIPhotoEffectTonal"),
                                      SCFilter(CIFilterName: "CIPhotoEffectTransfer")]
        player?.CIImageRenderer = filterSwipableView
        player?.loopEnabled = true

        
        // speeding up/slowing down the video
        composition = AVMutableComposition()
        let mutableCompositionVideoTrack = composition?.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let mutableCompositionAudioTrack = composition?.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())

        if let segments = recordSession?.segments as? [SCRecordSessionSegment] {
            var currentAudioTime = kCMTimeZero
            var currentVideoTime = kCMTimeZero
            for segment in segments {
                if let audioAssetTracks = segment.asset?.tracksWithMediaType(AVMediaTypeAudio) {
                    for audioAssetTrack in audioAssetTracks {
                        let audioAssetTrack = audioAssetTrack as! AVAssetTrack
                        mutableCompositionAudioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration), ofTrack: audioAssetTrack, atTime: currentAudioTime, error: nil)
                        let timescale = segment.info?["timescale"] as! Float
                        let scaledDuration = CMTimeMultiplyByFloat64(audioAssetTrack.timeRange.duration, Float64(timescale))
                        mutableCompositionAudioTrack?.scaleTimeRange(CMTimeRangeMake(currentAudioTime, audioAssetTrack.timeRange.duration), toDuration: scaledDuration)
                        currentAudioTime = CMTimeAdd(currentAudioTime, scaledDuration)
                    }
                }
                
                if let videoAssetTracks = segment.asset?.tracksWithMediaType(AVMediaTypeVideo) {
                    for videoAssetTrack in videoAssetTracks {
                        let videoAssetTrack = videoAssetTrack as! AVAssetTrack
                        mutableCompositionVideoTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration), ofTrack:videoAssetTrack, atTime:currentVideoTime, error:nil)
                        let timescale = segment.info?["timescale"] as! Float
                        let scaledDuration = CMTimeMultiplyByFloat64(videoAssetTrack.timeRange.duration, Float64(timescale))
                        mutableCompositionVideoTrack?.scaleTimeRange(CMTimeRangeMake(currentVideoTime, videoAssetTrack.timeRange.duration), toDuration:scaledDuration)
                        currentVideoTime = CMTimeAdd(currentVideoTime, scaledDuration)
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        //player?.setItemByAsset(recordSession?.assetRepresentingSegments())
        player?.setItemByAsset(composition)
        player?.play()
        
    }
    
    override func viewDidLayoutSubviews() {
        playerLayer?.frame = filterSwipableView.bounds
    }
    
    override func viewWillDisappear(animated: Bool) {
        player?.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
// MARK: - Button Touch Handlers
    
    @IBAction func saveToCameraRollPressed(sender: AnyObject)
    {
        player?.pause()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        let segmentsAsset = composition
        var assetExport = SCAssetExportSession()
        if let asset = segmentsAsset {
            assetExport = SCAssetExportSession(asset: asset)
        }
        assetExport.outputUrl = recordSession?.outputUrl
        assetExport.outputFileType = AVFileTypeMPEG4
        assetExport.audioConfiguration.preset = SCPresetHighestQuality
        assetExport.videoConfiguration.preset = SCPresetHighestQuality
        assetExport.videoConfiguration.filter = filterSwipableView.selectedFilter
        if let overlayView = overlayCaptionView {
            assetExport.videoConfiguration.overlay = overlayView
        }
        assetExport.videoConfiguration.maxFrameRate = 35
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
    
    @IBAction func insertCaptionPressed(sender: AnyObject) {
        overlayCaptionView = OverlayCaptionView(frame: view.frame)
        if let overlayView = overlayCaptionView {
            view.addSubview(overlayView)
        }
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