//
//  ViewController.m
//  Tiltmin
//
//  Created by caroline on 2014/12/31.
//  Copyright (c) 2014年 MOOI. All rights reserved.
//

#import "ViewController.h"
#import "SBJson.h"

@interface ViewController ()

@end

@implementation ViewController {
    CMMotionManager *motionManager;
    NSTimeInterval updateInterval;
}

#pragma mark -
#pragma mark Application state management

- (id)initWithCoder:(NSCoder*)decoder {
    self = [super initWithCoder:decoder];
    if (!self) {
        return nil;
    }
    
    updateInterval = 0.01;

    self.samplerUnit = [[SamplerUnit alloc] init];
    
    // Set up the audio session for this app, in the process obtaining the
    // hardware sample rate for use in the audio processing graph.
    BOOL audioSessionActivated = [self.samplerUnit setupAudioSession];
    NSAssert (audioSessionActivated == YES, @"Unable to set up audio session.");
    
    // Create the audio processing graph; place references to the graph and to the Sampler unit
    // into the processingGraph and samplerUnit instance variables.
    [self.samplerUnit createAUGraph];
    [self.samplerUnit configureAndStartAudioProcessingGraph];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // デバイスのボリュームに対応させる
    MPVolumeView *volume_view = [[MPVolumeView alloc] initWithFrame: CGRectMake(0, 0, 0, 0)];
    volume_view.hidden = YES;
    [self.view addSubview: volume_view];
    
    self.settingView.hidden = YES;
    
    // Load the preset so the app is ready to play upon launch.
    [self.samplerUnit loadPreset];
    
    NSDictionary *preference = [self loadPreference];
    self.samplerUnit.centerNoteNum = [[preference objectForKey:@"centerNoteNum"] intValue];
    self.samplerUnit.pitchBendSensitivity = [[preference objectForKey:@"bendRange"] intValue];
    [self.samplerUnit controlChangePitchBendSensitivity];
    [self displayCenterNoteNum];
    [self displayPitchBendSensitivity:0];
    
    // CMMotionManagerのインスタンス生成
    motionManager = [[CMMotionManager alloc] init];
    
    if ([motionManager isDeviceMotionAvailable] == YES) {
        [motionManager setDeviceMotionUpdateInterval:updateInterval];
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                           withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            [self.samplerUnit pitchBend:deviceMotion.attitude.pitch];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Gestures

/**
 *
 */
- (IBAction)longPressView:(UILongPressGestureRecognizer *)sender {
    float horiz = 0.5;  // 水平方向の相対位置（画面下:0、画面上:100）
    float vert = 0.5;   // 垂直方向の相対位置（画面左:0、画面右:100）
    
    CGPoint location = [sender locationInView:self.view];
    horiz = (location.x / self.view.frame.size.width);
    vert = ((self.view.frame.size.height - location.y) / self.view.frame.size.height);

    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            [self.samplerUnit noteOn];
            [self.samplerUnit controlChangePan:horiz];
            [self.samplerUnit controlChangeVolume:vert];
            break;
        case UIGestureRecognizerStateChanged:
            [self.samplerUnit controlChangePan:horiz];
            [self.samplerUnit controlChangeVolume:vert];
            break;
        case UIGestureRecognizerStateEnded:
            [self.samplerUnit noteOff];
            break;
        default:
            break;
    }
}

/**
 *
 */
- (IBAction)panView:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.view];
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            self.settingView.hidden = NO;
            break;
        case UIGestureRecognizerStateChanged:
            [self.samplerUnit changeCenterNote:(translation.y * (-0.1))];
            [self displayCenterNoteNum];
            break;
        case UIGestureRecognizerStateEnded:
            self.settingView.hidden = YES;
            [self saveCenterNoteNum:self.samplerUnit.centerNoteNum];
            break;
        default:
            break;
    }
    [sender setTranslation:CGPointZero inView:self.view];
}

/**
 *
 */
