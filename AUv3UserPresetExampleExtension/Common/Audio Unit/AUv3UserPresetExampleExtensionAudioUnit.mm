//
//  AUv3UserPresetExampleExtensionAudioUnit.mm
//  AUv3UserPresetExampleExtension
//
//  Created by Eric Kampman on 3/12/24.
//

#import "AUv3UserPresetExampleExtensionAudioUnit.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/AUViewController.h>

#import "AUv3UserPresetExampleExtensionAUProcessHelper.hpp"
#import "AUv3UserPresetExampleExtensionDSPKernel.hpp"

#import "AUv3UserPresetExampleExtensionParameterAddresses.h"


// Define parameter addresses.

@interface AUv3UserPresetExampleExtensionAudioUnit ()

@property (nonatomic, readwrite) AUParameterTree *parameterTree;
@property AUAudioUnitBusArray *outputBusArray;
@property (nonatomic, readonly) AUAudioUnitBus *outputBus;
@end


@implementation AUv3UserPresetExampleExtensionAudioUnit {
    // C++ members need to be ivars; they would be copied on access if they were properties.
    AUv3UserPresetExampleExtensionDSPKernel _kernel;
    std::unique_ptr<AUProcessHelper> 		_processHelper;
	AUAudioUnitPreset            			*_currentPreset;
}

@synthesize parameterTree = _parameterTree;

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];
    
    if (self == nil) { return nil; }
    
    [self setupAudioBuses];
    
    return self;
}

#pragma mark - Presets

/*
	Apple's template project currently implements the audiounit in Objective-C++.
	There are other demo projects that use Swift.
 
	Because the audio processing has to be done in C++ (or C), Swift carries a
	somewhat higher burden to integrate with the processing code, but is definitely
	doable. It's on my list to attempt to integrate directly with C++, since Swift
	now supports that, but it looks like I need to create a framework for the C++
	code and I haven't done that yet.
 */

- (bool)supportsUserPresets {
	return true;
}

- (NSDictionary<NSString *,id> *)fullState {
	NSMutableDictionary *state = [[NSMutableDictionary alloc] initWithDictionary:super.fullState];
	
	AUParameter *param = [self.parameterTree parameterWithAddress:AUv3UserPresetExampleExtensionParameterAddress::gain];
	
	/* set the values of ALL your params. This is just an example. */
	NSDictionary<NSString*, id> *params = @{
		@"gain": [NSNumber numberWithFloat:param.value],
	};
	
	NSError *error = nil;
	state[@"data"] = [NSKeyedArchiver archivedDataWithRootObject:params
										   requiringSecureCoding:false
														   error:&error];
	
	if (nil != error) {
		NSLog(@"achive error %@", error);
		return nil;
	}
	
	return state;
}

-(void)setFullState:(NSDictionary<NSString *,id> *)fullState {
	NSError *error = nil;
	NSDictionary *dict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSDictionary.class
															 fromData:(NSData *)fullState[@"data"]
																error:&error];
	// read your params
	AUParameter *param = [self.parameterTree parameterWithAddress:AUv3UserPresetExampleExtensionParameterAddress::gain];
	
	if (nil != error) {
		NSLog(@"achive error %@", error);
		return;
	}

	/*
		Of course, you will have more than one param. You need to set each one.
	 */
	param.value = [(NSNumber *)dict[@"gain"] floatValue];
}

- (AUAudioUnitPreset *)currentPreset {
	AUAudioUnitPreset            *_currentPreset;

	if (!_currentPreset || _currentPreset.number >= 0) {
		/*
			Factory presets have numbers > 0. In this demo project there aren't any.
			I don't know if returning nil here could be problematic. If so at least
			one factory default preset should be created and returned.
		 */
		return nil;
	}
	
	NSLog(@"User Preset: %ld, %@\n", (long)self.currentPreset.number, self.currentPreset.name);
	return _currentPreset;
}

- (void)setCurrentPreset:(AUAudioUnitPreset *)preset {
	if (nil == preset) {
		NSLog(@"nil passed to setCurrentPreset!");
		return;
	}
	if (preset.number >= 0) { return; }
	
	NSError *error = nil;
	NSDictionary<NSString *,id> *dict = [self presetStateFor:preset
													   error:&error];
	self.fullStateForDocument = dict;
	if (nil == error) {
		_currentPreset = preset;
	} else {
		NSLog(@"preset load error: %@", error);
	}
}


#pragma mark - AUAudioUnit Setup

- (void)setupAudioBuses {
    // Create the output bus first
    AVAudioFormat *format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
    _outputBus = [[AUAudioUnitBus alloc] initWithFormat:format error:nil];
    _outputBus.maximumChannelCount = 8;
    
    // then an array with it
    _outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
                                                             busType:AUAudioUnitBusTypeOutput
                                                              busses: @[_outputBus]];
}

