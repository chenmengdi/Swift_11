//
//  Bluetooth_Central.swift
//  Swift_11
//
//  Created by 陈孟迪 on 2017/12/23.
//  Copyright © 2017年 陈孟迪. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol BlueToothCentralDelegate {

    func onScan(peripheral:AnyObject?,isStop:Int,rssi:AnyObject?)
    
}
enum PeripheralConnectReturnType {
    case PeripheralConnectTypeSuccess//连接成功
    case PeripheralConnextTypeFail//连接失败
    case PeripheralConnectTypeDisconnect//连接断开
}

class Bluetooth_Central: NSObject,CBCentralManagerDelegate,CBPeripheralDelegate {

    var manager:CBCentralManager?
    var per:CBPeripheral?
    var scanAllPeripheral:NSMutableArray?
    var scanTimer:Timer?
    var characterDict:NSMutableDictionary?
    var centralType:Int?
//    var startScanResult:((Int,NSNumber)->())?//第一个参数是扫描到的设备，第二个参数如果是0说明正在扫描，等于1停止扫描，第三个参数为设备的信号值
//    var stopScanResult:((Int)->())?
    var delegate:BlueToothCentralDelegate?
    
    var readResult:((NSString,NSData)->())?//第一个参数是设备的UUID，第二个参数是设备返回的数据，一般情况下是20个字节
    var connectResult:((NSString,PeripheralConnectReturnType)->Void)?//第一个参数是设备的UUID，第二个参数是设备连接的状态
    var errorRseult:((NSString,NSString)->())?
    
    var rssiResult:((NSString,NSNumber)->())?
    
    
    
    
    override init() {
        super.init()
        
        manager = CBCentralManager.init(delegate: self, queue: nil)
        scanAllPeripheral = NSMutableArray()
        characterDict = NSMutableDictionary()
        
        
    }

