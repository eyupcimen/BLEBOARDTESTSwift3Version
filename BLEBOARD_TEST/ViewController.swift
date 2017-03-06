//
//  ViewController.swift
//  BLEBOARD_TEST
//
//  Created by Kevin Darrah on 12/18/15.
//  Copyright © 2015 KDcircuits. All rights reserved.
//
// This is our main code for the remote starter app

import UIKit

//GLOBAL VARIABLES HERE
var connectionstatusString: String = "Disconnected" // this string used for the connection status label
var batteryVoltageString: String = ""//usd for the battery voltage label
var carBatteryVoltageString: String = ""//used for the car battery voltage label
var temperatureString: String = ""//used for the temperature measuerement label
var connectButtonTextString: String = "Connect"//this is used to change the text on the connect button
var startCarCounter = 0//same idea as the remote start counter down on the module, used in the app to make the button 'selected' when the remote start button is pressed, then wait for an update from the module before de-selecting


class ViewController: UIViewController {
    @IBOutlet var ToggleButtonLabel: UIButton!//outlet for changing parameters of the remote start button

    @IBAction func ToggleButtonAction(_ sender: AnyObject) {//called when the remote start button is pressed
        
        if let bleService = btDiscoverySharedInstance.bleService {//make sure we're connected up before sending anything
            bleService.sendData(123456789, characteristic: bleService.BLE_INT_CBChar!)//send over the 'pass code' for remote starting
            bleService.peripheral?.readValue(for: bleService.BLE_INT_CBChar!)//go read the returned integer, not needed for anything, but it's nice to do this anyway
            startCarCounter = 2//set the counter to 2, then on every second decrement this.  When set to 0, the button will de-select
            ToggleButtonLabel.isSelected = true//make the button appear selected - let's us know something is happening
        }
    }
    @IBOutlet var connectButtonLabel: UIButton!//outlet for the connect button, we'll change the title text
    
    @IBAction func connectButtonAction(_ sender: AnyObject) {//called when the connect button is pressed
        if connectionstatusString == "Disconnected"{//if we're disconnected, then start scanning (will auto connect)
            btDiscoverySharedInstance.startScanning()//start bluetooth scan
            connectButtonLabel.isHidden = true;//this is just to hide the connect button while it's looking for the module
        }else{//else meaning that we're connected, so run this to disconenct
             btDiscoverySharedInstance.stopScanning()//stop scanning or,
             btDiscoverySharedInstance.disconnect()//disconnect
        }
    }
    
    //OUTLETS FOR THE LABELS:
    @IBOutlet var connectionStatusLabel: UILabel!
    @IBOutlet var batteryVoltage: UILabel!
    @IBOutlet var carBatteryVoltage: UILabel!
    @IBOutlet var temperatureLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btDiscoverySharedInstance//kicks off the bluetooth instance
        
        
        
        // Do any additional setup after loading the view, typically from a nib.
        
        //setup our notifications here
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.refreshScreenFunction(_:)), name:NSNotification.Name(rawValue: "refreshScreenRequest"), object: nil)//this one to refresh the entire screen
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appInBackground(_:)), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)//this one for when teh app is ever in teh background or the device is locked.  Don't need to be connected wasting battery...
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func refreshScreenFunction(_ notification: Notification){//called from other classes as a notification - to refresh screen
        //this gets the reload on the main thread
        DispatchQueue.main.async(execute: { () -> Void in
            if(connectionstatusString == "Connected"){//if connected, change button title and show the remote start button
                connectButtonTextString = "Disconnect"
                self.ToggleButtonLabel.isHidden = false
                self.connectButtonLabel.isHidden = false;
            }
            else{//otherwise hide the remote start button
            self.ToggleButtonLabel.isHidden = true
            }
            //  update all of the labels and button titles
            self.connectionStatusLabel.text = connectionstatusString
            self.batteryVoltage.text = batteryVoltageString
            self.carBatteryVoltage.text = carBatteryVoltageString
            self.temperatureLabel.text = temperatureString
            self.connectButtonLabel.setTitle(connectButtonTextString, for: UIControlState())
            self.ToggleButtonLabel.isSelected = false
        })
    }
    //this is handy so that we disconnect when the app is pushed to the background or when the device is locked
    func appInBackground(_ notification : Notification) {
        print("app is in background")
        if connectionstatusString != "Disconnected"{
        btDiscoverySharedInstance.stopScanning()
        btDiscoverySharedInstance.disconnect()
        }
    }
    
    
}

