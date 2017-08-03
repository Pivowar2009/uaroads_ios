//
//  SendTracksService.swift
//  UARoads_swift
//
//  Created by Roman on 7/27/17.
//  Copyright © 2017 Victor Amelin. All rights reserved.
//

import Foundation
import RealmSwift

class SendTracksService: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    
    static let shared = SendTracksService()
    
    private (set) public var urlSession: URLSession!
    
    private (set) public var tracksToSend: [Dictionary<Int, ThreadSafeReference<UA_Roads.TrackModel>>] = []
    
    private override init() {
        super.init()
        
        let opQueue = OperationQueue.main
        opQueue.maxConcurrentOperationCount = 1
        let configuration = URLSessionConfiguration.background(withIdentifier: "bgSendTrackSessionConfiguration")
        self.urlSession = URLSession(configuration: configuration,
                                     delegate: self,
                                     delegateQueue: opQueue)
    }
    
    // MARK: Public funcs
    
    func sendAllNotPostedTraks() {
        if isSutableNetworkConnection() == false {
            return
        }
        
        guard let tracksResult = allTracksToSend() else { return }
        
        for track in tracksResult {
            pl("trackId = \(track.trackID)")
        }
        
        for track in tracksResult {
            sendTrack(track)
        }
    }
    
    func sendTrack(_ track: TrackModel) {
        let parameters = track.sendTrackParameters()
        
        guard let sendTrackUrl = URL(string: "http://api.uaroads.com/add") else { return }
        var request = URLRequest(url: sendTrackUrl)
        request.httpMethod = "POST"
        let data = NSKeyedArchiver.archivedData(withRootObject: parameters)
        request.httpBody = data
        
        changeTrackStatus(.uploading, for: track)
        
        let task = urlSession.dataTask(with: request)
        
        let trackRef = ThreadSafeReference(to: track)
        let taskDict = [task.taskIdentifier : trackRef]
        
        tracksToSend.append(taskDict)
        
        task.resume()
        
        // TODO: delete commented text when uploading will be finished
//        urlSession.dataTask(with: request) { [weak self] (data, response, error) in
//            if let data = data {
//                let result = String(data: data, encoding: String.Encoding.utf8)
//                pl("RESULT: \(String(describing: result))")
//                pl("response -> \n\(response)")
//                // TODO: set correct uploadStatus
//                let uploadStatus: TrackStatus = result == "OK" ? .uploaded : .uploaded//.waitingForUpload
//                DispatchQueue.main.async {
//                    self?.changeUploadStatus(uploadStatus, for: track)
//                }
//            } else {
//                pl(error)
//            }
//        }.resume()
    }
    
    
    // MARK: Private funcs
    
    private func changeTrackStatus(_ status: TrackStatus, for track: TrackModel) {
        RealmManager().update {
            track.status = status.rawValue
        }
    }
    
    private func isSutableNetworkConnection() -> Bool {
        let sendDataOnlyWiFi = SettingsManager.sharedInstance.sendDataOnlyWiFi
        let currentNetwork = NetworkConnectionManager.shared.networkStatus
        
        if currentNetwork == .notReachable {
            return false
        }
        if sendDataOnlyWiFi && currentNetwork != .reachableViaWiFi {
            return false
        }
        
        return true
    }
    
    private func allTracksToSend() -> Results<TrackModel>? {
        let predicate = NSPredicate(format: "status = %ld OR status = %ld",
                                    TrackStatus.saved.rawValue,
                                    TrackStatus.waitingForUpload.rawValue)
        
        let tracks = RealmManager().objects(type: TrackModel.self)?.filter(predicate)
        
        return tracks
    }
    
    private func handleSendTrack(with dataTask: URLSessionDataTask, trackStatus: TrackStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let index = self?.tracksToSend.index(where: {
                $0.keys.first == dataTask.taskIdentifier
            }) else {
                return
            }
            
            guard let dict = self?.tracksToSend[index] else { return }
            guard let trackRef = dict[dataTask.taskIdentifier] else { return }
            guard let track = RealmManager().realm?.resolve(trackRef) else { return }
            
            self?.changeTrackStatus(trackStatus, for: track)
            
            self?.tracksToSend.remove(at: index)
        }
    }

    
    // MARK: Delegate funcs:
    // MARK: — URLSessionDelegate
    
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        pf()
        pl("urlSession error -> \(String(describing: error?.localizedDescription))")
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        pf()
        let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        let authChallengeDisposition = Foundation.URLSession.AuthChallengeDisposition.useCredential
        completionHandler(authChallengeDisposition, credential)
    }
    
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        pl("background session \(session) finished events.")
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let completionHandler = appDelegate.backgroundSessionCompletionHandler {
            appDelegate.backgroundSessionCompletionHandler = nil
            DispatchQueue.main.async {
                completionHandler()
            }
        }
    }

    
    // MARK: — URLSessionDataDelegate
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        pf()
        pl("response -> \n\(response)")
        pl("dataTask id = \(dataTask.taskIdentifier)")
        
        if let httpResponse = response as? HTTPURLResponse {
            let trackStatus: TrackStatus = httpResponse.statusCode != 200 ? .waitingForUpload : .uploaded
            
            handleSendTrack(with: dataTask, trackStatus: trackStatus)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let result = String(data: data, encoding: String.Encoding.utf8)
        pl("RESULT: \(String(describing: result))")
        
        let trackStatus: TrackStatus = result == "OK" ? .uploaded : .waitingForUpload
        
        handleSendTrack(with: dataTask, trackStatus: trackStatus)
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    willCacheResponse proposedResponse: CachedURLResponse,
                    completionHandler: @escaping (CachedURLResponse?) -> Void) {
        pf()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            pl("task \(task.taskIdentifier) error -> \(error.localizedDescription)")
        } else {
            pl("task \(task.taskIdentifier) completed succesfully")
        }
    }
}



