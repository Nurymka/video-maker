//
//  AudioTypeButton.swift
//  VideoMaker
//
//  Created by Tom on 10/18/15.
//  Copyright © 2015 Tom. All rights reserved.
//

import UIKit

class AudioTypeButton: UIButton {
    
    var buttonState: ButtonState = .OriginalSound {
        didSet {
            switch buttonState {
            case .OriginalSound:
                setImage(UIImage(key: .btnSpeakerOn), forState: .Normal)
            case .PickSong:
                setImage(UIImage(key: .btnMusicNote), forState: .Normal)
            case .NoSound:
                setImage(UIImage(key: .btnSpeakerOff), forState: .Normal)
            }
        }
    }
    
    enum ButtonState {
        case OriginalSound
        case PickSong
        case NoSound
    }
}

