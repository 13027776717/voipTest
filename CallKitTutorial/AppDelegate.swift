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


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    @ObservedObject var tutorialContext = CallKitExampleContext()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        registerForPushNotifications()
        voipRegistration()
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
        tutorialContext.mCore.didRegisterForRemotePushWithStringifiedToken(deviceTokenStr: stringifiedToken)
        let userDefault = UserDefaults.standard
         userDefault.setValue(stringifiedToken, forKey: "pushToken")
         userDefault.synchronize()
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
        
        completionHandler(.alert)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
    }
}

extension AppDelegate:PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        var stringifiedToken = pushCredentials.token.map{String(format: "%02X", $0)}.joined()
        print("stringifiedToken == \(stringifiedToken)")
       let userDefault = UserDefaults.standard
        userDefault.setValue(stringifiedToken, forKey: "voipToken")
        userDefault.synchronize()
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        print("payload == \(payload)")
        localNotification()
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType)  {
        print("payload == \(payload)")
        localNotification()
    }
    
    func localNotification() {
        // Configure the notification's payload.
        tutorialContext.mProviderDelegate.incomingCall()
        if (tutorialContext.loggedIn) {
            
        } else {
            tutorialContext.isComingFromVoip = true
            tutorialContext.login()
        }
        
    }
}
