//
//  AVInputViewController.h
//  HealthNAVI
//
//  Created by Francis Jemuel Bergonia on 11/11/19.
//  Copyright © 2019 Arkray Marketing, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AVInputViewController;
@protocol inputSpeechViewControllerDelegate<NSObject>
- (void)addItemViewController:(inputSpeech_vc *)controller didFinishEnteringItem:(NSString *)item;
@end

@interface AVInputViewController: UIViewController
@property (nonatomic, weak, nullable) id<inputSpeechViewControllerDelegate> passBackdelegate;
@end

NS_ASSUME_NONNULL_END
