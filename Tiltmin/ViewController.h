//
//  ViewController.h
//  Tiltmin
//
//  Created by caroline on 2014/12/31.
//  Copyright (c) 2014年 MOOI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <MediaPlayer/MediaPlayer.h>
#import "SamplerUnit.h"

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *settingView;
@property (weak, nonatomic) IBOutlet UILabel *centerNoteNum;
@property (weak, nonatomic) IBOutlet UILabel *pitchBendSensitivity;

@property (strong, nonatomic) SamplerUnit *samplerUnit;

- (IBAction)longPressView:(UILongPressGestureRecognizer *)sender;
- (IBAction)panView:(UIPanGestureRecognizer *)sender;
- (IBAction)pinchView:(UIPinchGestureRecognizer *)sender;

@end

