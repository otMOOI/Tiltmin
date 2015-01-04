//
//  SamplerUnit.m
//  Tiltmin
//
//  Created by caroline on 2014/12/31.
//  Copyright (c) 2014年 MOOI. All rights reserved.
//

#import "SamplerUnit.h"

@implementation SamplerUnit {
    UIAccelerationValue accelX, accelY, accelZ;
}

@synthesize graphSampleRate = _graphSampleRate;
@synthesize samplerUnit     = _samplerUnit;
@synthesize ioUnit          = _ioUnit;
@synthesize processingGraph = _processingGraph;

@synthesize isNoteOn;
@synthesize centerNoteNum;


#pragma mark -
#pragma mark Audio setup

/**
 * Create an audio processing graph.
 */
- (BOOL)createAUGraph {
    
    OSStatus result = noErr;
    AUNode samplerNode, ioNode;
    
    // Specify the common portion of an audio unit's identify, used for both audio units
    // in the graph.
    AudioComponentDescription cd = {};
    cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
    cd.componentFlags            = 0;
    cd.componentFlagsMask        = 0;
    
    // Instantiate an audio processing graph
    result = NewAUGraph (&_processingGraph);
    NSCAssert (result == noErr, @"Unable to create an AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    //Specify the Sampler unit, to be used as the first node of the graph
    cd.componentType = kAudioUnitType_MusicDevice;
    cd.componentSubType = kAudioUnitSubType_Sampler;
    
    // Add the Sampler unit node to the graph
    result = AUGraphAddNode (self.processingGraph, &cd, &samplerNode);
    NSCAssert (result == noErr, @"Unable to add the Sampler unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Specify the Output unit, to be used as the second and final node of the graph
    cd.componentType = kAudioUnitType_Output;
    cd.componentSubType = kAudioUnitSubType_RemoteIO;
    
    // Add the Output unit node to the graph
    result = AUGraphAddNode (self.processingGraph, &cd, &ioNode);
    NSCAssert (result == noErr, @"Unable to add the Output unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Open the graph
    result = AUGraphOpen (self.processingGraph);
    NSCAssert (result == noErr, @"Unable to open the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Connect the Sampler unit to the output unit
    result = AUGraphConnectNodeInput (self.processingGraph, samplerNode, 0, ioNode, 0);
    NSCAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Obtain a reference to the Sampler unit from its node
    result = AUGraphNodeInfo (self.processingGraph, samplerNode, 0, &_samplerUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the Sampler unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Obtain a reference to the I/O unit from its node
    result = AUGraphNodeInfo (self.processingGraph, ioNode, 0, &_ioUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    return YES;
}

/**
 * Starting with instantiated audio processing graph, configure its
 * audio units, initialize it, and start it.
 */
- (void)configureAndStartAudioProcessingGraph {
    OSStatus result = noErr;
    UInt32 framesPerSlice = 0;
    UInt32 framesPerSlicePropertySize = sizeof (framesPerSlice);
    UInt32 sampleRatePropertySize = sizeof (self.graphSampleRate);
    
    result = AudioUnitInitialize (self.ioUnit);
    NSCAssert (result == noErr, @"Unable to initialize the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Set the I/O unit's output sample rate.
    result =    AudioUnitSetProperty (
                                      self.ioUnit,
                                      kAudioUnitProperty_SampleRate,
                                      kAudioUnitScope_Output,
                                      0,
                                      &_graphSampleRate,
                                      sampleRatePropertySize
                                      );
    
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Obtain the value of the maximum-frames-per-slice from the I/O unit.
    result =    AudioUnitGetProperty (
                                      self.ioUnit,
                                      kAudioUnitProperty_MaximumFramesPerSlice,
                                      kAudioUnitScope_Global,
                                      0,
                                      &framesPerSlice,
                                      &framesPerSlicePropertySize
                                      );
    
    NSCAssert (result == noErr, @"Unable to retrieve the maximum frames per slice property from the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Set the Sampler unit's output sample rate.
    result =    AudioUnitSetProperty (
                                      self.samplerUnit,
                                      kAudioUnitProperty_SampleRate,
                                      kAudioUnitScope_Output,
                                      0,
                                      &_graphSampleRate,
                                      sampleRatePropertySize
                                      );
    
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Set the Sampler unit's maximum frames-per-slice.
    result =    AudioUnitSetProperty (
                                      self.samplerUnit,
                                      kAudioUnitProperty_MaximumFramesPerSlice,
                                      kAudioUnitScope_Global,
                                      0,
                                      &framesPerSlice,
                                      framesPerSlicePropertySize
                                      );
    
    NSAssert( result == noErr, @"AudioUnitSetProperty (set Sampler unit maximum frames per slice). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    
    if (self.processingGraph) {
        
        // Initialize the audio processing graph.
        result = AUGraphInitialize (self.processingGraph);
        NSAssert (result == noErr, @"Unable to initialze AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        // Start the graph
        result = AUGraphStart (self.processingGraph);
        NSAssert (result == noErr, @"Unable to start audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        // Print out the graph to the console
        CAShow (self.processingGraph);
    }
}

/**
 * Load the preset
 */
- (void)loadPreset {
    NSURL *presetURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Sine440Builtin" ofType:@"aupreset"]];
    if (presetURL) {
        NSLog(@"Attempting to load preset '%@'\n", [presetURL description]);
    } else {
        NSLog(@"COULD NOT GET PRESET PATH!");
    }
    [self loadSynthFromPresetURL: presetURL];
}

/**
 * Load a synthesizer preset file and apply it to the Sampler unit
 */
- (OSStatus)loadSynthFromPresetURL:(NSURL *)presetURL {
    
    CFDataRef propertyResourceData = 0;
    Boolean status;
    SInt32 errorCode = 0;
    OSStatus result = noErr;
    
    // Read from the URL and convert into a CFData chunk
    status = CFURLCreateDataAndPropertiesFromResource (
                                                       kCFAllocatorDefault,
                                                       (__bridge CFURLRef) presetURL,
                                                       &propertyResourceData,
                                                       NULL,
                                                       NULL,
                                                       &errorCode
                                                       );
    
    NSAssert (status == YES && propertyResourceData != 0, @"Unable to create data and properties from a preset. Error code: %d '%.4s'", (int) errorCode, (const char *)&errorCode);
   	
    // Convert the data object into a property list
    CFPropertyListRef presetPropertyList = 0;
    CFPropertyListFormat dataFormat = 0;
    CFErrorRef errorRef = 0;
    presetPropertyList = CFPropertyListCreateWithData (
                                                       kCFAllocatorDefault,
                                                       propertyResourceData,
                                                       kCFPropertyListImmutable,
                                                       &dataFormat,
                                                       &errorRef
                                                       );
    
    // Set the class info property for the Sampler unit using the property list as the value.
    if (presetPropertyList != 0) {
        
        result = AudioUnitSetProperty(
                                      self.samplerUnit,
                                      kAudioUnitProperty_ClassInfo,
                                      kAudioUnitScope_Global,
                                      0,
                                      &presetPropertyList,
                                      sizeof(CFPropertyListRef)
                                      );
        
        CFRelease(presetPropertyList);
    }
    
    if (errorRef) CFRelease(errorRef);
    CFRelease (propertyResourceData);
    
    return result;
}

/**
 * Set up the audio session for this app.
 */
- (BOOL)setupAudioSession {
    
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    
    // Specify that this object is the delegate of the audio session, so that
    //    this object's endInterruption method will be invoked when needed.
    [mySession setDelegate: self];
    
    // Assign the Playback category to the audio session. This category supports
    //    audio output with the Ring/Silent switch in the Silent position.
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting audio session category."); return NO;}
    
    // Request a desired hardware sample rate.
    self.graphSampleRate = 44100.0;    // Hertz
    
    [mySession setPreferredHardwareSampleRate: self.graphSampleRate error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting preferred hardware sample rate."); return NO;}
    
    // Activate the audio session
    [mySession setActive: YES error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error activating the audio session."); return NO;}
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
    self.graphSampleRate = [mySession currentHardwareSampleRate];
    
    return YES;
}

#pragma mark -
#pragma mark Audio control

/**
 * Play the note
 */
- (OSStatus)noteOn {
    self.isNoteOn = YES;
    UInt32 noteCommand = kMIDIMessage_NoteOn << 4 | 0;
    return MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, floor(centerNoteNum), 127, 0);
}

/**
 * Stop the note
 */
- (OSStatus)noteOff {
    self.isNoteOn = NO;
    UInt32 noteCommand = kMIDIMessage_NoteOff << 4 | 0;
    return MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, floor(centerNoteNum), 0, 0);
}

/**
 *
 */
- (OSStatus)controlChangeVolume:(float)ratio {
    UInt32 noteCommand = kMIDIMessage_ControlChange << 4 | 0;
    UInt32 controlNum = 7;  // コントロール番号: 7（チャンネル・ボリューム）
    UInt32 msb = (127 * ratio);
    
    return MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, controlNum, msb, 0);
}

/**
 *
 */
- (OSStatus)controlChangePan:(float)ratio {
    UInt32 noteCommand = kMIDIMessage_ControlChange << 4 | 0;
    UInt32 controlNum = 10;  // コントロール番号: 10（パン）
    UInt32 msb = (127 * ratio);
    
    return MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, controlNum, msb, 0);
}

/**
 *
 */
- (OSStatus)controlChangePitchBendSensitivity {
    UInt32 noteCommand = kMIDIMessage_ControlChange << 4 | 0;
    
    // コントロール番号: 101（RPN MSB）
    OSStatus osStatus = MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, 101, 0, 0);
    if (osStatus != noErr) return osStatus;
    
    // コントロール番号: 100（RPN LSB）
    osStatus = MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, 100, 0, 0);
    if (osStatus != noErr) return osStatus;
    
    // コントロール番号: 6（データエントリーMSB）
    osStatus = MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, 6, floor(self.pitchBendSensitivity), 0);
    if (osStatus != noErr) return osStatus;
    
    // コントロール番号: 38（データエントリーLSB）
    osStatus = MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, 38, 12, 0);
    return osStatus;
}

/**
 *
 */
- (OSStatus)pitchBend:(double)ratio {
    UInt32 noteCommand = kMIDIMessage_PitchBend << 4 | 0;
    accelY = (ratio * kFilteringFactor) + (accelY * (1.0 - kFilteringFactor));
    UInt32 bendValue = 8192 + round(16384 * accelY / M_PI);
    if (bendValue > 16383) bendValue = 16383;

    UInt32 msb = (bendValue >> 7) & 0x7F;
    UInt32 lsb = bendValue & 0x7F;
    return MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, lsb, msb, 0);
}

/**
 *
 */
- (void)changeCenterNote:(float)difference {
    self.centerNoteNum += difference;

    if (self.centerNoteNum > 127) {
        self.centerNoteNum = 127;
    }
    if (self.centerNoteNum < 0) {
        self.centerNoteNum = 0;
    }
}

/**
 *
 */
- (void)changeBendRange:(float)difference {
//NSLog(@"%f", difference);
    self.pitchBendSensitivity += difference;
    
    if (self.pitchBendSensitivity > 120) {
        self.pitchBendSensitivity = 120;
    }
    if (self.pitchBendSensitivity < 0) {
        self.pitchBendSensitivity = 0;
    }

    [self controlChangePitchBendSensitivity];
}

#pragma mark -
#pragma mark Audio processing graph methods

/**
 * Stop the audio processing graph
 */
- (void)stopAudioProcessingGraph {
    OSStatus result = noErr;
    if (self.processingGraph) result = AUGraphStop(self.processingGraph);
    NSAssert (result == noErr, @"Unable to stop the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
}

/**
 * Restart the audio processing graph
 */
- (void)restartAudioProcessingGraph {
    OSStatus result = noErr;
    if (self.processingGraph) result = AUGraphStart (self.processingGraph);
    NSAssert (result == noErr, @"Unable to restart the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
}

#pragma mark -
#pragma mark Audio session delegate methods

/**
 * Respond to an audio interruption, such as a phone call or a Clock alarm.
 */
- (void)beginInterruption {
    
    // Stop any notes that are currently playing.
    [self noteOff];
    
    // Interruptions do not put an AUGraph object into a "stopped" state, so
    //    do that here.
    [self stopAudioProcessingGraph];
}

/**
 * Respond to the ending of an audio interruption.
 */
- (void)endInterruptionWithFlags:(NSUInteger)flags {
    
    NSError *endInterruptionError = nil;
    [[AVAudioSession sharedInstance] setActive: YES
                                         error: &endInterruptionError];
    if (endInterruptionError != nil) {
        
        NSLog (@"Unable to reactivate the audio session.");
        return;
    }
    
    if (flags & AVAudioSessionInterruptionFlags_ShouldResume) {
        
        /*
         In a shipping application, check here to see if the hardware sample rate changed from
         its previous value by comparing it to graphSampleRate. If it did change, reconfigure
         the ioInputStreamFormat struct to use the new sample rate, and set the new stream
         format on the two audio units. (On the mixer, you just need to change the sample rate).
         
         Then call AUGraphUpdate on the graph before starting it.
         */
        
        [self restartAudioProcessingGraph];
    }
}

@end
