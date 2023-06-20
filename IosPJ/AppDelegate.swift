//
//  AppDelegate.swift
//  IosPJ
//
//  Created by young on 2023/05/30.
//

import UIKit
import PushKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let registry = PKPushRegistry(queue: nil)
        registry.delegate = self
        registry.desiredPushTypes = [PKPushType.voIP]
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let deviceID = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        print("AppDelegate didUpdate token - \(deviceID)")
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        let dic = payload.dictionaryPayload
        print("AppDelegate didReceiveIncomingPushWith payload type - \(payload.type)")
        print("AppDelegate didReceiveIncomingPushWith payload - \(dic)")
        let c = dic["caller_ac_nick"]
        print("AppDelegate didReceiveIncomingPushWith c \(c!)")
        
        let model = CallModel(counterpart: c as! String, uuid: UUID())
        model.pushReceived = true
        CallManager.getInstance().callModel = model
        CallDelegate.instance.reportIncomingCall(title: model.counterpart, uuid: model.uuid)
        CallManager.getInstance().startRegistration(address: "\(Config.ADDRESS):\(Config.PORT)", id: Config.ID, pwd: Config.PASSWORD, type: Config.TRANSPORT)
    }
}