//private func handleOnSendEvent() {
//    AnalyticManager.sharedInstance.reportEvent(category: "System", action: "SendDataActivity Start")
//    
//    var sendingInProcess = false
//    
//    let pred = NSPredicate(format: "(status == 2) OR (status == 3)")
//    let result = self.dbManager.objects(type: TrackModel.self)?.filter(pred)
//    
//    if sendingInProcess == false {
//        if let result = result, result.count > 0 {
//            sendingInProcess = true
//            
//            if let track = result.first {
//                self.dbManager.update {
//                    track.status = TrackStatus.uploading.rawValue
//                }
//                
                //prepare params for sending
//                let data64: String = TracksFileManager.trackStringData(from: track)
//                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
//                let autorecord = track.autoRecord ? 1 : 0
//                let params: [String : AnyObject] = [
//                    "uid": Utilities.deviceUID() as AnyObject,
//                    "comment":track.title as AnyObject,
//                    "routeId":track.trackID as AnyObject,
//                    "data": data64 as AnyObject,
//                    "app_ver":version as AnyObject,
//                    "auto_record" : autorecord as AnyObject,
//                    "date":"\(track.date.timeIntervalSince1970)" as AnyObject
//                ]
//                
//                NetworkManager.sharedInstance.tryToSendData(params: params, handler: { val in
//                    sendingInProcess = false
//                    
//                    if result.count > 1 && val  {
//                        self.onSend?() //recursion
//                    } else {
//                        (UIApplication.shared.delegate as? AppDelegate)?.completeBackgroundTrackSending(val)
//                    }
//                    
//                    self.dbManager.update {
//                        if val == true {
//                            track.status = TrackStatus.uploaded.rawValue
//                        } else {
//                            track.status = TrackStatus.waitingForUpload.rawValue
//                        }
//                    }
//                })
//            }
//        }
//    }
//    if !sendingInProcess {
//        (UIApplication.shared.delegate as? AppDelegate)?.completeBackgroundTrackSending(false)
//    }
//    AnalyticManager.sharedInstance.reportEvent(category: "System", action: "sendDataActivity End")
//}
