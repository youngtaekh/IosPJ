//
//  Register.swift
//  IosPJ
//
//  Created by young on 2023/05/31.
//

import Foundation
import UIKit

func onRegisterListener(isActive: Bool, code: Int32) {
    DispatchQueue.main.async () {
        print("onRegisterListener isActive \(isActive)")
        print("onRegisterListener code \(code)")
        let model = RegistrationModel()
        if (code == 200) {
            if (isActive) {
                PublisherImpl.instance.onRegistrationSuccessObserver(model: model)
            } else {
                PublisherImpl.instance.onUnRegistrationSuccessObserver(model: model)
            }
        } else {
            PublisherImpl.instance.onRegistrationFailureObserver(model: model)
        }
    }
}

func onMessageReceived() {
    print("onMessageReceived")
    DispatchQueue.main.async () {
        let model = MessageModel()
        model.from = PJManager().getFrom()
        model.message = PJManager().getMessage()
        PublisherImpl.instance.onInstantMessageObserver(model: model)
    }
}
