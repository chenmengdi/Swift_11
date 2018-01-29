//
//  ViewController.swift
//  Swift_11
//
//  Created by 陈孟迪 on 2017/12/23.
//  Copyright © 2017年 陈孟迪. All rights reserved.
//

import UIKit
import CoreBluetooth
class ViewController: UIViewController,BlueToothCentralDelegate {
    
    
    
    

    var blueCentral = Bluetooth_Central()
    var peripheral:CBPeripheral?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createUI()
        
    }
    func createUI() {
        
        let button:UIButton = UIButton.init(type: .custom)
        button.frame = CGRect.init(x: (self.view.frame.size.width-100)/2, y: 200, width: 100, height: 50)
        button.setTitle("开始扫描", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.addTarget(self, action: #selector(action(sender:)), for: .touchUpInside)
        self.view.addSubview(button)
        
    }
    
    @objc func action(sender:UIButton) {
        
        scan()
    }
    
    //开始扫描，时间为10s
    func scan() {
        blueCentral.delegate = self;
        blueCentral.didScan(timer: 5)
    }
    //停止扫描设备
    func stop() {
        blueCentral.stopScan()
        
    }
    func onScan(peripheral: AnyObject?, isStop: Int, rssi: AnyObject?) {
        
        print("peripheral:\(String(describing: peripheral)),isStop:\(isStop),rssi:\(String(describing: rssi))")
    }
    
    //连接设备，参数为搜索之后的设备
    func connect() {
        blueCentral.didConnect(peripheral: peripheral!)
        onConnect()
        onError()
    }
    
    //断开连接设备，参数为要断开的设备
    func disconnect() {
        blueCentral.didDisConnect(peripheral: peripheral!)
        onConnect()
        
    }
    
    //获取已经连接过的设备，参数为UUID
    func connected() {
        let array:NSArray = Bluetooth_Central().didConnected(uuidArray: ["",""])
        print("array:\(array)")
        
    }
    
    //获取设备的信号值
    func rssi() {
        
        blueCentral.readRssi(peripheral:peripheral!)
        onRssi()
        
    }
    
    //写入数据
    func write() {
        blueCentral.didWriteValue(peripheral: peripheral!, data: NSData())
        onRead()
        
    }
    
//    //搜索设备的回调
//    func onScan () {
//
//        blueCentral.startScanResult = {isStop,rssi in
//
//            print("isStop:\(isStop),rssi:\(rssi)")
//        }
//    }
//    //停止搜索的回调
//    func onStopScan() {
//
//        blueCentral.stopScanResult = {isStop in
//
//            print("isStop:\(isStop)")
//        }
//
//    }
    
    //连接设备的回调
    func onConnect() {
        blueCentral.connectResult = {uuid,type in
            print("uuid:\(uuid)")
            print("type:\(type)")
        }
       onError()
    }
    
    //获取设备返回的数据
    func onRead() {
        blueCentral.readResult = { uuid,data in
            print("uuid:\(uuid)")
            print("data:\(data)")
        }
      onError()
    }
    //错误回调
    func onError() {
        
        blueCentral.errorRseult = { uuid,errorStr in
            
            print("uuid:\(uuid),error:\(errorStr)")
        }
    }
    //信号值回调
    func onRssi() {
        
        blueCentral.rssiResult = {uuid,rssi in
            
            print("uuid:\(uuid),rssi:\(rssi)")
        }
        onError()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

