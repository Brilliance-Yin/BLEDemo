//
//  ViewController.m
//  BLEDemo
//
//  Created by Bri on 2021/4/21.
//

#import "ViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "CustomBlueTooth.h"
#import "FunctionViewController.h"
#import <BabyBluetooth/BabyBluetooth.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource> {
    BabyBluetooth *baby;
}

@property (nonatomic, strong) NSMutableArray *deviceArray;
@property (nonatomic, strong) UITableView *tableView;


@end

@implementation ViewController

- (NSMutableArray *)deviceArray {
    if (!_deviceArray) {
        _deviceArray = [NSMutableArray array];
    }
    return _deviceArray;
}

- (UITableView *)tableView {
    if(!_tableView){
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        _tableView.backgroundColor = UIColor.whiteColor;
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [baby cancelAllPeripheralsConnection];
    baby.scanForPeripherals().begin();
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"搜索中...";
    
    baby = [BabyBluetooth shareBabyBluetooth];
    [self babyDelegate];
    
//    [[CustomBlueTooth shareInstance] scanAllDeviceCallback:^(DeviceModel * _Nonnull device) {
//        NSLog(@"设备%@", device.equipName);
//        
//        //去重
//        BOOL isExist = false;
//        for (DeviceModel *deviceModel in self.deviceArray) {
//            if ([deviceModel.identifier isEqualToString:device.identifier]) {
//                isExist = true;
//            }
//        }
//
//        if (![self.deviceArray containsObject:device] && !isExist && device.peripheral.identifier.UUIDString.length > 0) {
//            [self.deviceArray addObject:device];
//        }
//
//        if (self.deviceArray.count > 0) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.tableView reloadData];
//            });
//        }
//    }];
    
}

- (void)babyDelegate {
    
    __weak typeof(self) weakSelf = self;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBCentralManagerStatePoweredOn) {
            [SVProgressHUD showInfoWithStatus:@"设备打开成功，开始扫描设备"];
        }
    }];
    
    //设置扫描到设备的委托
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备:%@",peripheral.name);
        NSString *macString = [weakSelf getMacString:advertisementData[@"kCBAdvDataLeBluetoothDeviceAddress"]];
        DeviceModel *scanDevice = [[DeviceModel alloc] init];
        scanDevice.equipName = peripheral.name;
        scanDevice.peripheral = peripheral;
        if (macString.length == 20) {
            macString = [macString substringFromIndex:3];
        }
        scanDevice.macString = macString.uppercaseString;
        scanDevice.identifier = peripheral.identifier.UUIDString;
        
        //去重
        BOOL isExist = false;
        for (DeviceModel *deviceModel in weakSelf.deviceArray) {
            if ([deviceModel.identifier isEqualToString:peripheral.identifier.UUIDString]) {
                isExist = true;
            }
        }
        if (![self.deviceArray containsObject:scanDevice] && !isExist) {
            [self.deviceArray addObject:scanDevice];
        }
        if (self.deviceArray.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    
    }];
    
   
    //设置发现设service的Characteristics的委托
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        NSLog(@"===service name:%@",service.UUID);
        for (CBCharacteristic *c in service.characteristics) {
            NSLog(@"charateristic name is :%@",c.UUID);
        }
    }];
    //设置读取characteristics的委托
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        NSLog(@"characteristic name:%@ value is:%@",characteristics.UUID,characteristics.value);
    }];
    //设置发现characteristics的descriptors的委托
    [baby setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"===characteristic name:%@",characteristic.service.UUID);
        for (CBDescriptor *d in characteristic.descriptors) {
            NSLog(@"CBDescriptor name is :%@",d.UUID);
        }
    }];
    //设置读取Descriptor的委托
    [baby setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        NSLog(@"Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    }];
    
    //设置查找设备的过滤器
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSString *macString = [weakSelf getMacString:advertisementData[@"kCBAdvDataLeBluetoothDeviceAddress"]];
        if (peripheralName.length > 0 && macString.length > 0) {
            return YES;
        }
        return NO;
    }];
    
    [baby setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
        NSLog(@"setBlockOnCancelAllPeripheralsConnectionBlock");
    }];
       
    [baby setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        NSLog(@"setBlockOnCancelScanBlock");
    }];
    
    
    /*设置babyOptions
        
        参数分别使用在下面这几个地方，若不使用参数则传nil
        - [centralManager scanForPeripheralsWithServices:scanForPeripheralsWithServices options:scanForPeripheralsWithOptions];
        - [centralManager connectPeripheral:peripheral options:connectPeripheralWithOptions];
        - [peripheral discoverServices:discoverWithServices];
        - [peripheral discoverCharacteristics:discoverWithCharacteristics forService:service];
        
        该方法支持channel版本:
            [baby setBabyOptionsAtChannel:<#(NSString *)#> scanForPeripheralsWithOptions:<#(NSDictionary *)#> connectPeripheralWithOptions:<#(NSDictionary *)#> scanForPeripheralsWithServices:<#(NSArray *)#> discoverWithServices:<#(NSArray *)#> discoverWithCharacteristics:<#(NSArray *)#>]
     */
    
    //示例:
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    //连接设备->
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:BLESERVICEUUID]] discoverWithServices:nil discoverWithCharacteristics:nil];

}

#pragma mark --tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.deviceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"cell";
    UITableViewCell *cell;
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    DeviceModel *model = self.deviceArray[indexPath.row];
    cell.textLabel.text = model.equipName;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 54;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [SVProgressHUD show];
    DeviceModel *model = self.deviceArray[indexPath.row];
    [baby cancelScan];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    FunctionViewController *functionVC = [[FunctionViewController alloc] init];
    functionVC.device = model;
    functionVC->baby = self->baby;
    [self.navigationController pushViewController:functionVC animated:YES];
    
//    [[CustomBlueTooth shareInstance] connectDeviceWithDevice:model callBack:^(BOOL success) {
//
//            [[CustomBlueTooth shareInstance] getDeviceInfoWithDevice:model callBack:^(NSData * _Nonnull data) {
//                if (data) {
//                    NSLog(@"版本信息——%@", data);
//                    [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"版本信息——%@", data]];
//                    FunctionViewController *vc = [[FunctionViewController alloc] init];
//                    vc.device = model;
//                    [self.navigationController pushViewController:vc animated:YES];
//                }
//            }];
//    }];
    
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
