//
//  CustomBlueTooth.h
//  BLEDemo
//
//  Created by Bri on 2021/4/21.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const BLESERVICEUUID = @"8653000A-43E6-47B7-9CB0-5FC21D4AE340";
static NSString *const BLEREADUUID = @"8653000B-43E6-47B7-9CB0-5FC21D4AE340";
static NSString *const BLEWRITEUUID = @"8653000C-43E6-47B7-9CB0-5FC21D4AE340";

//设备当前状态
typedef NS_ENUM(NSUInteger, DeviceStaus) {
    DeviceStausDefault,         //扫描状态
    DeviceStausConnected,       //连接状态
    DeviceStausUsed,            //使用过
};

@class DeviceModel;
typedef void (^blueToothScanCallback)(DeviceModel *device);
typedef void (^blueToothConnectCallback)(BOOL success);
typedef void (^blueToothGetInfoCallback)(NSData *data);

@interface CustomBlueTooth : NSObject {
    @private
    NSMutableArray *connectedDevices;
    NSMutableArray *scanDevices;
}

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *currentPeripheral;

@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;
@property (nonatomic, strong) CBCharacteristic *readCharacteristic;

+ (instancetype)shareInstance;

/** 扫描设备 */
- (void)scanAllDeviceCallback:(blueToothScanCallback)callback;
/** 连接设备 */
- (void)connectDeviceWithDevice:(DeviceModel *)device callBack:(blueToothConnectCallback)callback;
/** 获取设备版本信息 */
- (void)getDeviceInfoWithDevice:(DeviceModel *)device callBack:(blueToothGetInfoCallback)callback;
/** <#param#> */
- (void)getDeviceStatusWithDevice:(DeviceModel *)device callBack:(blueToothGetInfoCallback)callback;

/** 获取当前连接的设备 */
- (NSArray *)findConnectedDevices;
- (void)disconnectAllDevice;

@end

@interface DeviceModel : NSObject

///使用天数
@property (nonatomic, strong) NSString *useDay;
///设备类型名称
@property (nonatomic, strong) NSString *equipName;
///最近使用时间
@property (nonatomic, strong) NSString *equipActiveTime;
///固件版本号
@property (nonatomic, strong) NSString *firmwareVersion;
///
@property (nonatomic, strong) NSString *quanElectricity;
///品牌
@property (nonatomic, strong) NSString *brand;
///MAC地址
@property (nonatomic, strong) NSString *macString;

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) CBPeripheral *_Nullable peripheral;
@property (nonatomic, assign) DeviceStaus deviceStatus;

@end

NS_ASSUME_NONNULL_END
