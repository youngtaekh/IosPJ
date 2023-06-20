//
//  Register.swift
//  IosPJ
//
//  Created by young on 2023/05/31.
//

import Foundation
import UIKit

func onRegisterListener(isActive: Bool, code: Int32, expiration: Int32) {
    DispatchQueue.main.async () {
        print("onRegisterListener isActive \(isActive)")
        print("onRegisterListener code \(code)")
        print("onRegisterListener expiration \(expiration)")
        let model = RegistrationModel()
        if (code == 200) {
            if (expiration <= 0) {
                PublisherImpl.instance.onUnRegistrationSuccessObserver(model: model)
                CallManager.getInstance().registrationModel!.registered = false
                CallManager.getInstance().stopNetworkNotifier()
            } else {
                PublisherImpl.instance.onRegistrationSuccessObserver(model: model)
                CallManager.getInstance().registrationModel!.registered = true
                CallManager.getInstance().startNetworkNotifier()
            }
        } else {
            if (expiration <= 0) {
                PublisherImpl.instance.onUnRegistrationFailureObserver(model: model)
            } else {
                PublisherImpl.instance.onRegistrationFailureObserver(model: model)
                CallManager.getInstance().registrationModel!.registered = false
                CallManager.getInstance().stopNetworkNotifier()
            }
        }
    }
}

func onMessageReceived() {
    print("onMessageReceived")
    DispatchQueue.main.async () {
        let model = MessageModel()
        model.from = PJManager().getFrom()
        model.message = PJManager().getMessage()
        print("onMessageReceived message - \(String(describing: model.message)) asdf")
        PublisherImpl.instance.onInstantMessageObserver(model: model)
    }
}
