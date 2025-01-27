---
title: ios蓝牙开发（二）ios连接外设的代码实现
tags: 蓝牙
categories: 蓝牙
abbrlink: 18121
date: 2016-06-22 12:01:03
---

> 上一篇文章介绍了蓝牙的技术知识，这里我们具体说明一下中心模式的应用场景。主设备（手机去扫描连接外设，发现外设服务和属性，操作服务和属性的应用。一般来说，外设（蓝牙设备，比如智能手环之类的东西）， 会由硬件工程师开发好，并定义好设备提供的服务，每个服务对于的特征，每个特征的属性（只读，只写，通知等等），本文例子的业务场景，就是用一手机app去读写蓝牙设备。

------

## ios连接外设的代码实现流程

```
1. 建立中心角色
2. 扫描外设（discover）
3. 连接外设(connect)
4. 扫描外设中的服务和特征(discover)
    - 4.1 获取外设的services
    - 4.2 获取外设的Characteristics,获取Characteristics的值，获取Characteristics的Descriptor和Descriptor的值
5. 与外设做数据交互(explore and interact)
6. 订阅Characteristic的通知
7. 断开连接(disconnect)
```

## 准备环境

```
  1 xcode
  2 开发证书和手机（蓝牙程序需要使用使用真机调试，使用模拟器也可以调试，但是方法很蛋疼，我会放在最后说）
  3 蓝牙外设
```

## 实现步骤

### 1 导入CoreBluetooth头文件，建立主设备管理类，设置主设备委托



<!-- more -->

------

```objective-c
#import <CoreBluetooth/CoreBluetooth.h>
@interface ViewController : UIViewController<CBCentralManagerDelegate>


@interface ViewController (){
  //系统蓝牙设备管理对象，可以把他理解为主设备，通过他，可以去扫描和链接外设
  CBCentralManager *manager;
  //用于保存被发现设备
  NSMutableArray *peripherals;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  /*
   设置主设备的委托,CBCentralManagerDelegate
      必须实现的：
      - (void)centralManagerDidUpdateState:(CBCentralManager *)central;//主设备状态改变的委托，在初始化CBCentralManager的适合会打开设备，只有当设备正确打开后才能使用
      其他选择实现的委托中比较重要的：
      - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI; //找到外设的委托
      - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功的委托
      - (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//外设连接失败的委托
      - (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//断开外设的委托
  */
   //初始化并设置委托和线程队列，最好一个线程的参数可以为nil，默认会就main线程
   manager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
```

### 2 扫描外设（discover），扫描外设的方法我们放在centralManager成功打开的委托中，因为只有设备成功打开，才能开始扫描，否则会报错。

------

```objective-c
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{

    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@">>>CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@">>>CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@">>>CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@">>>CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@">>>CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@">>>CBCentralManagerStatePoweredOn");
            //开始扫描周围的外设
            /*
             第一个参数nil就是扫描周围所有的外设，扫描到外设后会进入
                  - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
             */
            [manager scanForPeripheralsWithServices:nil options:nil];

            break;
        default:
            break;
    }

}

//扫描到设备会进入方法
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{

    NSLog(@"当扫描到设备:%@",peripheral.name);
    //接下来可以连接设备

}
```

### 3 连接外设(connect)

------

```objective-c
//扫描到设备会进入方法
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{

    //接下连接我们的测试设备，如果你没有设备，可以下载一个app叫lightbule的app去模拟一个设备
    //这里自己去设置下连接规则，我设置的是P开头的设备
     if ([peripheral.name hasPrefix:@"P"]){
     /*
         一个主设备最多能连7个外设，每个外设最多只能给一个主设备连接,连接成功，失败，断开会进入各自的委托
      - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功的委托
      - (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//外设连接失败的委托
      - (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//断开外设的委托
      */

      //找到的设备必须持有它，否则CBCentralManager中也不会保存peripheral，那么CBPeripheralDelegate中的方法也不会被调用！！
      [peripherals addObject:peripheral];
      //连接设备
     [manager connectPeripheral:peripheral options:nil];
  }

}

//连接到Peripherals-成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@">>>连接到名称为（%@）的设备-成功",peripheral.name);
}

//连接到Peripherals-失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
}

//Peripherals断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]);

}
```

