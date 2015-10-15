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
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/es/popular.png", name: "Popular", tagId: 1),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/28-733.png", name: "Lip-Sync Classic", tagId: 28),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/22-853.png", name: "Comedy", tagId: 22),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/es/hilarious.png", name: "Hilarious", tagId: 6),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/us/rap.jpg", name: "Rap", tagId: 29),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/7-832.png", name: "Cheerful", tagId: 7),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/17-446.png", name: "Movie Dialogue", tagId: 17),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/2-292.png", name: "Energetic", tagId: 2),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/4-34.png", name: "Sound Effects", tagId: 4),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/23-576.png", name: "Memorable Ads", tagId: 23),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/5-305.png", name: "Affectionate", tagId: 5),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/3-110.png", name: "Peaceful", tagId: 3),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/config-item-images/18-597.png", name: "Sad", tagId: 18),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/zh/Electronic.jpg", name: "Electronic", tagId: 31),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/zh/Metal.jpg", name: "Metal", tagId: 32),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/zh/WorldMusic.jpg", name: "World Music", tagId: 34),
        PlaylistItem(thumbnailURL: "http://res01.musical.ly/song-tag-images/zh/Rock.jpg", name: "Rock", tagId: 33),
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
