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
	
	@Published var callMsg : String = ""
	@Published var isCallIncoming : Bool = false
	@Published var isCallRunning : Bool = false
	@Published var remoteAddress : String = "Nobody yet"
	@Published var isSpeakerEnabled : Bool = false
	@Published var isMicrophoneEnabled : Bool = false
	
	/*------------ Callkit tutorial related variables ---------------*/
	let incomingCallName = "Incoming call"
	var mCall : Call?
	var mProviderDelegate : CallKitProviderDelegate!
	var mCallAlreadyStopped : Bool = false;
	
    let userDefaultStr :String = "voipTest"
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
        } else {
            username = "1111"
            passwd = "P@55word1!"
            domain = "comms.kelare-demo.com"
            transportType = "TLS"
            proxy = "comms-ext.kelare-demo.com"
        }

		let factory = Factory.Instance
		// IMPORTANT : In this tutorial, we require the use of a core configuration file.
		// This way, once the registration is done, and until it is cleared, it will return to the LoggedIn state on launch.
		// This allows us to have a functional call when the app was closed and is started by a VOIP push notification (incoming call
		// We also need to enable "Push Notitifications" and "Background Mode - Voice Over IP"
		let configDir = factory.getConfigDir(context: nil)
		try? mCore = factory.createCore(configPath: "\(configDir)/MyConfig", factoryConfigPath: "", systemContext: nil)
		mProviderDelegate = CallKitProviderDelegate(context: self)
		// enabling push notifications management in the core
		mCore.callkitEnabled = true
		mCore.pushNotificationEnabled = true
		try? mCore.start()
		
		mCoreDelegate = CoreDelegateStub( onCallStateChanged: { (core: Core, call: Call, state: Call.State, message: String) in
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
		}, onAccountRegistrationStateChanged: { (core: Core, account: Account, state: RegistrationState, message: String) in
			NSLog("New registration state is \(state) for user id \( String(describing: account.params?.identityAddress?.asString()))\n")
			if (state == .Ok) {
				self.loggedIn = true
				// Since core has "Push Enabled", the reception and setting of the push notification token is done automatically
				// It should have been set and used when we log in, you can check here or in the liblinphone logs
				NSLog("Account registered Push voip token: \(account.params?.pushNotificationConfig?.voipToken)")
                if self.isComingFromVoip {
#if targetEnvironment(simulator)
           
#else
                    self.mProviderDelegate.incomingCall()
#endif
                }
			} else {
				self.loggedIn = false
			}
		})
		mCore.addDelegate(delegate: mCoreDelegate)
	}
	
	func login() {
		
        if (username == "") {
            return
        }
        
        if (passwd == "") {
            return
        }
        
        if (domain == "") {
            return
        }
        
        let dic = [
            "username":username,
            "passwd":passwd,
            "domain":domain,
            "proxy":proxy,
            "transportType":transportType
        ];
        
        UserDefaults.standard.setValue(dic, forKey: userDefaultStr)
        UserDefaults.standard.synchronize()
		do {
            mCore.verifyServerCertificates(yesno: false)
			var transport : TransportType
			if (transportType == "TLS") { transport = TransportType.Tls }
			else if (transportType == "TCP") { transport = TransportType.Tcp }
			else  { transport = TransportType.Udp }
            
            if proxy == "" && domain != "" {
                proxy = domain
            }
			
			let authInfo = try Factory.Instance.createAuthInfo(username: username, userid: "", passwd: passwd, ha1: "", realm: "", domain: domain)
			let accountParams = try mCore.createAccountParams()
			let identity = try Factory.Instance.createAddress(addr: String("sip:" + username + "@" + domain))
			try! accountParams.setIdentityaddress(newValue: identity)
			let address = try Factory.Instance.createAddress(addr: String("sip:" + proxy))
			try address.setTransport(newValue: transport)
			try accountParams.setServeraddress(newValue: address)
			accountParams.registerEnabled = true
			// Enable push notifications on this account
			accountParams.pushNotificationAllowed = true
			// We're in a sandbox application, so we must set the provider to "apns.dev" since it will be "apns" by default, which is used only for production apps
			accountParams.pushNotificationConfig?.provider = "apns.dev"
			mAccount = try mCore.createAccount(params: accountParams)
			mCore.addAuthInfo(info: authInfo)
            
			try mCore.addAccount(account: mAccount!)
			mCore.defaultAccount = mAccount
			
		} catch { NSLog(error.localizedDescription) }
#if DEBUG
        FLEXManager.shared.showExplorer()
#endif
	}
	
	func unregister()
	{
		if let account = mCore.defaultAccount {
			let params = account.params
			let clonedParams = params?.clone()
			clonedParams?.registerEnabled = false
			account.params = clonedParams
		}
	}
	func delete() {
		if let account = mCore.defaultAccount {
			mCore.removeAccount(account: account)
			mCore.clearAccounts()
			mCore.clearAllAuthInfo()
		}
	}
}