有一点非常容易出错，大家请注意。在 `didDiscoverPeripheral`这个委托中有这一行

```
//找到的设备必须持有它，否则CBCentralManager中也不会保存peripheral，那么CBPeripheralDelegate中的方法也不会被调用！！
[peripherals addObject:peripheral];
```

**请特别注意，如果不保存，会影响到后面的方法执行，这个地方很多人出错，在我的蓝牙交流群中每天几乎都会因为这个问题导致无法连接和对外设后续的操作。**

大家也可以看一下这个委托在xcode中的说明,重点看@discussion中的内容，里面特别指出了需要retained对象。

```
/*!
 *  @method centralManager:didDiscoverPeripheral:advertisementData:RSSI:
 *
 *  @param central              The central manager providing this update.
 *  @param peripheral           A <code>CBPeripheral</code> object.
 *  @param advertisementData    A dictionary containing any advertisement and scan response data.
 *  @param RSSI                 The current RSSI of <i>peripheral</i>, in dBm. A value of <code>127</code> is reserved and indicates the RSSI
 *								was not available.
 *
 *  @discussion                 This method is invoked while scanning, upon the discovery of <i>peripheral</i> by <i>central</i>. A discovered peripheral must
 *                              be retained in order to use it; otherwise, it is assumed to not be of interest and will be cleaned up by the central manager. For
 *                              a list of <i>advertisementData</i> keys, see {@link CBAdvertisementDataLocalNameKey} and other similar constants.
 *
 *  @seealso                    CBAdvertisementData.h
 *
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI;
```

### 4扫描外设中的服务和特征(discover)

------

设备连接成功后，就可以扫描设备的服务了，同样是通过委托形式，扫描到结果后会进入委托方法。但是这个委托已经不再是主设备的委托（CBCentralManagerDelegate），而是外设的委托（CBPeripheralDelegate）,这个委托包含了主设备与外设交互的许多 回叫方法，包括获取services，获取characteristics，获取characteristics的值，获取characteristics的Descriptor，和Descriptor的值，写数据，读rssi，用通知的方式订阅数据等等。

### 4.1获取外设的services

```objective-c
//连接到Peripherals-成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@">>>连接到名称为（%@）的设备-成功",peripheral.name);
    //设置的peripheral委托CBPeripheralDelegate
    //@interface ViewController : UIViewController<CBCentralManagerDelegate,CBPeripheralDelegate>
    [peripheral setDelegate:self];
    //扫描外设Services，成功后会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    [peripheral discoverServices:nil];

}

//扫描到Services
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    //  NSLog(@">>>扫描到服务：%@",peripheral.services);
    if (error)
    {
        NSLog(@">>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }

    for (CBService *service in peripheral.services) {
         NSLog(@"%@",service.UUID);
         //扫描每个service的Characteristics，扫描到后会进入方法： -(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
         [peripheral discoverCharacteristics:nil forService:service];
     }

}
```

### 4.2获取外设的Characteristics,获取Characteristics的值，获取Characteristics的Descriptor和Descriptor的值

```objective-c
 //扫描到Characteristics
 -(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
     if (error)
     {
         NSLog(@"error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
         return;
     }

     for (CBCharacteristic *characteristic in service.characteristics)
     {
         NSLog(@"service:%@ 的 Characteristic: %@",service.UUID,characteristic.UUID);
     }

     //获取Characteristic的值，读到数据会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
     for (CBCharacteristic *characteristic in service.characteristics){
         {
             [peripheral readValueForCharacteristic:characteristic];
         }
     }

     //搜索Characteristic的Descriptors，读到数据会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
     for (CBCharacteristic *characteristic in service.characteristics){
         [peripheral discoverDescriptorsForCharacteristic:characteristic];
     }

 }

//获取的charateristic的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //打印出characteristic的UUID和值
    //!注意，value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
    NSLog(@"characteristic uuid:%@  value:%@",characteristic.UUID,characteristic.value);

}

//搜索到Characteristic的Descriptors
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{

    //打印出Characteristic和他的Descriptors
     NSLog(@"characteristic uuid:%@",characteristic.UUID);
    for (CBDescriptor *d in characteristic.descriptors) {
        NSLog(@"Descriptor uuid:%@",d.UUID);
    }

}
//获取到Descriptors的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    //打印出DescriptorsUUID 和value
    //这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
    NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);
}
```

