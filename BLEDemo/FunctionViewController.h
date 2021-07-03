//
//  FunctionViewController.h
//  BLEDemo
//
//  Created by Bri on 2021/4/21.
//

#import <UIKit/UIKit.h>
#import "CustomBlueTooth.h"
#import <BabyBluetooth/BabyBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface FunctionViewController : UIViewController {
    @public
    BabyBluetooth *baby;
}

@property (nonatomic, strong) DeviceModel *device;

@end

NS_ASSUME_NONNULL_END
