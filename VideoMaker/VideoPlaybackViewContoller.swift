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
    var segmentsRecordedTimeScale: [Float] = []
    var composition: AVMutableComposition?
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
        var mutableCompositionVideoTrack = composition?.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        var mutableCompositionAudioTrack = composition?.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        if let arrayCount = recordSession?.segments.count {
            var currentAudioTime = kCMTimeZero
            var currentVideoTime = kCMTimeZero
            for index in 0..<arrayCount {
                var segment = recordSession?.segments[index] as! SCRecordSessionSegment
                var audioAssetTracks = segment.asset?.tracksWithMediaType(AVMediaTypeAudio)
                var videoAssetTracks = segment.asset?.tracksWithMediaType(AVMediaTypeVideo)
                
                if let unwrapAudioAssetTracks = audioAssetTracks {
                    for audioAssetTrack in unwrapAudioAssetTracks {
                        let audioAssetTrack = audioAssetTrack as! AVAssetTrack
                        mutableCompositionAudioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration), ofTrack:audioAssetTrack, atTime:currentAudioTime, error: nil)
                        var scaledDuration = CMTimeMultiplyByFloat64(audioAssetTrack.timeRange.duration, Float64(segmentsRecordedTimeScale[index]))
                        mutableCompositionAudioTrack?.scaleTimeRange(CMTimeRangeMake(currentAudioTime, audioAssetTrack.timeRange.duration), toDuration:scaledDuration)
                        currentAudioTime = CMTimeAdd(currentVideoTime, scaledDuration)
                    }
                }

                if let unwrapVideoAssetTracks = videoAssetTracks {
                    for videoAssetTrack in unwrapVideoAssetTracks {
                        let videoAssetTrack = videoAssetTrack as! AVAssetTrack
                        mutableCompositionVideoTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration), ofTrack:videoAssetTrack, atTime:currentVideoTime, error:nil)
                        var scaledDuration = CMTimeMultiplyByFloat64(videoAssetTrack.timeRange.duration, Float64(segmentsRecordedTimeScale[index]))
                        mutableCompositionVideoTrack?.scaleTimeRange(CMTimeRangeMake(currentVideoTime, videoAssetTrack.timeRange.duration), toDuration:scaledDuration)
                        currentVideoTime = CMTimeAdd(currentVideoTime, scaledDuration)
                        
                    }
                }
            }
            
        }
        
        // add "save to camera roll" button on the right side
        var btnSaveToCameraRoll = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveToCameraRollPressed:")
        navigationItem.rightBarButtonItem = btnSaveToCameraRoll
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
    
    func saveToCameraRollPressed(sender: AnyObject)
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
        assetExport.videoConfiguration.preset = SCPresetHighestQuality
        assetExport.audioConfiguration.preset = SCPresetHighestQuality
        assetExport.videoConfiguration.filter = filterSwipableView.selectedFilter
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