- (void)setupParameterTree:(AUParameterTree *)parameterTree {
    _parameterTree = parameterTree;
    
    // Send the Parameter default values to the Kernel before setting up the parameter callbacks, so that the defaults set in the Kernel.hpp don't propagate back to the AUParameters via GetParameter
    for (AUParameter *param in _parameterTree.allParameters) {
        _kernel.setParameter(param.address, param.value);
    }
    
    [self setupParameterCallbacks];
}

- (void)setupParameterCallbacks {
    // Make a local pointer to the kernel to avoid capturing self.
    
    __block AUv3UserPresetExampleExtensionDSPKernel *kernel = &_kernel;
    
    // implementorValueObserver is called when a parameter changes value.
    _parameterTree.implementorValueObserver = ^(AUParameter *param, AUValue value) {
        kernel->setParameter(param.address, value);
    };
    
    // implementorValueProvider is called when the value needs to be refreshed.
    _parameterTree.implementorValueProvider = ^(AUParameter *param) {
        return kernel->getParameter(param.address);
    };
    
    // A function to provide string representations of parameter values.
    _parameterTree.implementorStringFromValueCallback = ^(AUParameter *param, const AUValue *__nullable valuePtr) {
        AUValue value = valuePtr == nil ? param.value : *valuePtr;
        
        return [NSString stringWithFormat:@"%.f", value];
    };
}

#pragma mark - AUAudioUnit Overrides

- (AUAudioFrameCount)maximumFramesToRender {
    return _kernel.maximumFramesToRender();
}

- (void)setMaximumFramesToRender:(AUAudioFrameCount)maximumFramesToRender {
    _kernel.setMaximumFramesToRender(maximumFramesToRender);
}

// An audio unit's audio output connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)outputBusses {
    return _outputBusArray;
}

- (void)setShouldBypassEffect:(BOOL)shouldBypassEffect {
    _kernel.setBypass(shouldBypassEffect);
}

- (BOOL)shouldBypassEffect {
    return _kernel.isBypassed();
}

// Allocate resources required to render.
// Subclassers should call the superclass implementation.
- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    const auto outputChannelCount = [self.outputBusses objectAtIndexedSubscript:0].format.channelCount;
    
    _kernel.setMusicalContextBlock(self.musicalContextBlock);
    _kernel.initialize(outputChannelCount, _outputBus.format.sampleRate);
    _processHelper = std::make_unique<AUProcessHelper>(_kernel, outputChannelCount);
    return [super allocateRenderResourcesAndReturnError:outError];
}

// Deallocate resources allocated in allocateRenderResourcesAndReturnError:
// Subclassers should call the superclass implementation.
- (void)deallocateRenderResources {
    
    // Deallocate your resources.
    _kernel.deInitialize();
    
    [super deallocateRenderResources];
}

#pragma mark - MIDI

- (MIDIProtocolID)AudioUnitMIDIProtocol {
    return _kernel.AudioUnitMIDIProtocol();
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)

// Block which subclassers must provide to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
    /*
     Capture in locals to avoid ObjC member lookups. If "self" is captured in
     render, we're doing it wrong.
     */
    // Specify captured objects are mutable.
    __block AUv3UserPresetExampleExtensionDSPKernel *kernel = &_kernel;
    __block std::unique_ptr<AUProcessHelper> &processHelper = _processHelper;
    
    return ^AUAudioUnitStatus(AudioUnitRenderActionFlags 				*actionFlags,
                              const AudioTimeStamp       				*timestamp,
                              AVAudioFrameCount           				frameCount,
                              NSInteger                   				outputBusNumber,
                              AudioBufferList            				*outputData,
                              const AURenderEvent        				*realtimeEventListHead,
                              AURenderPullInputBlock __unsafe_unretained pullInputBlock) {
        
        if (frameCount > kernel->maximumFramesToRender()) {
            return kAudioUnitErr_TooManyFramesToProcess;
        }
        
        /*
         Important:
         If the caller passed non-null output pointers (outputData->mBuffers[x].mData), use those.
         
         If the caller passed null output buffer pointers, process in memory owned by the Audio Unit
         and modify the (outputData->mBuffers[x].mData) pointers to point to this owned memory.
         The Audio Unit is responsible for preserving the validity of this memory until the next call to render,
         or deallocateRenderResources is called.
         
         If your algorithm cannot process in-place, you will need to preallocate an output buffer
         and use it here.
         
         See the description of the canProcessInPlace property.
         */
        processHelper->processWithEvents(outputData, timestamp, frameCount, realtimeEventListHead);
        
        return noErr;
    };
    
}

@end

