//
//  RegistrationObserver.swift
//  IosPJ
//
//  Created by young on 2023/06/09.
//

import Foundation

protocol RegistrationObserver {
    func onRegistrationSuccess(model: RegistrationModel)
    func onRegistrationFailure(model: RegistrationModel)
    func onUnRegistrationSuccess(model: RegistrationModel)
    func onUnRegistrationFailure(model: RegistrationModel)
    func onInstantMessage(model: MessageModel)
    func onIncomingCall(model: CallModel)
}
