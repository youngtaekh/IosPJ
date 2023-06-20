//
//  CallDelegate.swift
//  IosPJ
//
//  Created by young on 2023/06/14.
//

import Foundation
import CallKit
import AVFAudio
import UIKit

class CallDelegate: NSObject, CXProviderDelegate {
    private let TAG = "CallDelegate"
    static let instance = CallDelegate()
    var provider: CXProvider?
    
    private override init() {
        super.init()
        let localizedName = NSLocalizedString("AppName", comment: "Name of application")
        print("\(TAG) init localizedName - \(localizedName)")
        let config = CXProviderConfiguration.init()
        config.includesCallsInRecents = false
        config.supportsVideo = false
        config.maximumCallGroups = 1
        config.maximumCallsPerCallGroup = 5
        config.iconTemplateImageData = UIImage.init(named: "CallKit")?.pngData()
        provider = CXProvider.init(configuration: config)
        provider!.setDelegate(self, queue: nil)
    }
    
    func reportIncomingCall(title: String, uuid: UUID) {
        print("\(TAG) \(#function) \(title) \(uuid.uuidString)")
        let update = CXCallUpdate.init()
        update.localizedCallerName = title
        update.supportsDTMF = false
        update.hasVideo = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsHolding = false
        provider!.reportNewIncomingCall(with: uuid, update: update) { (error: Error?) -> Void in
            if (error == nil) {
                print("\(self.TAG) \(#function) incoming transaction request successful")
            } else {
                print("\(self.TAG) \(#function) incoming transaction error")
            }
        }
    }
    
    func updateCounterpartName(uuid: UUID, name: String) {
        NSLog("%@ uuid %@ name %@", #function, uuid.uuidString, name)
        let update = CXCallUpdate.init()
        update.localizedCallerName = name
        update.supportsDTMF = false
        update.hasVideo = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsHolding = false
        provider?.reportCall(with: uuid, updated: update)
    }
    
    func start(counterpartName: String, uuid: UUID) {
        NSLog("%@ uuid %@", #function, uuid.uuidString)
        
        let handle = CXHandle.init(type: CXHandle.HandleType.generic, value: counterpartName)
        let controller = CXCallController.init()
        let startAction = CXStartCallAction.init(call: uuid, handle: handle)
        
        startAction.isVideo = false
        
        controller.requestTransaction(with: startAction) { (error: Error?) -> Void in
            if (error == nil) {
                NSLog("\(#function) request transaction successful")
            } else {
                NSLog("%@ request transaction failed: %@", #function, error!.localizedDescription)
            }
        }
    }
    
    func reportOutgoingCallConnected(uuid: UUID) {
        provider?.reportOutgoingCall(with: uuid, connectedAt: Date.now)
    }
    
    func answer() {
        let model = CallManager.getInstance().callModel!
        answer(callId: 0, uuid: model.uuid)
    }
    
    func answer(callId: Int, uuid: UUID) {
        NSLog("answer(callId: %d, uuid %@", callId, uuid.uuidString)
        
        let controller = CXCallController.init()
        let answerAction = CXAnswerCallAction.init(call: uuid)
        
        controller.requestTransaction(with: answerAction) { (error: Error?) -> Void in
            if (error == nil) {
                NSLog("%@ transaction request successful", #function)
            } else {
                NSLog("%@ transaction request failed: %@", #function, error!.localizedDescription)
            }
        }
    }
    
    func cancel() {
        let model = CallManager.getInstance().callModel!
        provider?.reportCall(with: model.uuid, endedAt: Date.now, reason: CXCallEndedReason.unanswered)
        CallManager.getInstance().cancelCall()
    }
    
    func decline() {
        let model = CallManager.getInstance().callModel!
        provider?.reportCall(with: model.uuid, endedAt: Date.now, reason: CXCallEndedReason.declinedElsewhere)
        CallManager.getInstance().declineCall()
    }
    
    func bye() {
        let model = CallManager.getInstance().callModel!
        provider?.reportCall(with: model.uuid, endedAt: Date.now, reason: CXCallEndedReason.answeredElsewhere)
        CallManager.getInstance().byeCall()
    }
    
    func busy() {
        let model = CallManager.getInstance().callModel!
        provider?.reportCall(with: model.uuid, endedAt: Date.now, reason: CXCallEndedReason.declinedElsewhere)
        CallManager.getInstance().busyCall()
    }
    
    func onTerminated() {
        let model = CallManager.getInstance().callModel!
        provider?.reportCall(with: model.uuid, endedAt: Date.now, reason: CXCallEndedReason.remoteEnded)
    }
    
//    func end() {
//        let model = CallManager.getInstance().callModel!
//        end(callId: 0, uuid: model.uuid)
//    }
    
//    func end(callId: Int, uuid: UUID?) {
//        NSLog("end(callId: %ld, uuid: %@)", callId, uuid!.uuidString)
//
//        if (uuid == nil) {
//            return
//        }
//        let controller = CXCallController.init()
//        let endAction = CXEndCallAction.init(call: uuid!)
//
//        controller.requestTransaction(with: endAction) { (error: Error?) -> Void in
//            if (error == nil) {
//                NSLog("%@ transaction request successful", #function)
//            } else {
//                NSLog("%@ transaction request failed: %@", #function, error!.localizedDescription)
//            }
//        }
//    }
    
    func providerDidBegin(_ provider: CXProvider) {
        print("\(TAG) \(#function)")
    }
    
    func providerDidReset(_ provider: CXProvider) {
        print("\(TAG) \(#function)")
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("\(TAG) \(#function) CXStartCallAction")
        CallManager.getInstance().configureAudioSession()
        PJManager().deactivateAudioSession()
        action.fulfill()
        PJManager().makeCall(CallManager.getInstance().callModel!.counterpart)
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("\(TAG) \(#function) CXAnswerCallAction")
        CallManager.getInstance().configureAudioSession()
        PJManager().deactivateAudioSession()
        action.fulfill()
        CallManager.getInstance().answerCall()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("\(TAG) \(#function) CXEndCallAction")
        action.fulfill()
        
        let manager = CallManager.getInstance()
        let model = manager.callModel!
        if (model.connected) {
            manager.byeCall()
        } else if (model.outgoing) {
            manager.cancelCall()
        } else {
            manager.declineCall()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("\(TAG) \(#function) CXSetMutedCallAction")
        action.fulfill()
        //TODO: mute
//        let manager = CallManager.instance
//        let info = manager.get()
//        let handler = EventHandler.alloc(with: nil)
//        if (info != nil) {
//            if (info!.mute) {
//                manager.muteSwitch(mute: false)
//                handler?.onMute(false)
//            } else {
//                manager.muteSwitch(mute: true)
//                handler?.onMute(true)
//            }
//        }
    }
    
    func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {
        print("\(TAG) \(#function) CXTransaction")
        return false
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("\(TAG) \(#function) timedOutPerforming")
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("\(TAG) \(#function) didActivate")
        PJManager().activateAudioSession()
//        CallManager.getInstance().addObserver()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("\(TAG) \(#function) didDeactivate")
//        CallManager.getInstance().removeObserver()
    }
}
