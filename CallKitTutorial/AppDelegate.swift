//
//  AppDelegate.swift
//  CallKitTutorial
//
//  Created by QuentinArguillere on 10/08/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import UIKit
import SwiftUI
import PushKit
import linphonesw

let userDefaultStr :String = "voipTest"
let backGround :String = "backGround"

var isComeFromVoip:Bool = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    @ObservedObject var tutorialContext = CallKitExampleContext()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        registerForPushNotifications()
        voipRegistration()
        Callmanager.instance()
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var stringifiedToken = deviceToken.map{String(format: "%02X", $0)}.joined()
//        stringifiedToken.append(String(":remote"))
        print("stringifiedToken == \(stringifiedToken.localizedLowercase)")
        Callmanager.instance().mCore.didRegisterForRemotePushWithStringifiedToken(deviceTokenStr: stringifiedToken)
        let userDefault = UserDefaults.standard
         userDefault.setValue(stringifiedToken, forKey: "pushToken")
         userDefault.synchronize()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
//        isComeFromVoip = false
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
      //1
      UNUserNotificationCenter.current()
        //2
        .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
          //3
          print("Permission granted: \(granted)")
        }
    }
    
    // Register for VoIP notifications
    func voipRegistration() {
        
        // Create a push registry object
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        // Set the registry's delegate to self
        voipRegistry.delegate = self
        // Set the push type to VoIP
        voipRegistry.desiredPushTypes = [.voIP]
    }

}

extension AppDelegate:UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        UserDefaults.standard.setValue("willPresent", forKey: "willPresent")
//                    UserDefaults.standard.synchronize()
        
//        completionHandler(.alert)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo as NSDictionary
        UserDefaults.standard.setValue(userInfo, forKey: "NotificationuserInfo")
                    UserDefaults.standard.synchronize()
        
//        UserDefaults.standard.setValue("didReceive", forKey: "didReceive")
//                    UserDefaults.standard.synchronize()
        
        let callid = response.notification.request.content.userInfo["CallId"] as? String
        if callid != nil && callid != "" {
            
            
            let call = Callmanager.instance().findCall(callId: callid) as? Call ?? nil
            
            if call != nil {
                tutorialContext.mCall = call
                tutorialContext.mProviderDelegate.incomingCall()
            }
            
        }
    }
}

extension AppDelegate:PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        var stringifiedToken = pushCredentials.token.map{String(format: "%02X", $0)}.joined()
        print("stringifiedToken == voipToken ==\(stringifiedToken)")
       let userDefault = UserDefaults.standard
        userDefault.setValue(stringifiedToken, forKey: "voipToken")
        userDefault.synchronize()
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        let userDefault = UserDefaults.standard
         userDefault.setValue("didReceiveIncomingPushWithcompletion", forKey: "voipToken")
         userDefault.synchronize()
        print("payload =22= \(payload)")
        localNotification()
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType)  {
        let userDefault = UserDefaults.standard
         userDefault.setValue("didReceiveIncomingPushWith", forKey: "voipToken")
         userDefault.synchronize()
        print("payload =11= \(payload)")
        localNotification()
    }
    
    func localNotification() {
        // Configure the notification's payload.
        
        
//        if (!Callmanager.instance().isLogin) {
        Callmanager.instance()
//            UserDefaults.standard.setValue("pushRegistry", forKey: "pushRegistry")
            UserDefaults.standard.synchronize()
            isComeFromVoip = true
            
            
            let dic = UserDefaults.standard.value(forKey: userDefaultStr) as! NSDictionary
            Callmanager.instance().register(dic: dic)
//        tutorialContext.mProviderDelegate.incomingCall()
        
//        tutorialContext.login()
//        }
       
        
    }
}
