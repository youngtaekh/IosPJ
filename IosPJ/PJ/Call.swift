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
        CallManager.getInstance().callModel = CallModel(counterpart: PJManager().getCounterpart(), incoming: true)
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
                manager.callModel = CallModel(counterpart: PJManager().getCounterpart(), outgoing: true)
                PublisherImpl.instance.onOutgoingCallObserver(model: manager.callModel!)
                break
            case 4:
                print("state - CONNECTING")
                break
            case 5:
                print("state - CONFIRMED")
                manager.callModel!.connected = true
                PublisherImpl.instance.onConnectedObserver(model: manager.callModel!)
                break
            case 6:
                print("state - DISCONNECTED")
                manager.callModel!.terminated = true
                PublisherImpl.instance.onTerminatedObserver(model: manager.callModel!)
                manager.stopRegistration()
                break
            default:
                print("state - default")
                break
        }
    }
}