### 5 把数据写到Characteristic中

------

```objective-c
//写数据
-(void)writeCharacteristic:(CBPeripheral *)peripheral
            characteristic:(CBCharacteristic *)characteristic
                     value:(NSData *)value{

    //打印出 characteristic 的权限，可以看到有很多种，这是一个NS_OPTIONS，就是可以同时用于好几个值，常见的有read，write，notify，indicate，知知道这几个基本就够用了，前连个是读写权限，后两个都是通知，两种不同的通知方式。
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast												= 0x01,
     CBCharacteristicPropertyRead													= 0x02,
     CBCharacteristicPropertyWriteWithoutResponse									= 0x04,
     CBCharacteristicPropertyWrite													= 0x08,
     CBCharacteristicPropertyNotify													= 0x10,
     CBCharacteristicPropertyIndicate												= 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites								= 0x40,
     CBCharacteristicPropertyExtendedProperties										= 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)		= 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)	= 0x200
     };

     */
    NSLog(@"%lu", (unsigned long)characteristic.properties);


    //只有 characteristic.properties 有write的权限才可以写
    if(characteristic.properties & CBCharacteristicPropertyWrite){
        /*
            最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
        */
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }else{
        NSLog(@"该字段不可写！");
    }


}
```

### 6 订阅Characteristic的通知

------

```objective-c
//设置通知
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
            characteristic:(CBCharacteristic *)characteristic{
    //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];

}

//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{

     [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}
```

### 7 断开连接(disconnect)

------

```objective-c
//停止扫描并断开连接
-(void)disconnectPeripheral:(CBCentralManager *)centralManager
                 peripheral:(CBPeripheral *)peripheral{
    //停止扫描
    [centralManager stopScan];
    //断开连接
    [centralManager cancelPeripheralConnection:peripheral];
}
```

### 8 模拟器蓝牙调试，慎用，最好还是用真机去调试。

------

```
由于在iPhone 4s之后的iOS才支持BLE，新一代的这些iOS设备又都不便宜，在做测试的时候，用iOS模拟器进行调试，可以节约一些开发成本。怎么在iOS模拟器上调试BLE，
苹果最初给出的说明是，支持BLE的mac机子上可以用模拟器进行调试，并给出了一份技术文档（传送门），恶心的是，后来苹果抽风，又把这份文档移除，
并且把iOS 7.0的模拟器上对BLE的支持也移除掉了（难道是想让大家多买设备测试？Apple sucks.）后面，网上搜了一下，解决办法如下：
1. 买一个CSR蓝牙4.0 USB适配器（某宝上大概30块钱），在机子上插入该物（你懂的）
2. 在Terminal下敲入sudo nvram bluetoothHostControllerSwitchBehavior="never" ， 重启Mac。
3. 用XCode 4.6调试代码，在iOS 6.1的模拟器上跑程序（用XCode 5.0跑iOS 7.0模拟器会抛异常，原因上面详诉过了，Apple sucks，你懂的）

如何降低模拟器的IOS版本呢？
XCode->Preferences->Downloads里面有很多simulators你可以下载
选择个6.1的下载好了
```

------

## 代码下载:

我博客中大部分示例代码都上传到了github，地址是：https://github.com/coolnameismy/demo，[点击跳转代码下载地址](https://github.com/coolnameismy/demo)