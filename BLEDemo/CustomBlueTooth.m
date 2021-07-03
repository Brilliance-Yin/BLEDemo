//
//  CustomBlueTooth.m
//  BLEDemo
//
//  Created by Bri on 2021/4/21.
//

#import "CustomBlueTooth.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface CustomBlueTooth () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, copy) blueToothScanCallback scanCallBack;
@property (nonatomic, copy) blueToothConnectCallback connectCallBack;
@property (nonatomic, copy) blueToothGetInfoCallback getInfoCallBack;
@property (nonatomic, copy) blueToothGetInfoCallback getStatusCallBack;
@property (nonatomic, assign) BOOL first;

@end

@implementation CustomBlueTooth

+ (instancetype)shareInstance {
    static CustomBlueTooth *share = nil ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[CustomBlueTooth alloc] init];
    });
    return share;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        connectedDevices = [[NSMutableArray alloc] init];
        scanDevices = [[NSMutableArray alloc] init];
    }
    return self;
}

- (CBCentralManager *)centralManager {
    if (!_centralManager) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return _centralManager;
}

#pragma mark - 扫描设备
- (void)scanAllDeviceCallback:(blueToothScanCallback)callback {
    if (callback) {
        _scanCallBack = [callback copy];
    }
    if (self.centralManager.state == CBManagerStatePoweredOn) {
        scanDevices = [NSMutableArray array];
        [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:BLESERVICEUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    }
}

#pragma mark - 连接设备
- (void)connectDeviceWithDevice:(DeviceModel *)device callBack:(blueToothConnectCallback)callback {
    if (callback) {
        _connectCallBack = [callback copy];
    }

    [self.centralManager connectPeripheral:device.peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES}];
}

#pragma mark - 获取设备信息
- (void)getDeviceInfoWithDevice:(DeviceModel *)device callBack:(blueToothGetInfoCallback)callback {
    if (callback) {
        _getInfoCallBack = [callback copy];
        self.first = YES;
        
        [self.currentPeripheral discoverServices:nil];
    }
}

- (void)getDeviceStatusWithDevice:(DeviceModel *)device callBack:(blueToothGetInfoCallback)callback {
    if (callback) {
        _getStatusCallBack = [callback copy];
        self.first = YES;
    
        [self.currentPeripheral discoverServices:nil];
    }
}

- (void)disconnectAllDevice {
    for (DeviceModel *device in connectedDevices) {
        if (device.peripheral) {
            [self.centralManager cancelPeripheralConnection:device.peripheral];
        }
    }
    [connectedDevices removeAllObjects];
}

#pragma mark - CentralManager代理
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        scanDevices = [NSMutableArray array];
        [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:BLESERVICEUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    }
}

#pragma mark - 发现设备代理
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSString *macString = [self getMacString:advertisementData[@"kCBAdvDataLeBluetoothDeviceAddress"]];
    if (peripheral.name.length > 0 && macString.length > 0) {
        NSLog(@"发现设备——%@", peripheral.name);
        DeviceModel *scanDevice = [[DeviceModel alloc] init];
        scanDevice.equipName = peripheral.name;
        scanDevice.peripheral = peripheral;
        if (macString.length == 20) {
            macString = [macString substringFromIndex:3];
        }
        scanDevice.macString = macString.uppercaseString;
        scanDevice.identifier = peripheral.identifier.UUIDString;
        
        [scanDevices addObject:scanDevice];
        if (_scanCallBack) {
            _scanCallBack(scanDevice);
        }
    }
}

#pragma mark - 设备连接代理
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [SVProgressHUD showSuccessWithStatus:@"连接成功"];
    self.currentPeripheral = peripheral;
    
    //保存已连接设备
    for (DeviceModel *device in scanDevices) {
        if ([device.identifier isEqualToString:peripheral.identifier.UUIDString]) {
            [self addDevice:device];
        }
    }
    
    [peripheral discoverServices:nil];
    peripheral.delegate = self;
    [self.centralManager stopScan];
    if (_connectCallBack) {
        _connectCallBack(YES);
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [SVProgressHUD showSuccessWithStatus:@"连接失败"];
    [self.centralManager stopScan];
    if (_connectCallBack) {
        _connectCallBack(NO);
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [SVProgressHUD showSuccessWithStatus:@"失去连接"];
    //删除失去连接设备
    for (DeviceModel *device in scanDevices) {
        if ([device.identifier isEqualToString:peripheral.identifier.UUIDString]) {
            [self removeDevice:device];
        }
    }
}

#pragma mark - 发现服务代理
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSArray *services = peripheral.services;
    // 根据服务再次扫描每个服务对应的特征
    for (CBService *ses in services) {
        [peripheral discoverCharacteristics:nil forService:ses];
    }
}

