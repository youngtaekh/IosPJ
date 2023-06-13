//
//  Publisher.swift
//  IosPJ
//
//  Created by young on 2023/06/09.
//

import Foundation

protocol Publisher {
    func add(key: String, observer: RegistrationObserver)
    func removeRegistrationObserver(key: String)
    func add(key: String, observer: CallObserver)
    func removeCallObserver(key: String)
    
    func onRegistrationSuccessObserver(model: RegistrationModel)
    func onRegistrationFailureObserver(model: RegistrationModel)
    func onUnRegistrationSuccessObserver(model: RegistrationModel)
    func onUnRegistrationFailureObserver(model: RegistrationModel)
    func onInstantMessageObserver(model: MessageModel)
    func onIncomingCallObserver(model: CallModel)
    func onOutgoingCallObserver(model: CallModel)
    func onConnectedObserver(model: CallModel)
    func onTerminatedObserver(model: CallModel)
}
