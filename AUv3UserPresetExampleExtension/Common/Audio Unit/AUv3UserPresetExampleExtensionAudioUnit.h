//
//  AUv3UserPresetExampleExtensionAudioUnit.h
//  AUv3UserPresetExampleExtension
//
//  Created by Eric Kampman on 3/12/24.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface AUv3UserPresetExampleExtensionAudioUnit : AUAudioUnit
- (void)setupParameterTree:(AUParameterTree *)parameterTree;
@end
