//
//  BTDiscovery.swift
//
//  Created by Kevin Darrah on 5/28/15.
//  Copyright (c) 2015 KDcircuits. All rights reserved.
//

import Foundation
import CoreBluetooth



let btDiscoverySharedInstance = BTDiscovery();//the instance of the class.  

class BTDiscovery: NSObject, CBCentralManagerDelegate {//The entire Bluetooth Discovery Class

    
  fileprivate var centralManager: CBCentralManager?
  fileprivate var peripheralBLE: CBPeripheral?
  
 
  
    
  override init() {
    super.init()
    let centralQueue = DispatchQueue(label: "com.kdcircuits", attributes: [])
    centralManager = CBCentralManager(delegate: self, queue: centralQueue)
  }//override init
    
  
  func startScanning() {// start scanning for bluetooth devices
    if let central = centralManager {
        print("Scanning Started")
        central.scanForPeripherals(withServices: nil, options: nil)//  make nil to search for all, or specify a service UUID
        print("Looking for Peripherals with Services")
        connectionstatusString = "Looking for device..."
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshScreenRequest"), object: nil)
    }
  }
    
    func stopScanning(){//stop scanning
        print("stopped scanning")
        centralManager!.stopScan()
    }
    
    func disconnect(){//disconnect from peripheral
        centralManager!.cancelPeripheralConnection(self.peripheralBLE!)
    }
  
  var bleService: BTService? {// once connected, this is called to kick off the BTService functions
    didSet {
      if let service = self.bleService {
        print("Starting to Discover Services")
        service.startDiscoveringServices()
       // service.reset()
      }
    }
  }
    
    //This function is called when a new peripheral is discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
     print("found something")
    // Validate peripheral informatio
    if ((peripheral.name == nil) || (peripheral.name == "")) {//this actually happens frequently, so important to have, otherwise app will crash
      return
    }
        
        print(peripheral.name ?? "" )
        if(peripheral.name == "BLEBOARD"){//connect to only peripherals with this name - not good for production, but works for now - need a better pairing process
            print("found BLEBOARD")
            self.peripheralBLE = peripheral
            connect_to_peripheral(peripheralBLE!)
        }

    }

    func connect_to_peripheral(_ peripheral: CBPeripheral){
        print("Trying to Connect")
        centralManager!.connect(peripheral, options: nil)//connect!
        print("going to go connect")
    }
  
    //called when connected
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    // Create new service class - now go get characteristics
    print("started to connect")
      self.bleService = BTService(initWithPeripheral: peripheral)
        print("Connected")
    connectionstatusString = "Connecting..."
    NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshScreenRequest"), object: nil)
    
    
    // Stop scanning for new devices
     central.stopScan()
  }

  //called when disconnected from peripheral
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    print("Disconnected")
    self.bleService = nil;
    self.peripheralBLE = nil;
    
    connectButtonTextString = "Connect"
    connectionstatusString = "Disconnected"
    batteryVoltageString = ""
    carBatteryVoltageString = ""
    temperatureString = ""
    
    
    NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshScreenRequest"), object: nil)
  }
  
    //called when bluetooth is powered off - clear out all found devices
  func clearDevices() {
    print("BLE OFF or RESETTING")
    self.bleService = nil
    self.peripheralBLE = nil
  }
    
 //This is called whenever there is a change with the Bluetooth status
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch (central.state) {
    case .poweredOff:
      self.clearDevices()
      print("Bluetooth OFF")
    case .unauthorized:
      // Indicate to user that the iOS device does not support BLE.
      break
      
    case .unknown:
      // Wait for another event
      break
    case .poweredOn:
        print("Bluetooth ON")
        //self.startScanning()
    case .resetting:
      self.clearDevices()
      break
    case .unsupported:
      break
      
    default:
      break
    
    }
  }
    
    

    
    
    

}

