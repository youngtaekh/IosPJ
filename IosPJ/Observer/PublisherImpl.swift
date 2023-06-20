//
//  PublisherImpl.swift
//  IosPJ
//
//  Created by young on 2023/06/09.
//

import Foundation

class PublisherImpl: Publisher {
    private let TAG = "PublisherImpl"
    
    static let instance = PublisherImpl()
    private init() {}
    
    private var registrationObservers = [String:RegistrationObserver]()
    private var callObservers = [String:CallObserver]()
    
    func add(key: String, observer: RegistrationObserver) {
        print("\(TAG) add(RegistrationObserver)")
        registrationObservers[key] = observer
    }
    
    func removeRegistrationObserver(key: String) {
        print("\(TAG) removeRegistrationObserver()")
        registrationObservers.removeValue(forKey: key)
    }
    
    func add(key: String, observer: CallObserver) {
        print("\(TAG) add(CallObserver)")
        callObservers[key] = observer
    }
    
    func removeCallObserver(key: String) {
        print("\(TAG) removeCallObserver()")
        callObservers.removeValue(forKey: key)
    }
    
    func onRegistrationSuccessObserver(model: RegistrationModel) {
        print("\(TAG) onRegistrationSuccessObserver(RegistrationModel)")
        for observer in registrationObservers.values {
            observer.onRegistrationSuccess(model: model)
        }
    }
    
    func onRegistrationFailureObserver(model: RegistrationModel) {
        print("\(TAG) onRegistrationFailureObserver(RegistrationModel)")
        for observer in registrationObservers.values {
            observer.onRegistrationFailure(model: model)
        }
    }
    
    func onUnRegistrationSuccessObserver(model: RegistrationModel) {
        print("\(TAG) onUnRegistrationSuccessObserver(RegistrationModel)")
        for observer in registrationObservers.values {
            observer.onUnRegistrationSuccess(model: model)
        }
    }
    
    func onUnRegistrationFailureObserver(model: RegistrationModel) {
        print("\(TAG) onUnRegistrationFailureObserver(RegistrationModel)")
        for observer in registrationObservers.values {
            observer.onUnRegistrationFailure(model: model)
        }
    }
    
    func onInstantMessageObserver(model: MessageModel) {
        print("\(TAG) onInstantMessageObserver")
        for observer in registrationObservers.values {
            observer.onInstantMessage(model: model)
        }
    }
    
    func onIncomingCallObserver(model: CallModel) {
        print("\(TAG) onIncomingCallObserver(CallModel)")
        for observer in registrationObservers.values {
            observer.onIncomingCall(model: model)
        }
    }
    
    func onOutgoingCallObserver(model: CallModel) {
        print("\(TAG) onOutgoingCallObserver(CallModel)")
        for observer in callObservers.values {
            observer.onOutgoingCall(model: model)
        }
    }
    
    func onConnectedObserver(model: CallModel) {
        print("\(TAG) onConnectedObserver(CallModel)")
        for observer in callObservers.values {
            observer.onConnected(model: model)
        }
    }
    
    func onTerminatedObserver(model: CallModel) {
        print("\(TAG) onTerminatedObserver(CallModel)")
        for observer in callObservers.values {
            observer.onTerminated(model: model)
        }
    }
}
