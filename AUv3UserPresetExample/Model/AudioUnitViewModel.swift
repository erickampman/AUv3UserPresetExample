//
//  AudioUnitViewModel.swift
//  AUv3UserPresetExample
//
//  Created by Eric Kampman on 3/12/24.
//

import SwiftUI
import AudioToolbox
import CoreAudioKit

struct AudioUnitViewModel {
    var showAudioControls: Bool = false
    var showMIDIContols: Bool = false
    var title: String = "-"
    var message: String = "No Audio Unit loaded.."
    var viewController: ViewController?
}