    //开始扫描蓝牙，timer为扫描的时间
    func didScan(timer:Int) {

        scanTimer = Timer.scheduledTimer(timeInterval: TimeInterval(timer), target: self, selector: #selector(stopScan), userInfo: nil, repeats: false)
        
        //扫描蓝牙的方法，第一个参数withServices是要扫描的服务的UUID数组
        manager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    //停止扫描
    @objc func stopScan() {
       
        //停止扫描
        manager?.stopScan()
        scanTimer?.invalidate()
        scanTimer = nil
        delegate?.onScan(peripheral: nil, isStop: 1, rssi: nil)
    }
    
    //连接蓝牙，参数peripheral为要连接的设备
    func didConnect(peripheral:CBPeripheral) {
        manager?.connect(peripheral, options: nil)
        
    }
   
    //断开蓝牙的连接，参数peripheral为要断开连接的设备
    func didDisConnect(peripheral:CBPeripheral) {
        manager?.cancelPeripheralConnection(peripheral)
        
    }
    
    //获取已经连接过的设备,参数uuidArray是已经连接过的设备的UUID,返回值是peripheral数组
    func didConnected(uuidArray:NSArray)->NSArray {
        
        let array:NSMutableArray = NSMutableArray()
        
        for u in uuidArray {
            let uuid:NSString = u as! NSString
            let identifier:NSUUID = NSUUID.init(uuidString: uuid as String)!
            array.add(identifier)
        }
        let connectedPeripheral:NSArray = (manager?.retrievePeripherals(withIdentifiers: array as! [UUID]) as NSArray?)!
        return connectedPeripheral
    }
    
    //获取设备的信号值
    func readRssi(peripheral:CBPeripheral) {
        
        peripheral.readRSSI()
        
    }
    
    //向硬件设备写入数据
    func didWriteValue(peripheral:CBPeripheral,data:NSData) {
        
        let character:CBCharacteristic? = characterDict?.object(forKey: "可以写的特征值") as? CBCharacteristic
        if let c:CBCharacteristic = character {
            peripheral.writeValue(data as Data, for: c, type: .withResponse)
        }else{
            
            print("特征值为空，不能写入命令")
        }
        
    }
    
    //----helper Method----
    //通过UUID区分连接的多个设备
    func findPeripheral(uuid:NSString) -> CBPeripheral {
        
        var peripheral:CBPeripheral?
        for p in scanAllPeripheral! {
            let pp:CBPeripheral = p as! CBPeripheral
            if ((pp.identifier.uuidString as NSString).isEqual(to:uuid as String)){
                peripheral = per
            }
        }
        return peripheral!
    }
    
    //----CBCentralManagerDelegate----
    //获取系统蓝牙状态的回调
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        centralType = central.state.rawValue
        switch central.state {
        case .poweredOff:
       print("手机系统蓝牙关闭状态")
            break
        case .unknown:
        print("未知状态")
            break
        case .resetting:
        print("正在重置状态")
            break
        case .unsupported:
        print("设备不支持状态")
            break
        case .unauthorized:
        print("设备未授权状态")
            break
        case .poweredOn:
        print("手机系统蓝牙打开状态，此时为可用状态")
        //如果蓝牙打开，那么开始扫描设备
        manager?.scanForPeripherals(withServices: nil, options: nil)
            break
            
        }
    }
    //扫描设备时调用的方法
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
//        advertisementData：设备的名字以及广播包信息
//        RSSI：设备的信号值
//        peripheral：返回的扫描到的设备
      
        self.scanAllPeripheral?.add(peripheral)
        
//        print("扫描到的设备:\(peripheral)")
        delegate?.onScan(peripheral: peripheral, isStop: 0, rssi: RSSI)
        
    }
    //连接设备成功的回调
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect")
        let uuid:NSString = peripheral.identifier.uuidString as NSString
        connectResult!(uuid,PeripheralConnectReturnType.PeripheralConnectTypeSuccess)
        peripheral.delegate  = self
        peripheral.discoverServices(nil)
    }
    //连接设备失败的回调
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("error:\(String(describing: error))")
       print("didFailToConnect")
        
        if let e:NSString = error as? NSString {
            errorRseult!(peripheral.identifier.uuidString as NSString,e)
        }else{
        connectResult!(peripheral.identifier.uuidString as NSString,PeripheralConnectReturnType.PeripheralConnextTypeFail)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("error:\(String(describing: error))")
        print("didDisconnectPeripheral")
        if let e:NSString = error as? NSString {
            errorRseult!(peripheral.identifier.uuidString as NSString,e)
        }else{
        connectResult!(peripheral.identifier.uuidString as NSString,PeripheralConnectReturnType.PeripheralConnectTypeDisconnect)
        }
    }
    
    //----CBPeripheralDelegate----
    
    //读取设备的信号值的回调
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        
//        需要调用peripheral.readRSSI()此方法时才会回调
        print("RSSI:\(RSSI)")
        if let e:NSString = error as? NSString {
            errorRseult!(peripheral.identifier.uuidString as NSString,e)
        }else{
            rssiResult!(peripheral.identifier.uuidString as NSString,RSSI)
        }
    }
    
    //获取服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("error:\(String(describing: error))")
        print("didDiscoverServices")
        if let e:NSString = error as? NSString {
            errorRseult!(peripheral.identifier.uuidString as NSString,e)
        }
        for  s in peripheral.services! {
            let service:CBService = s
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
    }
    //获取特征值
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("error:\(String(describing: error))")
        print("didDiscoverCharacteristicsFor")
        if let e:NSString = error as? NSString {
            errorRseult!(peripheral.identifier.uuidString as NSString,e)
        }
        for c in service.characteristics! {
            let cc:CBCharacteristic = c
            peripheral.discoverDescriptors(for: cc)
        }
        
        if ((service.uuid.uuidString as NSString).isEqual(to: "你要搜索的服务的UUID")) {
            //遍历当前服务下的所有特征值
            for c in service.characteristics! {
                let cc:CBCharacteristic = c
                if ((cc.uuid.uuidString as NSString).isEqual(to: "你要搜索的特征值的UUID")){
                    //打开通知
                    peripheral.setNotifyValue(true, for: cc)
                    characterDict?.setObject(cc, forKey: "可以写的特征值" as NSCopying)
                }
                
            }
            
        }
        
    }
    
    //获取设备返回的数据的回调
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("error:\(String(describing: error))")
        print("didUpdateValueForcharacteristic")
        if let e:NSString = error as? NSString {
            errorRseult!(peripheral.identifier.uuidString as NSString,e)
        }else{
            let data:NSData = characteristic.value! as NSData
            print("返回的数据:\(data)")
            readResult!(peripheral.identifier.uuidString as NSString,data)
        }
        
        
        
    }
    //写入数据时调用的方法
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("error:\(String(describing: error))")
        
        print("didUpdateValueForcharacteristic")
        if let e:NSString = error as? NSString {
            errorRseult!(peripheral.identifier.uuidString as NSString,e)
        }
    }

    
}
