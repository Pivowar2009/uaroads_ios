//
//  UARoadsSDK.swift
//  UARoads_swift
//
//  Created by Victor Amelin on 4/7/17.
//  Copyright © 2017 Victor Amelin. All rights reserved.
//

import Foundation
import CoreLocation

public final class UARoadsSDK {
    private init() {}
    public static let sharedInstance = UARoadsSDK()
    
    //============
    
    func encodePoints(_ points: [PitModel]) -> String? {
        var data: Data?
        var pitsDataList = [String]()
        
        for item in points {
            pitsDataList.append(pitDataString(pit: item))
        }
        
        let pitsDataString = pitsDataList.joined(separator: "#")
        data = pitsDataString.data(using: String.Encoding.utf8)!
        
        if let data = data {
            return gzippedData(data)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
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
}








