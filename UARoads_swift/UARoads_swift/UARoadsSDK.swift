//
//  UARoadsSDK.swift
//  UARoads_swift
//
//  Created by Victor Amelin on 4/7/17.
//  Copyright © 2017 Victor Amelin. All rights reserved.
//

import Foundation
import Alamofire

final class UARoadsSDK {
    private init() {}
    static let sharedInstance = UARoadsSDK()
    
    //============
    private static let baseURL = "http://api.uaroads.com"
    
    func authorizeDevice(email: String, handler: @escaping (_ success: Bool) -> ()) {
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
        
        Alamofire.request("\(UARoadsSDK.baseURL)/register-device", method: .post, parameters: params, encoding: URLEncoding(), headers: nil).responseJSON { response in
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
    
    func send(track: TrackModel, handler: @escaping (_ success: Bool) -> ()) {
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
        
//        Alamofire.request("\(UARoadsSDK.baseURL)/add", method: HTTPMethod.post, parameters: params, encoding: URLEncoding(), headers: nil).responseJSON(queue: nil, options: JSONSerialization.ReadingOptions.allowFragments) { response in
//            switch response.result {
//            case .success(let obj):
//                print("JSON: \(obj)")
//                
//                //                                    let json = JSON(obj)
//                
//                handler(true)
//                
//            case .failure(let error):
//                print("ERROR: \(error.localizedDescription)")
//                handler(false)
//            }
//        }
    }
    
    private func fullTrackData(track: TrackModel) -> Data? {
        var data: Data?
        var pitsDataList = [String]()

//        let pitsArray = track.pits?.sorted(by: { (A, B) -> Bool in
//            print("A: \(A.time)")
//            print("B: \(B.time)")
//            return A.time > B.time
//        })
//        for item in pitsArray! {
//            pitsDataList.append(pitDataString(pit: item))
//        }
        
        let pitsDataString = pitsDataList.joined(separator: "#")
        data = pitsDataString.data(using: String.Encoding.utf8)!
        
        if let data = data {
            return gzippedData(data)
        } else {
            return nil
        }
    }
    
    private func gzippedData(_ data: Data) -> Data {
        return (data as NSData).gzippedData(withCompressionLevel: -1.0)
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








