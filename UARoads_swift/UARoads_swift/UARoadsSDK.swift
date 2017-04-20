//
//  UARoadsSDK.swift
//  UARoads_swift
//
//  Created by Victor Amelin on 4/7/17.
//  Copyright © 2017 Victor Amelin. All rights reserved.
//

import Foundation
import Alamofire
//import StfalconSwiftExtensions
import UHBConnectivityManager

public final class UARoadsSDK {
    private init() {}
    public static let sharedInstance = UARoadsSDK()
    
    //============
    private static let baseURL = "http://uaroads.com"
    private var sendingInProcess = false
    
    public func authorizeDevice(email: String, handler: @escaping (_ success: Bool) -> ()) {
        let deviceName = "\(UIDevice.current.model) - \(UIDevice.current.name)"
        let osVersion = UIDevice.current.systemVersion
        let uid = UIDevice.current.identifierForVendor?.uuidString
        let params = [
            "os":"ios",
            "device_name":deviceName,
            "os_version":osVersion,
            "email":email,
            "uid":uid!
        ]
        
        print("\(UARoadsSDK.baseURL)/register-device")
        print(params)
        
        Alamofire.request("\(UARoadsSDK.baseURL)/register-device", method: .post, parameters: params, encoding: JSONEncoding(), headers: nil).responseJSON { response in
            if let data = response.data {
                let result = String(data: data, encoding: String.Encoding.utf8)
                if result == "OK" {
                    handler(true)
                } else {
                    handler(false)
                }
            } else {
                handler(false)
            }
        }
    }
    
    public func sendDataActivity() {
        let pred = NSPredicate(format: "(status == 2) OR (status == 3)")
        let result = RealmManager.sharedInstance.objects(type: TrackModel.self)?.filter(pred)
        
        if !sendingInProcess {
            if let result = result, result.count > 0 {
                if UHBConnectivityManager.shared().isConnected() == true {
                    sendingInProcess = true
                    
                    let track = result.first
                    RealmManager.sharedInstance.update {
                        track?.status = TrackStatus.uploading.rawValue
                    }
                    UARoadsSDK.sharedInstance.tryToSend(track: track!, handler: { [weak self] val in
                        self?.sendingInProcess = false
                        
                        if result.count > 1 && val {
                            self?.sendDataActivity()
                        } else {
                            (UIApplication.shared.delegate as? AppDelegate)?.completeBackgroundTrackSending(val)
                        }
                        
                        RealmManager.sharedInstance.update {
                            if val == true {
                                track?.status = TrackStatus.uploaded.rawValue
                            } else {
                                track?.status = TrackStatus.waitingForUpload.rawValue
                            }
                        }
                    })
                }
            }
        }
        if !sendingInProcess {
            (UIApplication.shared.delegate as? AppDelegate)?.completeBackgroundTrackSending(false)
        }
    }
    
    private func tryToSend(track: TrackModel, handler: @escaping (_ success: Bool) -> ()) {
        let data = fullTrackData(track: track)
        let base64DataString = data?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let params = [
            "uid":self.getUUID(),
            "comment":track.title,
            "routeId":track.trackID,
            "data":base64DataString ?? "",
            "app_ver":version as! String,
            "auto_record":track.autoRecord ? "1" : "0",
            "date":track.date.timeIntervalSince1970
        ] as [String : Any]
        
        print("\(UARoadsSDK.baseURL)/add")
        print(params)
        
        Alamofire.request("\(UARoadsSDK.baseURL)/add", method: .post, parameters: params, encoding: JSONEncoding(), headers: nil).responseJSON { response in
            if let data = response.data {
                let result = String(data: data, encoding: String.Encoding.utf8)
                if result == "OK" {
                    handler(true)
                } else {
                    handler(false)
                }
            } else {
                handler(false)
            }
        }
    }
    
    private func fullTrackData(track: TrackModel) -> Data? {
        var data: Data?
        var pitsDataList = [String]()

        let pitsArray = track.pits.sorted(byKeyPath: "time", ascending: true)
        print(pitsArray as Any)
        for item in pitsArray {
            pitsDataList.append(pitDataString(pit: item))
        }
        
        let pitsDataString = pitsDataList.joined(separator: "#")
        data = pitsDataString.data(using: String.Encoding.utf8)!
        
        if let data = data {
            return gzippedData(data)
        } else {
            return nil
        }
    }
    
    private func gzippedData(_ data: Data) -> Data? {
        return (data as NSData).gzippedData(withCompressionLevel: -1.0) ?? nil
    }
    
    private func pitDataString(pit: PitModel) -> String {
        let pitValueStr = pit.value == 0.0 ? "0" : "\(pit.value)"
        let result = "\(pit.time);\(pitValueStr);\(pit.latitude);\(pit.longitude);\(pit.tag)"
        return result;
    }
    
    private func getUUID() -> String {
        let uuid = NSUUID().uuidString
        return uuid
    }
}








