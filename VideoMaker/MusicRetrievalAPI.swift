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