- (IBAction)pinchView:(UIPinchGestureRecognizer *)sender {
    float bendRange = (self.samplerUnit.pitchBendSensitivity * sender.scale) - self.samplerUnit.pitchBendSensitivity;
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            self.settingView.hidden = NO;
            break;
        case UIGestureRecognizerStateChanged:
            [self displayPitchBendSensitivity:bendRange];
            break;
        case UIGestureRecognizerStateEnded:
            [self.samplerUnit changeBendRange:bendRange];
            self.settingView.hidden = YES;
            [self savePitchBendSensitivity:self.samplerUnit.pitchBendSensitivity];
            break;
        default:
            break;
    }
}

#pragma mark -
//#pragma mark

/**
 *
 */
- (void)displayCenterNoteNum {
    NSArray *noteNames = @[@"C", @"C♯/D♭", @"D", @"D♯/E♭", @"E", @"F", @"F♯/G♭", @"G", @"G♯/A♭", @"A", @"A♯/B♭", @"B"];
    
    int centerNoteNum = (int)self.samplerUnit.centerNoteNum;
    NSUInteger index = floor(centerNoteNum % 12);
    float freq = 440.0 * pow(2.0, (centerNoteNum - 69.0) / 12.0);
    
    self.centerNoteNum.text = [NSString stringWithFormat:@"centerNote = %@(%.2fHz)", [noteNames objectAtIndex:index], freq];
}

/**
 *
 */
- (void)displayPitchBendSensitivity:(float)bendRange {
    if (((int)(self.samplerUnit.pitchBendSensitivity + bendRange) % 12) == 0) {
        self.pitchBendSensitivity.text = [NSString stringWithFormat:@"pitchBendSensitivity = %u(±%.0foctave)", (unsigned int)(self.samplerUnit.pitchBendSensitivity + bendRange), floor((self.samplerUnit.pitchBendSensitivity + bendRange) / 12)];
    } else {
        self.pitchBendSensitivity.text = [NSString stringWithFormat:@"pitchBendSensitivity = %u", (unsigned int)(self.samplerUnit.pitchBendSensitivity + bendRange)];
    }
}

#pragma mark -
//#pragma mark

/**
 *
 */
- (NSMutableDictionary *)loadPreference {
    NSMutableDictionary *preference;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *filesDir = [paths objectAtIndex:0];
    NSString *filePath = [filesDir stringByAppendingPathComponent:@"preference.json"];
    
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:filePath]){
        // ファイルの読み込み
        NSData *json = [[NSData alloc] initWithContentsOfFile:filePath];
        
        // JSON を NSArray に変換する
        NSError *jsonSerializeError;
        preference = [NSJSONSerialization JSONObjectWithData:json
                                                    options:NSJSONReadingAllowFragments
                                                      error:&jsonSerializeError];
    } else {
        preference = [@{
            @"centerNoteNum" : @69.0,   // A4（440Hz）
            @"bendRange"     : @6.0,    // ±半オクターブ（半音12個÷2）
        } mutableCopy];
    }
    return preference;
}

/**
 *
 */
- (void)saveCenterNoteNum:(float)centerNoteNum {
    NSNumber *number = [[NSNumber alloc] initWithInt:floor(centerNoteNum)];
    [self savePreference:@"centerNoteNum" value:number];
}

/**
 *
 */
- (void)savePitchBendSensitivity:(float)bendRange {
    NSNumber *number = [[NSNumber alloc] initWithInt:floor(bendRange)];
    [self savePreference:@"bendRange" value:number];
}

/**
 *
 */
- (void)savePreference:(NSString *)key value:(NSObject *)value {
    NSMutableDictionary *preference = [[self loadPreference] mutableCopy];
    
    [preference setObject: value forKey:key];
    
    // アプリバージョン情報
    [preference setObject: [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
                   forKey: @"version"];
    
    // ビルドバージョン情報
    [preference setObject: [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]
                   forKey: @"build"];

    // jsonファイル出力
    SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
    jsonWriter.humanReadable = YES;
    //jsonWriter.sortKeys = YES;
    
    
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
NSString *filesDir = [paths objectAtIndex:0];
NSString *filePath = [filesDir stringByAppendingPathComponent:@"preference.json"];
    
    [[jsonWriter stringWithObject:preference] writeToFile:filePath
                                               atomically:YES
                                                 encoding:NSUnicodeStringEncoding
                                                    error:nil];
}

@end
