//
//  Call.swift
//  IosPJ
//
//  Created by young on 2023/05/31.
//

import Foundation
import UIKit

//func topMostController() -> UIViewController {
//    var topController: UIViewController = (UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController!)!
//    while (topController.presentedViewController != nil) {
//        topController = topController.presentedViewController!
//    }
//    return topController
//}
//
//func toIncomingCallVC() {
//    let storyboard = UIStoryboard(name: "Main", bundle: nil)
//    let vc = storyboard.instantiateViewController(withIdentifier: "viewController")
//    let topVC = topMostController()
//    let vcToPresent = vc.storyboard!.instantiateViewController(withIdentifier: "incomingCallVC") as! IncomingViewController
//    vcToPresent.counterpart = PJManager().getCounterpart()
//    topVC.present(vcToPresent, animated: true, completion: nil)
//}

func onIncomingCall() {
    DispatchQueue.main.async () {
        var model = CallManager.getInstance().callModel
        if (model == nil || model!.terminated) {
            model = CallModel(counterpart: PJManager().getCounterpart(), uuid: UUID(), incoming: true)
            CallDelegate.instance.reportIncomingCall(title: model!.counterpart, uuid: model!.uuid)
        } else {
            model!.incoming = true
            model!.counterpart = PJManager().getCounterpart()
            CallDelegate.instance.updateCounterpartName(uuid: model!.uuid, name: model!.counterpart)
        }
        CallManager.getInstance().callModel = model
        PublisherImpl.instance.onIncomingCallObserver(model: CallManager.getInstance().callModel!)
        PJManager().addCallListener(onCallStateListener)
        CallManager.getInstance().ringingCall()
    }
}

func onCallStateListener(code: Int32) {
    print("onCallStateListener code \(code)")
    DispatchQueue.main.async () {
        let manager = CallManager.getInstance()
        switch (code) {
            case 0:
                print("state - NULL")
                break
            case 1:
                print("state - CALLING")
                break
            case 2:
                print("state - INCOMING")
                break
            case 3:
                print("state - EARLY")
                PublisherImpl.instance.onOutgoingCallObserver(model: manager.callModel!)
                break
            case 4:
                print("state - CONNECTING")
                break
            case 5:
                print("state - CONFIRMED")
                manager.callModel!.connected = true
                PublisherImpl.instance.onConnectedObserver(model: manager.callModel!)
                if (manager.callModel!.outgoing) {
                    CallDelegate.instance.reportOutgoingCallConnected(uuid: manager.callModel!.uuid)
                }
                break
            case 6:
                print("state - DISCONNECTED")
                manager.callModel!.terminated = true
                PublisherImpl.instance.onTerminatedObserver(model: manager.callModel!)
                manager.stopRegistration()
                CallDelegate.instance.onTerminated()
                break
            default:
                print("state - default")
                break
        }
    }
}
