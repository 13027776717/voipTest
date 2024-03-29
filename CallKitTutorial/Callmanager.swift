//
//  Callmanager.swift
//  CallKitTutorial
//
//  Created by 付东 on 2022/6/30.
//  Copyright © 2022 BelledonneCommunications. All rights reserved.
//

import CallKit
import linphonesw
import UIKit

class Callmanager: NSObject {
    static var theCallManager: Callmanager?

    var mProviderDelegate: CallKitProviderDelegate!
    var mCore: Core!
    var mCoreDelegate: CoreDelegate!
    var mAccount: Account?

    var isLogin: Bool = false

    @objc static func instance() -> Callmanager {
        if theCallManager == nil {
            theCallManager = Callmanager()
        }
        return theCallManager!
    }

    func register(dic: NSDictionary) {
        let username: String = dic["username"] as! String
        let passwd: String = dic["passwd"] as! String
        let expires: String = dic["expires"] as! String
        let domain: String = dic["domain"] as! String
        let proxy: String = dic["proxy"] as! String
        let transportType: String = dic["transportType"] as! String
        var pushProxy = dic["pushProxy"] as! String
        var domainAddress = ""
        var sipProxy = ""
        let identityAddress = dic["identity"] as! String
        let serverAddress = dic["server"] as! String
        let stunServer = dic["stunServer"] as! String
        let isStun = Bool(dic["isStun"] as! String)!
        let isPushProxy = Bool(dic["isPushProxy"] as! String)!
        
        do {
            mCore.verifyServerCertificates(yesno: false)
            var transport: TransportType
            if transportType == "TLS" {
                transport = TransportType.Tls
                
            } else if transportType == "TCP" {
                transport = TransportType.Tcp
                
            } else {
                transport = TransportType.Udp
                
            }
            
            if (pushProxy != "") {
                if transportType == "TLS" {
                    
                    pushProxy = pushProxy + ":5061"
                } else {
                    
                    pushProxy = pushProxy + ":5060"
                }
                
            }

            var isHeader = false
            var isOutboundProxy = false
            if pushProxy != "" && proxy != "" {
                /// domain  proxy  push proxy
                isHeader = true
                domainAddress = pushProxy
                sipProxy = pushProxy
                isOutboundProxy = true
            } else {
                domainAddress = domain
                if pushProxy != "" || proxy != "" {
                    if pushProxy != "" {
                        sipProxy = pushProxy
                    } else {
                        sipProxy = proxy
                    }
                    isOutboundProxy = true
                } else {
                    // domain
                    sipProxy = domain
                    isOutboundProxy = false
                }
            }
            
            

            let authInfo = try Factory.Instance.createAuthInfo(username: username, userid: "", passwd: passwd, ha1: "", realm: "", domain: domain)

            let accountParams = try mCore.createAccountParams()

            /// identity
            let identity = try Factory.Instance.createAddress(addr: String("sip:" + username + "@" + identityAddress))
            try identity.setTransport(newValue: transport)
            try! accountParams.setIdentityaddress(newValue: identity)

            /// push  proxy
            let address = try Factory.Instance.createAddress(addr: String("sip:" + serverAddress))
            try address.setTransport(newValue: transport)
            try accountParams.setServeraddress(newValue: address)

            /// route Address
            if isOutboundProxy {
                try accountParams.setRoutesaddresses(newValue: [address])
            }
            
            accountParams.registerEnabled = true
            // Enable push notifications on this account
//            accountParams.pushNotificationAllowed = true
            accountParams.remotePushNotificationAllowed = true
            // We're in a sandbox application, so we must set the provider to "apns.dev" since it will be "apns" by default, which is used only for production apps
            accountParams.pushNotificationConfig?.provider = "apns.dev"
            
            mAccount = try mCore.createAccount(params: accountParams)
            // add CustomHeader
            if isHeader {
//                mAccount?.setCustomHeader(headerName: "x-domain", headerValue: domain)
                mAccount?.setCustomHeader(headerName: "x-outbound-proxy", headerValue: proxy)
                
                accountParams.contactParameters = "x-outbound-proxy=\(proxy);expires=\(expires)"
                
            }else {
                /// contact add expires
                accountParams.contactParameters = "expires=\(expires)"
            }

            
            /// expires
            accountParams.expires = Int(expires) ?? 3600
            
            ///contactUriParameters
            //accountParams.contactUriParameters = "119.28.64.168"

            
            /// nat
            /// stun:stun1.l.google.com:19302
            if isStun {
                var natPolicy = accountParams.natPolicy
                if natPolicy == nil {
                    natPolicy = try mCore.createNatPolicy()
                }

                natPolicy?.stunEnabled = true
                natPolicy?.turnEnabled = true
                natPolicy?.iceEnabled = true
                natPolicy?.stunServer = stunServer

                natPolicy?.upnpEnabled = true
                natPolicy?.tcpTurnTransportEnabled = true
                natPolicy?.tlsTurnTransportEnabled = true
                natPolicy?.udpTurnTransportEnabled = true
                
                accountParams.natPolicy = natPolicy
            }
            /// 如果使用推送代理 ，设置header
            /// pn-pbx-domain
            /// pn-pbx-out-proxy
            /// pn-sbc-proxy
            /// pn-topic :bundle id
            /// pn-os-type:iOS
            /// pn-from-type:apn
            if isPushProxy {
                let bundleIdentifier =  Bundle.main.bundleIdentifier
                mAccount?.setCustomHeader(headerName: "pn-pbx-domain", headerValue: domain)
                mAccount?.setCustomHeader(headerName: "pn-pbx-out-proxy", headerValue: proxy)
                mAccount?.setCustomHeader(headerName: "pn-sbc-proxy", headerValue: pushProxy)
                mAccount?.setCustomHeader(headerName: "pn-topic", headerValue: bundleIdentifier)
                mAccount?.setCustomHeader(headerName: "pn-os-type", headerValue: "iOS")
                mAccount?.setCustomHeader(headerName: "pn-from-type", headerValue: "apn")
            }

           
            /// verifyServerCertificate
//            mCore.verifyServerCertificates(yesno: false)
            mCore.addAuthInfo(info: authInfo)
            mCore.ipv6Enabled = true
            mCore.useRfc2833ForDtmf = true
            try mCore.addAccount(account: mAccount!)
            mCore.defaultAccount = mAccount

        } catch { NSLog(error.localizedDescription) }
    }