#pragma mark - 发现特征代理
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSArray *ctcs = service.characteristics;
    for (CBCharacteristic *character in ctcs) {
        CBCharacteristicProperties properties = character.properties;
         
        if (properties & CBCharacteristicPropertyNotify) {
            //如果具备通知的特性
            [peripheral setNotifyValue:YES forCharacteristic:character];
        }

        if ([character.UUID.UUIDString isEqualToString:BLEWRITEUUID]) {
            self.writeCharacteristic = character;
        }
        if ([character.UUID.UUIDString isEqualToString:BLEREADUUID]) {
            self.readCharacteristic = character;
            [self.currentPeripheral setNotifyValue:YES forCharacteristic:self.readCharacteristic];
        }
    }
    
    if (_getInfoCallBack && self.first) {
        if (self.readCharacteristic && self.writeCharacteristic) {
            Byte byte[] = {0xAA, 0x55, 0x10};
            NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)];
            [peripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
            self.first = NO;
        }
    }
    if (_getStatusCallBack && self.first) {
        if (self.readCharacteristic && self.writeCharacteristic) {
            Byte byte[] = {0xAA, 0x55, 0x20, 0x01, 0x00, 0x01, 0x24};
//            Byte byte[] = {0xCC, 0x55, 0x40};
            NSData *data = [NSData dataWithBytes:&byte length:sizeof(byte)];
            [peripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
            self.first = NO;
        }
    }
}

- (void)setReadCharacteristic:(CBCharacteristic *)readCharacteristic {
    if (!_readCharacteristic) {
        _readCharacteristic = readCharacteristic;
    }
}

- (void)setWriteCharacteristic:(CBCharacteristic *)writeCharacteristic {
    if (!_writeCharacteristic) {
        _writeCharacteristic = writeCharacteristic;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"写入数据成功");
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (_getInfoCallBack) {
        _getInfoCallBack(characteristic.value);
        _getInfoCallBack = nil;
    }
    if (_getStatusCallBack) {
        _getStatusCallBack(characteristic.value);
    }
}

#pragma mark - 设备本地处理
- (void)addDevice:(DeviceModel *)device {
    if (![connectedDevices containsObject:device]) {
        [connectedDevices addObject:device];
    }
}

- (void)removeDevice:(DeviceModel *)device {
    if ([connectedDevices containsObject:device]) {
        [connectedDevices removeObject:device];
    }
}

- (NSArray *)findConnectedDevices {
    return connectedDevices;
}

#pragma mark - mac地址解析
- (NSString *)getMacString:(id)data {
    NSData *addressData = data;
    __block NSString *macString = @"";
    NSString *mac = [self convertToNSStringWithNSData:addressData];
    NSMutableArray *macArray = [NSMutableArray array];
    for (int i = 0; i < mac.length/2; i++) {
        NSString *tempString = [mac substringWithRange:NSMakeRange(i*2, 2)];
        [macArray addObject:tempString];
    }
    //倒序取值
    [macArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *tempString = obj;
        if (idx == macArray.count - 1) {
            macString = tempString;
        }else {
            macString = [NSString stringWithFormat:@"%@:%@", macString, tempString];
        }
        if (idx == 0) {
            *stop = YES;
        }
    }];
    return macString;
}

- (NSString *)convertToNSStringWithNSData:(NSData *)data {
    NSMutableString *strTemp = [NSMutableString stringWithCapacity:[data length]*2];
    
    const unsigned char *szBuffer = [data bytes];
    
    for (NSInteger i=0; i < [data length]; ++i) {
        
        [strTemp appendFormat:@"%02lx",(unsigned long)szBuffer[i]];
        
    }
    return strTemp;
}

@end


@implementation DeviceModel

@end
