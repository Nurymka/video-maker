//
//  MusicRetrievalAPI.swift
//  VideoMaker
//
//  Created by Tom on 9/21/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import Foundation
import Alamofire

extension Alamofire.Request {
    // the retrieved data is serialized into a uiimage, used for album cover retrieval
    class func imageResponseSerializer() -> GenericResponseSerializer<UIImage> {
        return GenericResponseSerializer { request, response, data in
            
            guard let validData = data else {
                let failureReason = "Data couldn't be serialized. Input data was nil."
                let error = Error.errorWithCode(.DataSerializationFailed, failureReason: failureReason)
                return .Failure(data, error)
            }
            
            if let image = UIImage(data: validData, scale: UIScreen.mainScreen().scale) {
                return Result<UIImage>.Success(image)
            } else {
                return .Failure(data, Error.errorWithCode(.DataSerializationFailed, failureReason: "Unable to create image."))
            }
        }
    }
    
    func responseImage(completionHandler: (NSURLRequest?, NSHTTPURLResponse?, Result<UIImage>) -> Void) -> Self {
        return response(responseSerializer: Request.imageResponseSerializer(), completionHandler: completionHandler)
    }
}

struct MusicSearchAPI {
    static let resultLimit = 20
    enum Router: URLRequestConvertible {
        static let baseURLString = "http://api2.zhiliaoapp.com/1.1/search"
        case Search(String, Int) // search string, page int
        
        var URLRequest: NSMutableURLRequest {
            let parameters: [String: AnyObject] = {
                switch self {
                case .Search(let searchTerm, let page):
                    NSLog("page * resultLimit: \(page * resultLimit)")
                    return ["limit" : "\(resultLimit)", "offset" : "\(page * resultLimit)", "term" : searchTerm]
                }
            }()
            
            let URL = NSURL(string: Router.baseURLString)
            let URLRequest = NSURLRequest(URL: URL!)
            let encoding = Alamofire.ParameterEncoding.URL
            print(URL?.absoluteString)
            return encoding.encode(URLRequest, parameters: parameters).0
        }
    }
    
    // because thumbnails can be nsnull, this func is needed to avoid runtime crashes
    static func returnThumbnailUrlStringForDictObject(object: AnyObject?) -> String {
        if let object = object {
            if object as! NSObject != NSNull() {
                return object as! String
            }
        }
        return ""
    }
}

// each track from NSDictionary is stored as a TrackInfo
struct TrackInfo {
    let id: Int
    let trackPreviewURL: String
    let albumCoverURL: String
    let trackName: String
    let artistName: String
    
    init(id: Int, trackPreviewURL: String, albumCoverURL: String, trackName: String, artistName: String) {
        self.id = id
        self.trackPreviewURL = trackPreviewURL
        self.albumCoverURL = albumCoverURL
        self.trackName = trackName
        self.artistName = artistName
    }
}

// data used for ui elements, once the data is retrieved
// structs as NSData and back -> http://stackoverflow.com/questions/28916535/swift-structs-to-nsdata-and-back
struct TrackInfoLocal {
    let id: Int
    let trackName: String
    let artistName: String
    
    init(id: Int, trackName: String, artistName: String) {
        self.id = id
        self.trackName = trackName
        self.artistName = artistName
    }
    
    struct ArchivedTrackInfoLocal {
        var id: Int64
        var trackNameLength: Int64
        var artistNameLength: Int64
    }
    
    func archive() -> NSData {
        var archivedTrackInfoLocal = ArchivedTrackInfoLocal(id: Int64(self.id), trackNameLength: Int64(self.trackName.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), artistNameLength:
            Int64(self.artistName.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)))
        
        let metadata = NSData(bytes: &archivedTrackInfoLocal, length: sizeof(ArchivedTrackInfoLocal))
        
        let archivedData = NSMutableData(data: metadata)
        archivedData.appendData(trackName.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        archivedData.appendData(artistName.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        
        return archivedData
    }
    
    static func unarchive(data: NSData!) -> TrackInfoLocal {
        var archivedTrackInfoLocal = ArchivedTrackInfoLocal(id: 0, trackNameLength: 0, artistNameLength: 0)
        let archivedStructLength = sizeof(ArchivedTrackInfoLocal)
        
        let archivedData = data.subdataWithRange(NSMakeRange(0, archivedStructLength))
        archivedData.getBytes(&archivedTrackInfoLocal, length: archivedStructLength)
        
        let trackNameRange = NSMakeRange(archivedStructLength, Int(archivedTrackInfoLocal.trackNameLength))
        let artistNameRange = NSMakeRange(archivedStructLength + Int(archivedTrackInfoLocal.trackNameLength), Int(archivedTrackInfoLocal.artistNameLength))
        
        let trackNameData = data.subdataWithRange(trackNameRange)
        let trackName = NSString(data: trackNameData, encoding: NSUTF8StringEncoding) as! String
        
        let artistNameData = data.subdataWithRange(artistNameRange)
        let artistName = NSString(data: artistNameData, encoding: NSUTF8StringEncoding) as! String
        
        return TrackInfoLocal(id: Int(archivedTrackInfoLocal.id), trackName: trackName, artistName: artistName)
    }
}

extension String {
    static func presentableArtistAndSongName(artistName: String, songName: String) -> String {
        return artistName + " - " + songName
    }
}