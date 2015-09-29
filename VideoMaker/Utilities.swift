//
//  Utilities.swift
//  VideoMaker
//
//  Created by Tom on 9/23/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import Foundation

// FileManager is used to save music tracks as NSData objects to /Library/Caches/VideoMakerMusicCache/audios/xxx/{trackID}.m4a.
class FileManager {
    static let kVideoMakerMusicCacheDirectory = "VideoMakerMusicCache"
    
    static func writeTrackDataToDisk(data: NSData, withFileName trackURL: String) -> Bool {
        let fm = NSFileManager()
        let cachesURL = fm.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
        let modifiedTrackURL = (NSURL(string: trackURL)?.URLByDeletingLastPathComponent?.URLString.stringByRemovingMusicallyAddressPath())!
        let trackDirectoryURL = cachesURL.URLByAppendingPathComponent(kVideoMakerMusicCacheDirectory).URLByAppendingPathComponent(modifiedTrackURL) // creates a directory at path /Library/Caches/VideoMakerMusicCache/audios/xxx/ if it doesn't exist
        var isDirectory = ObjCBool(true)
        if !NSFileManager.defaultManager().fileExistsAtPath(trackDirectoryURL.path!, isDirectory: &isDirectory) {
            do {
            try NSFileManager.defaultManager().createDirectoryAtURL(trackDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("\(error)")
            }
        }
        let fileName = (NSURL(string: trackURL)?.lastPathComponent)!
        let trackPathURL = trackDirectoryURL.URLByAppendingPathComponent(fileName)
        if !NSFileManager.defaultManager().fileExistsAtPath(trackPathURL.path!) {
            return NSFileManager.defaultManager().createFileAtPath(trackPathURL.path!, contents: data, attributes: nil)
        }
        return false
    }
    
    static func returnTrackURLFromDisk(trackURL trackURL: String) -> NSURL? {
        if trackExistsOnDisk(trackURL: trackURL) {
            return trackPathURLFromTrackURL(trackURL)
        } else {
            print("File doesn't exist at path: \(trackPathURLFromTrackURL(trackURL).path!)")
            return nil
        }
    }
    
    static func trackExistsOnDisk(trackURL trackURL: String) -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(trackPathURLFromTrackURL(trackURL).path!)
    }
    
    private static func trackPathURLFromTrackURL(trackURL: String) -> NSURL {
        let modifiedTrackURL = trackURL.stringByRemovingMusicallyAddressPath()
        let fm = NSFileManager()
        let cachesURL = fm.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
        let trackPathURL = cachesURL.URLByAppendingPathComponent(kVideoMakerMusicCacheDirectory).URLByAppendingPathComponent(modifiedTrackURL)
        return trackPathURL
    }
}

extension String {
    func stringByRemovingMusicallyAddressPath() -> String {
        return self.stringByReplacingOccurrencesOfString("http://music.musical.ly/", withString: "")
    }
}