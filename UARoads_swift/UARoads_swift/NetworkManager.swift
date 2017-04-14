//
//  YandexManager.swift
//  UARoads_swift
//
//  Created by Victor Amelin on 4/7/17.
//  Copyright © 2017 Victor Amelin. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CoreLocation

class NetworkManager {
    private init() {}
    static let sharedInstance = NetworkManager()
    
    func searchResults(location: String, handler: @escaping SearchLocationHandler) {
        let coord = LocationManager.sharedInstance.manager.location?.coordinate ?? CLLocationCoordinate2DMake(0.0, 0.0)
        let params = [
            "lang":"uk_UA",
            "format":"json",
            "ll":"\(coord.latitude), \(coord.longitude)",
            "geocode":"Україна, \(location)"
        ]
        
        Alamofire.request("https://geocode-maps.yandex.ru/1.x/", method: .get, parameters: params, encoding: URLEncoding(), headers: nil).responseJSON(queue: nil, options: JSONSerialization.ReadingOptions.allowFragments) { response in
            switch response.result {
            case .success(let obj):
                
                let json = JSON(obj)
                let featureMember = json["response"].dictionary?["GeoObjectCollection"]?.dictionary?["featureMember"]?.array
                
                var result = [SearchResultModel]()
                if let featureMember = featureMember {
                    for item in featureMember {
                        let geoObject = item["GeoObject"].dictionary
                        let description = geoObject?["description"]?.string
                        let name = geoObject?["name"]?.string
                        let pos = geoObject?["Point"]?.dictionary?["pos"]?.string
                        let coordArr = pos?.components(separatedBy: " ")
                        let locationCoord = CLLocationCoordinate2DMake(CLLocationDegrees(Float(coordArr![1])!),
                                                                       CLLocationDegrees(Float(coordArr![0])!))
                        let model = SearchResultModel(locationCoordianate: locationCoord, locationName: name, locationDescription: description)
                        
                        result.append(model)
                    }
                }
                handler(result)
                
            case .failure(let error):
                print("ERROR: \(error.localizedDescription)")
            }
        }
    }
}






















