//
//  ViewController.swift
//  WiFi BLE Tool
//  Created by Thomas Bødker on 06/02/2021.
//
import UIKit
import CoreBluetooth



class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, DeviceViewDelegate, UITextFieldDelegate {
    
    let SERVICE_UUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    let CHARACTERISTIC_UUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    
    var rxtx_characteristic: CBCharacteristic? = nil
    
    @IBOutlet weak var tblPeripherals: UITableView!
    @IBOutlet weak var lblDeviceInfo: UILabel!
    
    let reuseIdentifier = "cell"
    
    var peripherals: [String: CBPeripheral] = [:]
    var centralManager: CBCentralManager!
    var myPeripheral: CBPeripheral!
    
    var deviceView: DeviceView!
    
    var gameTimer: Timer?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
       
        lblDeviceInfo.alpha = 0.0
        
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            
            if self.peripherals.count == 0 {
               
                UIView.animate(withDuration: 1.5) {
                    self.lblDeviceInfo.alpha = 1.0
                }
                
            } else {
                
                UIView.animate(withDuration: 0.5) {
                    self.lblDeviceInfo.alpha = 0.0
                }
                
            }
            
        }
        
    }
    
    //----------------------------------------------------------------------------------
    //------    XIB VIEW FUNCTIONS
    //----------------------------------------------------------------------------------
    
    func deviceSetup(SSID: String, Password: String) {
        
        print("SSID: \(SSID) - PASSWORD: \(Password)")
        
        if(SSID == "" || Password == "") {
            
            tblPeripherals.alpha = 1.0;
            tblPeripherals.isUserInteractionEnabled = true
            tblPeripherals.reloadData()
            
        } else {
            
            let data = "***\(SSID);\(Password)".data(using: String.Encoding.utf8)!
            myPeripheral.writeValue(data, for: rxtx_characteristic!, type: CBCharacteristicWriteType.withResponse)
            
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print(error?.localizedDescription ?? "dfgdf")
    }
    
    
    //----------------------------------------------------------------------------------
    //------    BLUETOOTH FUNCTIONS
    //----------------------------------------------------------------------------------
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == CBManagerState.poweredOn {
            print("BLE powered on")
            // Turned on
            central.scanForPeripherals(withServices: [SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        } else {
            print("Something wrong with BLE")
            // Not on, but can have different issues
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let pname = peripheral.name {
            peripherals[pname] = peripheral
            print("Found \(peripherals))")
            tblPeripherals.reloadData()
        } else { return }
        
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        peripheral.discoverServices([SERVICE_UUID])
        
        print("Found \(String(describing: peripheral.name))")
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        peripheral.discoverCharacteristics(nil, for: peripheral.services![0])
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        print("did discover characteristics for \(String(describing: peripheral.name!))")
        
        guard let characteristics = service.characteristics else { return }

        for char in characteristics {
            
            if char.uuid == CHARACTERISTIC_UUID {
                rxtx_characteristic = char
                peripheral.setNotifyValue(true, for: char)
            }
            
        }
        
        tblPeripherals.alpha = 0.1;
        tblPeripherals.isUserInteractionEnabled = false
        
        deviceView = DeviceView(frame: CGRect(x: 10, y: 150, width: view.frame.width-20, height: view.frame.height-400))
        deviceView.layer.borderWidth = 1
        deviceView.layer.cornerRadius = 8
        
        self.view.addSubview(deviceView)
        
        deviceView.delegate = self
       
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        print("Did update state for \(String(describing: myPeripheral.name!))")
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let data :NSData = characteristic.value as NSData? {
            
            let val =  String(describing: String(bytes: data, encoding: .utf8)!)
            
            
            if(val.contains("IP:")) {
                
                print(val)
                
                let alert = UIAlertController(title: "Device connected", message: "Device \(val)", preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
                self.present(alert, animated: true)
             
            }
            
            if(val == "RESET") {
                
                peripherals.removeAll();
                tblPeripherals.alpha = 1.0;
                tblPeripherals.isUserInteractionEnabled = true
                tblPeripherals.reloadData()
                
            }
            
            
            
            
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        central.scanForPeripherals(withServices: [SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        
        if let dv = self.deviceView {
            dv.removeFromSuperview()
        }else{
            print("Unable to remove subview")
        }
        
        deviceView.removeFromSuperview()
        deviceView.delegate = nil
        
        peripherals.removeAll();
        tblPeripherals.alpha = 1.0;
        tblPeripherals.isUserInteractionEnabled = true
        tblPeripherals.reloadData()
        
    }
    
    //----------------------------------------------------------------------------------
    //------    COLLECTION VIEW DELEGATE FUNCTIONS
    //----------------------------------------------------------------------------------
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! MyTableViewCell
                
        cell.myLabel.text = Array(peripherals)[indexPath.row].key
        
        cell.backgroundColor = UIColor.white
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        
        return cell
    }
     
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        myPeripheral = Array(peripherals)[indexPath.row].value
        myPeripheral!.delegate = self
        centralManager.stopScan()
        centralManager.connect(myPeripheral!)
        print("Connect to \(String(describing: myPeripheral.name))")
        
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180.0
    }
}




class MyTableViewCell: UITableViewCell
{
    
    @IBOutlet weak var myLabel: UILabel!
    
}
