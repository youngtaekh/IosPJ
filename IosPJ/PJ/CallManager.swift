//
//  CallManager.swift
//  IosPJ
//
//  Created by young on 2023/06/12.
//

import Foundation

class CallManager {
    private static var instance: CallManager?
    private init() {}
    
    static func getInstance() -> CallManager {
        if (instance == nil) {
            instance = CallManager()
        }
        return instance!
    }
    
    var registrationModel: RegistrationModel?
    var callModel: CallModel?
    var messageModel: MessageModel?
    
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
        callModel = CallModel(counterpart: counterpart, uuid: UUID(), outgoing: true)
        CallDelegate.instance.start(
            counterpartName: callModel!.counterpart,
            uuid: callModel!.uuid)
        PJManager().makeCall(counterpart)
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
}
