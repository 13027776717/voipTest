//
//  CallExample.swift
//  CallTutorial
//
//  Created by QuentinArguillere on 31/07/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import linphonesw
import AVFoundation

#if DEBUG
import FLEX
import SwiftUI
#endif

class CallKitExampleContext : ObservableObject
{
	var mCore: Core!
	@Published var coreVersion: String = Core.getVersion
	
	var mAccount: Account?
	var mCoreDelegate : CoreDelegate!
	@Published var username : String = "6699"
	@Published var passwd : String = "6699"
	@Published var domain : String = "119.28.64.168"
	@Published var loggedIn: Bool = false
	@Published var transportType : String = "TLS"
    @Published var proxy: String = "comms-ext.kelare-demo.com"
    @Published var pushProxy: String = ""
	
	@Published var callMsg : String = ""
	@Published var isCallIncoming : Bool = false
	@Published var isCallRunning : Bool = false
	@Published var remoteAddress : String = "Nobody yet"
	@Published var isSpeakerEnabled : Bool = false
	@Published var isMicrophoneEnabled : Bool = false
    
    @Published var callAddress : String = ""
    
    @Published var identityString = ""
    @Published var serveString = ""
    @Published var encryption = "SRTP"
    @Published var showTip = false
	
	/*------------ Callkit tutorial related variables ---------------*/
	let incomingCallName = "Incoming call"
	var mCall : Call?
	var mProviderDelegate : CallKitProviderDelegate!
	var mCallAlreadyStopped : Bool = false;
	
    
    var isComingFromVoip : Bool = false
    
	init()
	{
		LoggingService.Instance.logLevel = LogLevel.Debug
        let userDefault = UserDefaults.standard.value(forKey: userDefaultStr)
        
        if userDefault != nil {
            let user = userDefault as! Dictionary<String, String>
            username = user["username"]!
            passwd = user["passwd"]!
            domain = user["domain"]!
            transportType = user["transportType"]!
            proxy = user["proxy"]!
            pushProxy = user["pushProxy"]!
            identityString = user["identity"]!
            serveString = user["server"]!
        } else {
            username = "1006"
            passwd = "P@55word1!"
            domain = "sip.justrandoms.com"
            transportType = "TLS"
            proxy = ""
            pushProxy = "proxy.justrandoms.com:5061"
        }
        
        if (identityString == "") {
            identityString = domain
        }
        
        if (serveString == "") {
            serveString = domain
        }
        
        mProviderDelegate = CallKitProviderDelegate(context: self)
        
        let back = UserDefaults.standard.value(forKey: backGround)
        
        if (back != nil && back as! String != "") {
            coreVersion = back as! String
        }
        
        let notificationName = Notification.Name(rawValue: "register")
                NotificationCenter.default.addObserver(self,
                                            selector:#selector(register(notification:)),
                                            name: notificationName, object: nil)
        let notificationCall = Notification.Name(rawValue: "call")
                NotificationCenter.default.addObserver(self,
                                            selector:#selector(call(notification:)),
                                            name: notificationCall, object: nil)
        
        
	}
    
    @objc func register(notification: Notification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let state:RegistrationState = userInfo["state"] as! RegistrationState
        
        if (state == .Ok) {
            self.loggedIn = true
            // Since core has "Push Enabled", the reception and setting of the push notification token is done automatically
            // It should have been set and used when we log in, you can check here or in the liblinphone logs
            
#if targetEnvironment(simulator)
       
#else
//                self.mProviderDelegate.incomingCall()
#endif

        } else {
            self.loggedIn = false
        }
        
    }
    
    @objc func call(notification: Notification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let state:Call.State = userInfo["state"] as! Call.State
        let message :String = userInfo["message"] as! String
        let call:Call = userInfo["call"] as! Call
        
        self.callMsg = message
        if (state == .PushIncomingReceived){
            // We're being called by someone (and app is in background)
            self.mCall = call
            self.isCallIncoming = true
            self.mProviderDelegate.incomingCall()
            
        } else if (state == .IncomingReceived) {
            // If app is in foreground, it's likely that we will receive the SIP invite before the Push notification
            if (!self.isCallIncoming) {
                
                self.mCall = call
                self.isCallIncoming = true
#if targetEnvironment(simulator)
       
#else
                self.mProviderDelegate.incomingCall()
#endif
               

            }
            self.remoteAddress = call.remoteAddress!.asStringUriOnly()
        } else if (state == .Connected) {
            self.isCallIncoming = false
            self.isCallRunning = true
        } else if (state == .Released || state == .End || state == .Error) {
            // Call has been terminated by any side
            
            // Report to CallKit that the call is over, if the terminate action was initiated by other end of the call
            if (self.isCallRunning) {
                self.mProviderDelegate.stopCall()
            }
            self.remoteAddress = "Nobody yet"
        }
    }
    
    
	
	func login() {
        
        isComeFromVoip = false
        Callmanager.instance().isLogin = true
        if (username == "") {
            return
        }
        
        if (passwd == "") {
            return
        }
        
        if (domain == "") {
            return
        }
        
        if (identityString.trim() == "" || serveString.trim() == "") {
            
            showTip = true
            return
        }
        
        let dic = [
            "username":username,
            "passwd":passwd,
            "domain":domain,
            "proxy":proxy,
            "transportType":transportType,
            "pushProxy": pushProxy,
            "identity":identityString,
            "server":serveString
        ];
        
        UserDefaults.standard.setValue(dic, forKey: userDefaultStr)
        UserDefaults.standard.synchronize()
        Callmanager.instance().register(dic: dic as NSDictionary)

	}
	
	func unregister()
	{
        Callmanager.instance().isLogin = false
        Callmanager.instance().unregister()
	}
    
	func delete() {
        Callmanager.instance().delete()
	}
    
    
    func showFlex() {
#if DEBUG
        FLEXManager.shared.showExplorer()
#endif
    }
    
    func deleteUserDefault() {
        UserDefaults.standard.setValue("", forKey: "register")
        UserDefaults.standard.setValue("", forKey: "pushRegistry")
    }
    
    
    func call() {
        
        if callAddress != "" {
            var encrypt :MediaEncryption  = .None
            if (encryption == "SRTP") {
                encrypt = .SRTP
            } else if (encryption == "ZRTP") {
                encrypt = .ZRTP
            } else if (encryption == "DTLS") {
                encrypt = .DTLS
            } else {
                encrypt = .None
            }
            Callmanager.instance().outingCall(address: callAddress,encryption: encrypt)
        }
    }
    
   
    
}

extension String {
    
    func trim() -> String {
        var resultString = self.trimmingCharacters(in: CharacterSet.whitespaces)
        resultString = resultString.trimmingCharacters(in: CharacterSet.newlines)
        return resultString
    }

}
