//
//  ViewController.m
//  BluetoothCentral
//
//  Created by 张齐朴 on 16/1/22.
//  Copyright © 2016年 张齐朴. All rights reserved.
//

#import "ViewController.h"

#import <objc/runtime.h>

#define kServiceUUID               @"2C970FA1-FCC3-4BE4-A569-DB4BAFC6B4AB"
#define kReadCharacteristicUUID    @"50991972-5B10-419F-A4A0-14DEBC82283A"
#define kWriteCharacteristicUUID   @"56BA32DE-7AFA-44A0-BD3A-19C00C1687CA"
#define kBluetoothName             @"SERVER_ADVERTISE"

@interface ViewController ()

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCharacteristic *characteristic_r;
@property (nonatomic, strong) CBCharacteristic *characteristic_w;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupCentralManager];
}

- (void)setupCentralManager
{
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark
#pragma mark CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self appendTextViewText:[NSString stringWithFormat:@"%ld", (long)central.state]];
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self.centralManager
         scanForPeripheralsWithServices:nil
         options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
    }
}

// 发现设备
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    [self appendTextViewText:peripheral.name];
    
    if ([peripheral.name isEqualToString:kBluetoothName]) {
        [self.centralManager stopScan];
        
        if (self.peripheral != peripheral) {
            self.peripheral = peripheral;
            [self.centralManager connectPeripheral:self.peripheral
                                           options:nil];
        }
    }
}

// 已经连接设备
- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self appendTextViewText:[NSString stringWithFormat:@"已连接设备%@", peripheral.name]];
    
    if (self.peripheral && self.peripheral == peripheral) {
        self.peripheral.delegate = self;
        [self.peripheral discoverServices:nil];
    }
}

// 连接设备失败
- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(nullable NSError *)error
{
    [self appendTextViewText:[NSString stringWithFormat:@"%@", error]];
}

#pragma mark
#pragma mark CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *s in peripheral.services) {
        if ([s.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
            [self appendTextViewText:[NSString stringWithFormat:@"发现服务%@", kServiceUUID]];
            [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kReadCharacteristicUUID],
                                                       [CBUUID UUIDWithString:kWriteCharacteristicUUID]]
                                          forService:s];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    for (CBCharacteristic *c in service.characteristics) {
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:kReadCharacteristicUUID]]) {
            // 订阅某个特征
            [self appendTextViewText:[NSString stringWithFormat:@"发现特征读%@", kReadCharacteristicUUID]];
            [service.peripheral setNotifyValue:YES forCharacteristic:c];
            self.characteristic_r = c;
        }
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:kWriteCharacteristicUUID]]) {
            [self appendTextViewText:[NSString stringWithFormat:@"发现特征写%@", kWriteCharacteristicUUID]];
            self.characteristic_w = c;
        }
    }
}

// 当外围设备特征值改变的时候如果中心有订阅会调用这个方法
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error == nil)
    {
        if (characteristic.isNotifying) {
            // 读特征数据
            if (self.peripheral == peripheral) {
                [self.peripheral readValueForCharacteristic:characteristic];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    NSData *data = characteristic.value;
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [self appendTextViewText:str];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error == nil) {
        [self appendTextViewText:@"写数据成功"];
    }
}

- (void)appendTextViewText:(NSString *)text
{
    NSLog(@"%@", text);
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:
                              [NSString stringWithFormat:@"\n%@\n",text]];
    
    [self.textView.textStorage appendAttributedString:as];
}

- (IBAction)sendButtonAction:(UIButton *)sender
{
    NSData *data = [@"ok" dataUsingEncoding:NSUTF8StringEncoding];
    [self.peripheral writeValue:data
              forCharacteristic:self.characteristic_w
                           type:CBCharacteristicWriteWithResponse];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
