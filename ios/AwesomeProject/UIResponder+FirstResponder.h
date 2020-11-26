//
//  UIResponder+FirstResponder.h
//  Lowcost
//
//  Copyright © 2018 Electronic Temperature Instruments Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIResponder (FirstResponder)

+ (UIResponder *)currentFirstResponder;

@end
