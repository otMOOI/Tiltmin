//
//  SamplerUnit.h
//  Tiltmin
//
//  Created by caroline on 2014/12/31.
//  Copyright (c) 2014年 MOOI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

//
#define kFilteringFactor 0.1

// some MIDI constants:
enum {
    kMIDIMessage_NoteOn        = 0x9,
    kMIDIMessage_NoteOff       = 0x8,
    kMIDIMessage_ControlChange = 0xB,
    kMIDIMessage_PitchBend     = 0xE,
};

@interface SamplerUnit : NSObject

@property (readwrite) Float64   graphSampleRate;
@property (readwrite) AUGraph   processingGraph;
@property (readwrite) AudioUnit samplerUnit;
@property (readwrite) AudioUnit ioUnit;

@property (readwrite) BOOL isNoteOn;
@property (readwrite) float centerNoteNum;
@property (readwrite) float pitchBendSensitivity;

- (BOOL)createAUGraph;
- (void)configureAndStartAudioProcessingGraph;
- (void)loadPreset;
- (BOOL)setupAudioSession;
    
- (OSStatus)noteOn;
- (OSStatus)noteOff;
- (OSStatus)controlChangeVolume:(float)ratio;
- (OSStatus)controlChangePan:(float)ratio;
- (OSStatus)controlChangePitchBendSensitivity;
- (OSStatus)pitchBend:(double)ratio;
- (void)changeCenterNote:(float)difference;
- (void)changeBendRange:(float)difference;

- (void)beginInterruption;

@end
