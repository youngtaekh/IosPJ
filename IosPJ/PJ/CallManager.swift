//
//  CallManager.swift
//  IosPJ
//
//  Created by young on 2023/06/12.
//

import Foundation
import AVFAudio

class CallManager {
    private let TAG = "CallManager"
    private static var instance: CallManager?
    
    private var reach: Reachability?
    var currentNetwork = Config.INIT
    
    var audioChangeReason = -1
    
    private init() {
        reach = try? Reachability.init(hostname: Config.ADDRESS)
        reach?.whenReachable = { reach -> Void in
            if (reach.isReachableViaWiFi) {
                if (self.currentNetwork != Config.INIT && self.currentNetwork != Config.WIFI) {
                    print("Network \(self.currentNetwork) -> wifi")
                    CallManager.getInstance().networkChanged()
                }
                self.currentNetwork = Config.WIFI
            } else if (reach.isReachableViaWWAN) {
                if (self.currentNetwork != Config.INIT && self.currentNetwork != Config.MOBILE) {
                    print("Network \(self.currentNetwork) -> mobile")
                    CallManager.getInstance().networkChanged()
                }
                self.currentNetwork = Config.MOBILE
            } else {
                if (self.currentNetwork != Config.INIT && self.currentNetwork != Config.NONE) {
                    print("Network \(self.currentNetwork) -> Unavailable")
                    CallManager.getInstance().networkChanged()
                }
                self.currentNetwork = Config.NONE
            }
        }
        
        reach?.whenUnreachable = { reach -> Void in
            print("Network Unreachable")
            self.currentNetwork = Config.NONE
        }
    }
    
    static func getInstance() -> CallManager {
        if (instance == nil) {
            instance = CallManager()
        }
        return instance!
    }
    
    var registrationModel: RegistrationModel?
    var callModel: CallModel?
    var messageModel: MessageModel?
    
    func startNetworkNotifier() {
        do {
            try reach?.startNotifier()
        } catch {
            print("\(TAG) startNetworkNotifier Error")
        }
    }
    
    func stopNetworkNotifier() {
        reach?.stopNotifier()
    }
    
    func startRegistration(address: String, id: String, pwd: String, type: String) {
        registrationModel = RegistrationModel(userId: id)
        PJManager().startRegistration(
                              address,
                      userId: id,
                    password: pwd,
               transportType: type,
            registerListener: onRegisterListener,
             messageListener: onMessageReceived,
            incomingListener: onIncomingCall
        )
    }
    
    func stopRegistration() {
        PJManager().stopRegistration();
    }
    
    func networkChanged() {
        if (registrationModel == nil || !registrationModel!.registered) {
            return
        }
        PJManager().onNetworkChanged()
        if (callModel == nil) {
            print("callModel is nil")
        } else {
            print("callModel ain't nil")
            print("Counterpart \(callModel!.counterpart)")
            print("Outgoing \(callModel!.outgoing)")
            print("Incoming \(callModel!.incoming)")
            print("Connected \(callModel!.connected)")
            print("Terminated \(callModel!.terminated)")
            if (callModel!.incoming && !callModel!.outgoing && !callModel!.connected && !callModel!.terminated) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Put your code which should be executed with a delay here
                    self.ringingCall()
                }
            }
        }
    }
    
    func startCall(counterpart: String) {
        if (callModel == nil || callModel!.terminated) {
            callModel = CallModel(counterpart: counterpart, uuid: UUID(), outgoing: true)
            CallDelegate.instance.start(
                counterpartName: callModel!.counterpart,
                uuid: callModel!.uuid)
        }
    }
    
    func updateCall() {
        PJManager().updateCall()
    }
    
    func cancelCall() {
        PJManager().endCall()
    }
    
    func ringingCall() {
        PJManager().ringingCall()
    }
    
    func answerCall() {
        PJManager().answerCall()
    }
    
    func busyCall() {
        PJManager().busyCall()
    }
    
    func declineCall() {
        PJManager().declineCall()
    }
    
    func byeCall() {
        PJManager().endCall()
    }
    
    func sendMessage(to: String, msg: String) {
        PJManager().sendInstanceMessage(to, msg: msg)
    }
    
    func addCallListener() {
        PJManager().addCallListener(onCallStateListener)
    }
    
    func configureAudioSession(){
        let sessionInterface = AVAudioSession.sharedInstance()
        
        do{
            if(sessionInterface.responds(to: #selector(AVAudioSession.setCategory(_:options:)))){
                try sessionInterface.setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.allowBluetooth)
            }
            else{
                try sessionInterface.setCategory(AVAudioSession.Category.playAndRecord)
            }
            try sessionInterface.setMode(.voiceChat)
            
        }
        catch let error{
            NSLog("SipManager - configureAudioSession error: \(error)")
        }
    }
    
    func useSpeaker() {
        let session = AVAudioSession.sharedInstance()
        try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
    }
    
    func useEarpiece() {
        let session = AVAudioSession.sharedInstance()
        try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
    }
    
    func addObserver() {
        print("\(TAG) \(#function)")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteChangeListenerCallback(notification:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(notification:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance())
    }
    
    func removeObserver() {
        print("\(TAG) \(#function)")
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        audioChangeReason = -1
    }
    
    @objc func audioRouteChangeListenerCallback(notification: NSNotification) {
        NSLog("\(TAG) \(#function)")
        let interruptionDict = notification.userInfo
        let routeChangeReason = interruptionDict?[AVAudioSessionRouteChangeReasonKey]
        
        if (audioChangeReason != routeChangeReason! as! Int) {
            audioChangeReason = routeChangeReason! as! Int
            NSLog("\(TAG) routeChangeReason \(audioChangeReason)")
            
            if (audioChangeReason == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue) {
                NSLog("\(TAG) \(#function) AVAudioSession.RouteChangeReason.newDeviceAvailable")
            } else if (audioChangeReason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue ||
                       audioChangeReason == AVAudioSession.RouteChangeReason.override.rawValue) {
                NSLog("\(TAG) \(#function) AVAudioSession.RouteChangeReason.oldDeviceUnavailable")
            } else if (audioChangeReason == AVAudioSession.RouteChangeReason.categoryChange.rawValue) {
                NSLog("\(TAG) \(#function) AVAudioSession.RouteChangeReason.categoryChange")
            }
        }
    }
    
    @objc func handleInterruption(notification: Notification) {
        print("\(TAG) \(#function)")
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        
        // Switch over the interruption type.
        switch type {
                
                
            case .began:
                // An interruption began. Update the UI as necessary.
                
                break
            case .ended:
                // An interruption ended. Resume playback, if appropriate.
                
                guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // An interruption ended. Resume playback.
                } else {
                    // An interruption ended. Don't resume playback.
                }
                break
                
            default: ()
        }
    }
}
