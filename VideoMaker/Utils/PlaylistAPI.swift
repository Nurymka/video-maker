//
//  PlaylistAPI.swift
//  VideoMaker
//
//  Created by Tom on 10/8/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import Foundation
import Alamofire

struct PlaylistItem {
    let thumbnailURL: String
    let name: String
    let tagId: Int
    
    init(thumbnailURL: String, name: String, tagId: Int) {
        self.thumbnailURL = thumbnailURL
        self.name = name
        self.tagId = tagId
    }
}

struct MusicPlaylistAPI {
    static let resultLimit = 20
    static let playlists: [PlaylistItem] = [
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/es/popular.png", name: "popular", tagId: 1),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/28-733.png", name: "lip-sync classic", tagId: 28),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/22-853.png", name: "comedy", tagId: 22),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/es/hilarious.png", name: "hilarious", tagId: 6),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/us/rap.jpg", name: "rap", tagId: 29),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/7-832.png", name: "cheerful", tagId: 7),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/17-446.png", name: "movie dialogue", tagId: 17),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/2-292.png", name: "energetic", tagId: 2),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/4-34.png", name: "sound effects", tagId: 4),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/23-576.png", name: "memorable ads", tagId: 23),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/5-305.png", name: "affectionate", tagId: 5),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/3-110.png", name: "peaceful", tagId: 3),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/18-597.png", name: "sad", tagId: 18),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/zh/Electronic.jpg", name: "electronic", tagId: 31),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/zh/Metal.jpg", name: "metal", tagId: 32),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/zh/WorldMusic.jpg", name: "world music", tagId: 34),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/zh/Rock.jpg", name: "rock", tagId: 33),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/zh/ACG.jpg", name: "ACG", tagId: 30)
    ]
    
    enum Router: URLRequestConvertible {
        static let baseURLString = "http://www.musical.ly/rest/tracks/bytag"
        
        case Tracklist(Int, Int) // tagId - int, page number - int
        
        var URLRequest: NSMutableURLRequest {
            let parameters: [String: AnyObject] = {
                switch self {
                case .Tracklist(let tagId, let pageNumber):
                    return ["pageNo" : "\(pageNumber)", "pageSize" : "\(resultLimit)", "tagId" : "\(tagId)"]
                }
            }()
            
            let URL = NSURL(string: Router.baseURLString)
            let URLRequest = NSMutableURLRequest(URL: URL!)
            URLRequest.setValue("MTQ1MDYzODM5X3R3aXR0ZXI6OENkbUlMOVlrenBUdy9TengzZklNZz09OmQ4N2U1NzdkYjg3NmRkMzkwYWI1MGU1YTYyNDQ4NDky", forHTTPHeaderField: "slider-show-cookie") // temporary hack
            let encoding = Alamofire.ParameterEncoding.URL
            
            return encoding.encode(URLRequest, parameters: parameters).0
        }
    }
    

}