    func unregister() {
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

    func outingCall(address: String, encryption: MediaEncryption) {
        do {
            // As for everything we need to get the SIP URI of the remote and convert it to an Address
//            let remoteAddress = try Factory.Instance.createAddress(addr: address)

            if mAccount == nil {
                mAccount = mCore.defaultAccount
            }
            

            guard let remoteAddress = mAccount?.normalizeSipUri(username: address) else { return }
//             try remoteAddress.setPort(newValue: 50160)

            // We also need a CallParams object
            // Create call params expects a Call object for incoming calls, but for outgoing we must use null safely
            let params = try mCore.createCallParams(call: nil)
            
            // We can now configure it
            // Here we ask for no encryption but we could ask for ZRTP/SRTP/DTLS

            params.mediaEncryption = encryption
            // If we wanted to start the call with video directly
             params.videoEnabled = true
            params.audioEnabled = true
//            params.avpfEnabled = true
//            params.capabilityNegotiationReinviteEnabled = true
//            params.earlyMediaSendingEnabled = true
//            params.rtpBundleEnabled = true
 
            
            // add header
            let userDefault = UserDefaults.standard.value(forKey: userDefaultStr)

            if userDefault != nil {
                let user = userDefault as! Dictionary<String, String>
                
                let isPushProxy = Bool(user["isPushProxy"]!)!
                
                let domain = user["domain"]!
                
                let proxy: String = user["proxy"]!

                let pushProxy: String = user["pushProxy"]!

                if proxy != "" && pushProxy != "" {

                    params.addCustomHeader(headerName: "x-outbound-proxy", headerValue: proxy)
                    
                }
                
                if isPushProxy {
                    let bundleIdentifier =  Bundle.main.bundleIdentifier
                    params.addCustomHeader(headerName: "pn-pbx-domain", headerValue: domain)
                    params.addCustomHeader(headerName: "pn-pbx-out-proxy", headerValue: proxy)
                    params.addCustomHeader(headerName: "pn-sbc-proxy", headerValue: pushProxy)
                    params.addCustomHeader(headerName: "pn-topic", headerValue: bundleIdentifier)
                    params.addCustomHeader(headerName: "pn-os-type", headerValue: "iOS")
                    params.addCustomHeader(headerName: "pn-from-type", headerValue: "apn")
                }
               
                /// dial  add transport
                let transportType: String = user["transportType"]!
                var transport: TransportType
                if transportType == "TLS" { transport = TransportType.Tls }
                else if transportType == "TCP" { transport = TransportType.Tcp }
                else { transport = TransportType.Udp }
                try remoteAddress.setTransport(newValue: transport)

                if callKitEnabled() {
                    mProviderDelegate.startCall(remoteAddress: remoteAddress)
                }
            }

            // Finally we start the call
            _ = mCore.inviteAddressWithParams(addr: remoteAddress, params: params)
            // Call process can be followed in onCallStateChanged callback from core listener
        } catch { NSLog(error.localizedDescription) }
    }

    func terminateCall() {
        do {
            if mCore.callsNb == 0 { return }

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

        mCoreDelegate = CoreDelegateStub(onCallStateChanged: { (_: Core, call: Call, state: Call.State, message: String) in

            let notificationName = Notification.Name(rawValue: "call")
            NotificationCenter.default.post(name: notificationName, object: nil,
                                            userInfo: ["state": state, "call": call, "message": message])

        }, onAccountRegistrationStateChanged: { (_: Core, _: Account, state: RegistrationState, _: String) in

            let notificationName = Notification.Name(rawValue: "register")
            NotificationCenter.default.post(name: notificationName, object: nil,
                                            userInfo: ["state": state])
        })
        mCore.addDelegate(delegate: mCoreDelegate)
    }

    @objc func findCall(callId: String?) -> OpaquePointer? {
        let call = callByCallId(callId: callId)
        return call?.getCobject
    }

    func callByCallId(callId: String?) -> Call? {
        if callId == nil {
            return nil
        }
        let calls = mCore?.calls
        if let callTmp = calls?.first(where: { $0.callLog?.callId == callId }) {
            return callTmp
        }
        return nil
    }

    func callKitEnabled() -> Bool {
        #if !targetEnvironment(simulator)

            return true

        #endif

        return false
    }
}
