//
//  File.swift
//  VideoMaker
//
//  Created by Tom on 10/24/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit
import SCRecorder

public struct NKVideoSession {
    let recordSession: SCRecordSession
    let composition: AVComposition
    let overlay: UIView?
    let filter: SCFilter?
    var videoPlaybackViewControllerOrNil: VideoPlaybackViewController? // whenever one adds a caption view, layoutSubviews messes up controls after the export, that's why VideoPlaybackViewController is referenced and removes the caption view if it's present
    public func export(completion: (NSURL) -> ()) {
        let assetExport = SCAssetExportSession(asset: composition)
        assetExport.outputUrl = recordSession.outputUrl
        assetExport.outputFileType = AVFileTypeMPEG4
        assetExport.audioConfiguration.preset = SCPresetHighestQuality
        assetExport.videoConfiguration.preset = SCPresetHighestQuality
        assetExport.videoConfiguration.filter = filter
        if let overlay = overlay {
            assetExport.videoConfiguration.overlay = overlay
        }
        assetExport.videoConfiguration.maxFrameRate = 35
        let timestamp = CACurrentMediaTime()
        assetExport.exportAsynchronouslyWithCompletionHandler({
            print(String(format: "Completed compression in %fs", CACurrentMediaTime() - timestamp))
            if (assetExport.error == nil) {
                self.videoPlaybackViewControllerOrNil?.removeCaptionView()
                completion(assetExport.outputUrl!)
            }
            else {
                print("Video couldn't be exported: \(assetExport.error)")
            }
        })
    }
}

public protocol NKRecorderDelegate: class {
    func willStartRecording(recorderViewController: NKRecorderViewController)
    func didCancelRecording(recorderViewController: NKRecorderViewController)
    func didProduceVideo(recorderViewController: NKRecorderViewController, videoSession: NKVideoSession)
}

public class NKRecorderViewController : UINavigationController {
    private static let currentBundle = NSBundle(identifier: "me.tom.NKRecorder")!
    public weak var recorderDelegate: NKRecorderDelegate?
    weak var videoPlaybackViewController: VideoPlaybackViewController?
    public class func mainNavController() -> NKRecorderViewController {
        var once: dispatch_once_t = 0
        dispatch_once(&once) {
            loadCustomFonts()
        }
        let main = UIStoryboard(name: "Main", bundle: currentBundle)
        return main.instantiateViewControllerWithIdentifier("NKRecorderViewController") as! NKRecorderViewController
    }
    
    public func freezeUIForExport() {
        videoPlaybackViewController?.freezeUIForExport()
    }
    
    public func unfreezeUIFromExport() {
        videoPlaybackViewController?.unfreezeUIForExport()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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

extension NKRecorderViewController: RecordViewControllerDelegate {
    func recordingWillStart() {
        recorderDelegate?.willStartRecording(self)
    }
    
    func recordingDidCancel() {
        recorderDelegate?.didCancelRecording(self)
    }
}

extension NKRecorderViewController: VideoPlaybackViewControllerDelegate {
    func didProduceVideo(videoSession: NKVideoSession) {
        recorderDelegate?.didProduceVideo(self, videoSession: videoSession)
    }
}
