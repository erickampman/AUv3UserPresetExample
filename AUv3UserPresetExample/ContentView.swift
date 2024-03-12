//
//  ContentView.swift
//  AUv3UserPresetExample
//
//  Created by Eric Kampman on 3/12/24.
//

import AudioToolbox
import SwiftUI

struct ContentView: View {
    @ObservedObject var hostModel: AudioUnitHostModel
	@State private var showingExporter = false
	@State private var presetName = ""
    var margin = 10.0
    var doubleMargin: Double {
        margin * 2.0
    }
    
    var body: some View {
        VStack() {
            Text("\(hostModel.viewModel.title )")
                .textSelection(.enabled)
                .padding()
			Button("Presets") {
				showingExporter.toggle()
			}
            VStack(alignment: .center) {
                if let viewController = hostModel.viewModel.viewController {
                    AUViewControllerUI(viewController: viewController)
                        .padding(margin)
                } else {
                    VStack() {
                        Text(hostModel.viewModel.message)
                            .padding()
                    }
                    .frame(minWidth: 400, minHeight: 200)
                }
            }
            .padding(doubleMargin)
            
            if hostModel.viewModel.showAudioControls {
                Text("Audio Playback")
                Button {
                    hostModel.isPlaying ? hostModel.stopPlaying() : hostModel.startPlaying()
                    
                } label: {
                    Text(hostModel.isPlaying ? "Stop" : "Play")
                }
            }
            if hostModel.viewModel.showMIDIContols {
                Text("MIDI Input: Enabled")
            }
            Spacer()
                .frame(height: margin)
        }
		.sheet(isPresented: $showingExporter) {
			VStack(alignment: .center) {
				Text("User Preset")
					.font(.title)
				HStack() {
					Text("Save Preset As:")
					TextField("Preset Name", text: $presetName)
						.frame(width: 300)
				}
				.padding()
				HStack {
					Button {
						if saveParamsWithName(presetName) {
							showingExporter.toggle()
						}
					} label: {
						Text("Save")
							.disabled(presetName.isEmpty)
					}
					Button { showingExporter.toggle()
					} label: {
						Text("Cancel")
					}
					
					Button {
						if let preset = findPresetFromName(presetName), let auAudioUnit = hostModel.auAudioUnit {
							auAudioUnit.currentPreset = preset
						}
					} label: {
						Text("Load")
					}
				}
			}
		}
    }
	
	func findPresetFromName(_ name: String) -> AUAudioUnitPreset? {
		guard let auAudioUnit = hostModel.auAudioUnit else { return AUAudioUnitPreset?.none }
		
		for preset in auAudioUnit.userPresets {
			if name == preset.name {
				return preset
			}
		}
		return AUAudioUnitPreset?.none
	}
	
	func uniquePresetNumber() -> NSInteger {
		var ret: NSInteger = -1
		guard let auAudioUnit = hostModel.auAudioUnit else { return -1 }
		
		for preset in auAudioUnit.userPresets {
			if preset.number >= ret {
				ret -= 1
			}
		}
		return ret
	}
	
	func saveParamsWithName(_ name: String) -> Bool {
		let presetNumber = uniquePresetNumber()
		let preset = AUAudioUnitPreset()
		preset.number = presetNumber
		preset.name = name
		
		guard let auAudioUnit = hostModel.auAudioUnit else { return false }
		do {
			try auAudioUnit.saveUserPreset(preset)
		}
		catch let error as NSError {
			print("\(error)")
			return false
		}
		return true
	}


}

#Preview {
    ContentView(hostModel: AudioUnitHostModel())
}
