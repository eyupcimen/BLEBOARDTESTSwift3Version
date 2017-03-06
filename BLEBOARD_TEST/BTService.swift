//
//  BTService.swift
//
//  Created by Kevin Darrah on 5/28/15.
//  Copyright (c) 2015 KDcircuits. All rights reserved.
//

import Foundation
import CoreBluetooth

/* Services & Characteristics UUIDs */

//SERVICE UUIDS
let BLE_SERVICE_UUID = CBUUID(string: "B159ABF7-9B32-42DD-B26B-C62517AF1180")

//Notify UUID
let BLE_NOTIFY_UUID = CBUUID(string: "B159ABF7-9B32-42DD-B26B-C62517AF1181")

//CHARACTERISTIC UUIDS
let BLE_INT_UUID = CBUUID(string: "B159ABF7-9B32-42DD-B26B-C62517AF1182")
let BLE_JSON_UUID = CBUUID(string: "B159ABF7-9B32-42DD-B26B-C62517AF1183")
let BLE_NOTIFY_FUNCTION_UUID = CBUUID(string: "B159ABF7-9B32-42DD-B26B-C62517AF1184")


let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class BTService: NSObject, CBPeripheralDelegate {
var peripheral: CBPeripheral?

    //these are the characteristics
    var BLE_NOTIFY_CBChar: CBCharacteristic?
    var BLE_INT_CBChar: CBCharacteristic?
    var BLE_JSON_CBChar: CBCharacteristic?
    var BLE_NOTIFY_FUNCTION_CBChar: CBCharacteristic?

  
  init(initWithPeripheral peripheral: CBPeripheral) {
    super.init()
    self.peripheral = peripheral
    self.peripheral?.delegate = self
  }
  
  deinit {
    self.reset()
  }
  
    //we'll just discover all services
  func startDiscoveringServices() {
    self.peripheral?.discoverServices(nil)//[BLEServiceUUID]
  }
  
  func reset() {
    print("service reset")
    if peripheral != nil {
      peripheral = nil
    }
    
    // Deallocating therefore send notification
    self.sendBTServiceNotificationWithIsBluetoothConnected(false)
  }
  
    //called when a new service is found
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    print("FOUND SERVICES")
    print(peripheral.services ?? "")
    
    // Checks
    if (peripheral != self.peripheral) {
      // Wrong Peripheral
      return
    }
    
    if (error != nil) {
      return
    }
    
    if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
      // No Services
      return
    }
    
    //loop through the services and pull out all characteristics
    for service in peripheral.services! {
        peripheral.discoverCharacteristics(nil, for: service )
    }
    
  }
  
    
   //called when a new characteristic is found
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    
    print("FOUND CHARACHERISTICS")
    print(service.characteristics)
    
    if (peripheral != self.peripheral) {
      // Wrong Peripheral
      return
    }
    
    if (error != nil) {
        print("error getting characteristics")
      return
    }
    
    //Scan through all of the found characteristics - we already know the expected UUIDs, so assign them while we're discovering them
    for characteristic in service.characteristics! {
        print(characteristic)
        if characteristic.uuid == BLE_NOTIFY_UUID{
            print("FOUND BLE_NOTIFY_UUID")
            self.BLE_NOTIFY_CBChar = (characteristic)
            peripheral.setNotifyValue(true, for: characteristic )
            self.sendBTServiceNotificationWithIsBluetoothConnected(true)
        }
        if characteristic.uuid == BLE_INT_UUID{
            print("FOUND BLE_INT_UUID")
            self.BLE_INT_CBChar = (characteristic)
            peripheral.setNotifyValue(true, for: characteristic )
            self.sendBTServiceNotificationWithIsBluetoothConnected(true)
        }
        if characteristic.uuid == BLE_JSON_UUID{
            print("FOUND BLE_JSON_UUID")
            self.BLE_JSON_CBChar = (characteristic)
            peripheral.setNotifyValue(true, for: characteristic )
            self.sendBTServiceNotificationWithIsBluetoothConnected(true)
        }
        if characteristic.uuid == BLE_NOTIFY_FUNCTION_UUID{
            print("FOUND BLE_NOTIFY_FUNCTION_UUID")
            self.BLE_NOTIFY_FUNCTION_CBChar = (characteristic)
            peripheral.setNotifyValue(true, for: characteristic )
            self.sendBTServiceNotificationWithIsBluetoothConnected(true)
            connectionstatusString = "Connected"
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshScreenRequest"), object: nil)
        }
    }
  }
    
  // this function is used to send data to the BLE module and 'call' a certain function via the characteristic
    func sendData(_ txData: Int, characteristic: CBCharacteristic) {
    print("sending \(txData) to \(characteristic)")
    
        //set up the outgoing packet
    var formated_data = NSInteger(txData)
    let data = Data(bytes: &formated_data , count: 4)
        
    //send it out - note that this must be .withResponse in order to work
        self.peripheral?.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
  }
  
  func sendBTServiceNotificationWithIsBluetoothConnected(_ isBluetoothConnected: Bool) {
    let connectionDetails = ["isConnected": isBluetoothConnected]
    NotificationCenter.default.post(name: Notification.Name(rawValue: BLEServiceChangedStatusNotification), object: self, userInfo: connectionDetails)
  }
    
    
    //this fucntion is called automatically when new data is received by the app
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
            if(characteristic == self.BLE_INT_CBChar){
            print("READ INT UPDATE")
            //print(characteristic.value)//raw data in
            let BYTE_PACKET_IN: Data = characteristic.value!//convert to NSDATA
            var BYTE_DATA_IN = [UInt8](repeating: 0, count: 4)//setup the empty array
            
            (BYTE_PACKET_IN as NSData).getBytes(&BYTE_DATA_IN, length: BYTE_PACKET_IN.count)//copy NSDATA packet into array as bytes
            
            var returnedInteger: Int = 0
            print(BYTE_DATA_IN)
            memcpy(&returnedInteger, BYTE_DATA_IN, 4)//combines array into UInt16
            print(returnedInteger)
            }
        
            if(characteristic == self.BLE_NOTIFY_CBChar){
            //print("NOTIFY UPDATE")
            //print(characteristic.value)//raw data in
            
            //bring the data in, decode the string, then separate the string by commas into an array
            var data_in = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) as! String
            data_in = data_in.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let stringArray = data_in.components(separatedBy: ",")
            print(stringArray)
            

            //then we just pull out our variables out of the string array
            batteryVoltageString = "Battery Voltage = \(Float(Int16(stringArray[2])!) / 1000)V"
            carBatteryVoltageString = "Car Battery Voltage = \(Float(Int16(stringArray[3])!) * 11 / 1000)V"
            temperatureString = "Temperature = \(Float(Int16(stringArray[1])!) * 0.0625 * 9 / 5 + 32)\u{00B0}F"
            //then go update the screen
            NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshScreenRequest"), object: nil)
            }
        

        }
    
    


}

    
  
