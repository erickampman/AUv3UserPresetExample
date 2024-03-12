//
//  AUv3UserPresetExampleExtensionMainView.swift
//  AUv3UserPresetExampleExtension
//
//  Created by Eric Kampman on 3/12/24.
//

import SwiftUI

struct AUv3UserPresetExampleExtensionMainView: View {
    var parameterTree: ObservableAUParameterGroup
    
    var body: some View {
        ParameterSlider(param: parameterTree.global.gain)
    }
}
