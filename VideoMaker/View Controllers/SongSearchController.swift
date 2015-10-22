//
//  SongSearchController.swift
//  VideoMaker
//
//  Created by Tom on 10/22/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit

// remove cancel button from the UISearchController: http://stackoverflow.com/a/28396967
class SongSearchBar: UISearchBar {
    override func setShowsCancelButton(showsCancelButton: Bool, animated: Bool) {
        
    }
}

class SongSearchController: UISearchController, UISearchBarDelegate {
    override var searchBar: SongSearchBar {
        get {
            return privateSearchBar
        }
    }
    
    private var privateSearchBar = SongSearchBar()
}