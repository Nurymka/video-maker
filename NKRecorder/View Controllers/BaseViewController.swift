//
//  BaseViewController.swift
//  VideoMaker
//
//  Created by Tom on 10/19/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit

public class BaseViewController: UIViewController { // this class is only subclassed by RecordViewController and VideoPlaybackViewController for segue purposes
    var musicTrackInfo: TrackInfoLocal? // when a track is selected from Search/ChooseMusicTrackTableViewController, the property gets a value-
}
