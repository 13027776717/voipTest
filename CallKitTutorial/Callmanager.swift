//
//  Callmanager.swift
//  CallKitTutorial
//
//  Created by 付东 on 2022/6/30.
//  Copyright © 2022 BelledonneCommunications. All rights reserved.
//

import UIKit
import linphonesw
import CallKit

class Callmanager: NSObject {
    static var theCallManager: Callmanager?
    
    var mProviderDelegate : CallKitProviderDelegate!
    var mCore: Core!
    var mCoreDelegate : CoreDelegate!
    var mAccount: Account?
    
    var isLogin :Bool = false
    
    @objc static func instance() -> Callmanager {
        if theCallManager == nil {
            theCallManager = Callmanager()
        }
        return theCallManager!
    }
    
    func register(dic:NSDictionary) {
        
        let username:String = dic["username"] as! String
        let passwd:String = dic["passwd"] as! String
        let domain:String = dic["domain"] as! String
        var proxy:String = dic["proxy"] as! String
        let transportType:String = dic["transportType"] as! String
        
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
//            accountParams.pushNotificationAllowed = true
            accountParams.remotePushNotificationAllowed = true
            // We're in a sandbox application, so we must set the provider to "apns.dev" since it will be "apns" by default, which is used only for production apps
            accountParams.pushNotificationConfig?.provider = "apns.dev"
            mAccount = try mCore.createAccount(params: accountParams)
            mCore.addAuthInfo(info: authInfo)
            
            try mCore.addAccount(account: mAccount!)
            mCore.defaultAccount = mAccount
            
            if (isComeFromVoip) {
//                UserDefaults.standard.setValue("register", forKey: "register")
            }
            
        } catch { NSLog(error.localizedDescription) }

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
    
    func outingCall(address:String) {
        
        do {
            // As for everything we need to get the SIP URI of the remote and convert it to an Address
//            let remoteAddress = try Factory.Instance.createAddress(addr: address)
            
            if mAccount == nil {
                mAccount = mCore.defaultAccount
            }
            
            guard let remoteAddress =  mAccount?.normalizeSipUri(username: address) else { return }
                    
            // We also need a CallParams object
            // Create call params expects a Call object for incoming calls, but for outgoing we must use null safely
            let params = try mCore.createCallParams(call: nil)
            
            // We can now configure it
            // Here we ask for no encryption but we could ask for ZRTP/SRTP/DTLS
            params.mediaEncryption = MediaEncryption.None
            // If we wanted to start the call with video directly
            //params.videoEnabled = true
            
            // Finally we start the call
            let _ = mCore.inviteAddressWithParams(addr: remoteAddress, params: params)
            // Call process can be followed in onCallStateChanged callback from core listener
        } catch { NSLog(error.localizedDescription) }
    }
    
    func terminateCall() {
        do {
            if (mCore.callsNb == 0) { return }
            
            // If the call state isn't paused, we can get it using core.currentCall
            let coreCall = (mCore.currentCall != nil) ? mCore.currentCall : mCore.calls[0]
            
            // Terminating a call is quite simple
            if let call = coreCall {
                try call.terminate()
            }
        } catch { NSLog(error.localizedDescription) }
    }
    
    override init() {
        let factory = Factory.Instance
        // IMPORTANT : In this tutorial, we require the use of a core configuration file.
        // This way, once the registration is done, and until it is cleared, it will return to the LoggedIn state on launch.
        // This allows us to have a functional call when the app was closed and is started by a VOIP push notification (incoming call
        // We also need to enable "Push Notitifications" and "Background Mode - Voice Over IP"
        let configDir = factory.getConfigDir(context: nil)
        try? mCore = factory.createCore(configPath: "\(configDir)/MyConfig", factoryConfigPath: "", systemContext: nil)
        
        // enabling push notifications management in the core
        mCore.callkitEnabled = true
        mCore.pushNotificationEnabled = true
        
        try? mCore.start()
        
        mCoreDelegate = CoreDelegateStub( onCallStateChanged: { (core: Core, call: Call, state: Call.State, message: String) in
            
            print("call.d =22= \(call.callLog?.callId)")
            NSLog("111111")
//            UserDefaults.standard.setValue("all.state", forKey: "call.state")
//            UserDefaults.standard.setValue("cellCome", forKey:"call")
            let notificationName = Notification.Name(rawValue: "call")
                        NotificationCenter.default.post(name: notificationName, object: nil,
                                                        userInfo: ["state":state,"call":call,"message":message])
            
        }, onAccountRegistrationStateChanged: { (core: Core, account: Account, state: RegistrationState, message: String) in
           
            if (isComeFromVoip) {
//                UserDefaults.standard.setValue(state, forKey: "state")
            }
            if (state == .Ok) {
//                self.isLogin = true
//                if (isComeFromVoip) {
//                    UserDefaults.standard.setValue("Back Ground Success", forKey: backGround)
                    isComeFromVoip = false
//                }
            } else {
//                self.isLogin = false
            }
            let notificationName = Notification.Name(rawValue: "register")
                        NotificationCenter.default.post(name: notificationName, object: nil,
                                                        userInfo: ["state":state])
        })
        mCore.addDelegate(delegate: mCoreDelegate)
    }
    
    @objc func findCall(callId: String?) -> OpaquePointer? {
        let call = callByCallId(callId: callId)
        return call?.getCobject
    }

    func callByCallId(callId: String?) -> Call? {
        if (callId == nil) {
            return nil
        }
        let calls = mCore?.calls
        if let callTmp = calls?.first(where: { $0.callLog?.callId == callId }) {
            return callTmp
        }
        return nil
    }
    
}
