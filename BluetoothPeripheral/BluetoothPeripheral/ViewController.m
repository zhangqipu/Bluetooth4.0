//
//  ViewController.m
//  BluetoothPeripheral
//
//  Created by 张齐朴 on 16/1/22.
//  Copyright © 2016年 张齐朴. All rights reserved.
//

#import "ViewController.h"

#define kServiceUUID               @"2C970FA1-FCC3-4BE4-A569-DB4BAFC6B4AB"
#define kReadCharacteristicUUID    @"50991972-5B10-419F-A4A0-14DEBC82283A"
#define kWriteCharacteristicUUID   @"56BA32DE-7AFA-44A0-BD3A-19C00C1687CA"
#define kBluetoothName             @"SERVER_ADVERTISE"

@interface ViewController ()

@property (nonatomic, strong) CBUUID *custumServiceUUID;
@property (nonatomic, strong) CBMutableService *service;
@property (nonatomic, strong) CBMutableCharacteristic *characteristic_r;
@property (nonatomic, strong) CBMutableCharacteristic *characteristic_w;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupPeripheralManager];
    [self setupServicesAndCharacteristics];
}

- (void)setupPeripheralManager
{
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (void)setupServicesAndCharacteristics
{
    self.custumServiceUUID           = [CBUUID UUIDWithString:kServiceUUID];
    CBUUID *customReadcteristicUUID  = [CBUUID UUIDWithString:kReadCharacteristicUUID];
    CBUUID *customWritecteristicUUID = [CBUUID UUIDWithString:kWriteCharacteristicUUID];
    
    self.characteristic_r =
    [[CBMutableCharacteristic alloc] initWithType:customReadcteristicUUID
                                       properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead // 值改变时被通知，特征可读
                                            value:nil
                                      permissions:CBAttributePermissionsReadable]; // CBATTRequest 可读
    self.characteristic_w =
    [[CBMutableCharacteristic alloc] initWithType:customWritecteristicUUID
                                       properties:CBCharacteristicPropertyWrite // 特征可写
                                            value:nil
                                      permissions:CBAttributePermissionsWriteable]; // CBATTRequest 可写
    
    self.service = [[CBMutableService alloc] initWithType:self.custumServiceUUID primary:YES];
    self.service.characteristics = @[self.characteristic_r, self.characteristic_w];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    [self appendTextViewText:[NSString stringWithFormat:@"%ld", (long)peripheral.state]];
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        [self publishServicesAndCharacteristics];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error
{
    if (error == nil) {
        [self appendTextViewText:@"添加服务成功"];
        [self advertiseServices];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (error == nil) {
        [self appendTextViewText:@"广播开启成功"];
        
    }
}

// 此设备特征被订阅
- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    [self appendTextViewText:@"此设备特征被订阅"];
    
}

// 中心设备读此外设请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    [self appendTextViewText:[NSString stringWithFormat:@"%@", request]];
    
    if ([request.characteristic.UUID isEqual:self.characteristic_r.UUID]) {
        if (request.offset > self.characteristic_r.value.length) { // 读取越界
            [self.peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
        }
        
        request.value = [self.characteristic_r.value subdataWithRange:
                         (NSRange){request.offset, self.characteristic_r.value.length - request.offset}];
        
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

// 中心设备写此设备请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
    [self appendTextViewText:[NSString stringWithFormat:@"%@", requests]];

    CBATTRequest *request = requests[0];
    
    self.characteristic_w.value = request.value;
    
    [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
}

- (void)publishServicesAndCharacteristics
{
    [self.peripheralManager addService:self.service];
}

- (void)advertiseServices
{
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataLocalNameKey:kBluetoothName,
                                               CBAdvertisementDataServiceUUIDsKey:@[self.custumServiceUUID]
                                               }];
}

- (IBAction)writeDataAction:(id)sender
{
    NSData *data = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
    
    // 向此设备特征写数据
    [self.peripheralManager updateValue:data
                      forCharacteristic:self.characteristic_r
                   onSubscribedCentrals:nil];
    [self appendTextViewText:@"写数据"];
}

- (void)appendTextViewText:(NSString *)text
{
    NSLog(@"%@",text);
    
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:
                              [NSString stringWithFormat:@"\n%@\n",text]];
    
    [self.textView.textStorage appendAttributedString:as];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
