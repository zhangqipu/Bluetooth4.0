//
//  ViewController.h
//  BluetoothCentral
//
//  Created by 张齐朴 on 16/1/22.
//  Copyright © 2016年 张齐朴. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

