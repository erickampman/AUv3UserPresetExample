//
//  AUv3UserPresetExampleApp.swift
//  AUv3UserPresetExample
//
//  Created by Eric Kampman on 3/12/24.
//

import CoreMIDI
import SwiftUI

@main
struct AUv3UserPresetExampleApp: App {
    @ObservedObject private var hostModel = AudioUnitHostModel()

    var body: some Scene {
        WindowGroup {
            ContentView(hostModel: hostModel)
        }
    }
}
