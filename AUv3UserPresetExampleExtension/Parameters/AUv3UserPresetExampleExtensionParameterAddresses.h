//
//  AUv3UserPresetExampleExtensionParameterAddresses.h
//  AUv3UserPresetExampleExtension
//
//  Created by Eric Kampman on 3/12/24.
//

#pragma once

#include <AudioToolbox/AUParameters.h>

#ifdef __cplusplus
namespace AUv3UserPresetExampleExtensionParameterAddress {
#endif

typedef NS_ENUM(AUParameterAddress, AUv3UserPresetExampleExtensionParameterAddress) {
    gain = 0
};

#ifdef __cplusplus
}
#endif
