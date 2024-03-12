# AUv3 User Preset Example

This project was created with Xcode 15's AudioUnit Extension App template. 

Minimal changes have been made. This project is intended *ONLY* to illustrate how to support user presets.
Nothing I found on the web so far worked for me, so hopefully this will provide some guidance to others. 

Apple's [developer video](https://developer.apple.com/videos/play/wwdc2019/509/) was somewhat helpful, but failed to explain:
- the relationship between presetState/fullStateForDocument and the fullState property

The AudioUnit Extension App template is more bare-bones than previous audio unit demo code.
This project is not intended to address anything other than how to implement user presets.
In particular it doesn't do:
- polyphony
- audio envelopes

The UI is pretty elementary. 
- Set the parameter's value with the slider.
- Click on the "Presets" button
- Set the preset's name.
- Click Save
- Dismiss the sheet.
- Change the parameter's value.
- Click on the "Presets" button
- Make sure the preset's name is still set (or make it so)
- Click on Load.
- Verify that the value is now set properly.


