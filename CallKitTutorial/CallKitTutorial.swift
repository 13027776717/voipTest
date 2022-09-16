//
//  CallExample.swift
//  CallTutorial
//
//  Created by QuentinArguillere on 31/07/2020.
//  Copyright © 2020 BelledonneCommunications. All rights reserved.
//

import Alamofire
import AVFoundation
import linphonesw

#if DEBUG
    import FLEX
    import SwiftUI
#endif

class CallKitExampleContext: ObservableObject {
    @Published var coreVersion: String = Core.getVersion

    @Published var username: String = "3333"
    @Published var passwd: String = "7cU3rjjJjb4EXqwFqTHBvLzAjy7A3s"
    @Published var domain: String = "comms.kelare-demo.com" /// 119.28.64.168
    @Published var loggedIn: Bool = false
    @Published var transportType: String = "TLS"
    @Published var proxy: String = "comms-ext.kelare-demo.com"
    @Published var pushProxy: String = ""

    @Published var callMsg: String = ""
    @Published var isCallIncoming: Bool = false
    @Published var isCallRunning: Bool = false
    @Published var remoteAddress: String = "Nobody yet"
    @Published var isSpeakerEnabled: Bool = false
    @Published var isMicrophoneEnabled: Bool = false

    @Published var callAddress: String = ""

    @Published var identityString = ""
    @Published var serveString = ""
    @Published var encryption = "SRTP"
    @Published var showTip = false

    @Published var handlerPushType = 0
    @Published var expires = "3600"
    @Published var stunServer = "stun:turn.matrix.org"
    @Published var isStun = false

    var pushRegionArray: NSArray = []

    /*
     stun:stun1.l.google.com:19302
     stun:stun2.l.google.com:19302
     stun:stun3.l.google.com:19302
     stun:stun4.l.google.com:19302
     stun:23.21.150.121
     stun:stun01.sipphone.com
     stun:stun.ekiga.net
     stun:stun.fwdnet.net
     stun:stun.ideasip.com
     stun:stun.iptel.org
     stun:stun.rixtelecom.se
     stun:stun.schlund.de
     stun:stunserver.org
     stun:stun.softjoys.com
     stun:stun.voiparound.com
     stun:stun.voipbuster.com
     stun:stun.voipstunt.com
     stun:stun.voxgratia.org
     stun:stun.xten.com
          */

    /*------------ Callkit tutorial related variables ---------------*/
    let incomingCallName = "Incoming call"
    var mCall: Call?
    var mProviderDelegate: CallKitProviderDelegate!
    var mCallAlreadyStopped: Bool = false

    var isComingFromVoip: Bool = false

    init() {
        let handleType = UserDefaults.standard.value(forKey: handleNotificationType)

        if handleType != nil {
            let type = handleType as! Int
            handlerPushType = type
        } else {
            UserDefaults.standard.setValue(0, forKey: handleNotificationType)
            handlerPushType = 0
        }

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
            expires = user["expires"]!
            stunServer = user["stunServer"]!
            isStun = Bool(user["isStun"]!)!
        } else {
            username = "1006"
            passwd = "P@55word1!"
            domain = "abc.justrandoms.com"
            transportType = "TLS"
            proxy = "sip.justrandoms.com"
            pushProxy = "proxy.justrandoms.com:5060"
            expires = "3600"
            stunServer = "stun:turn.matrix.org"
            isStun = true
        }

        if identityString == "" {
            identityString = domain
        }

        if serveString == "" {
            serveString = domain
        }

        mProviderDelegate = CallKitProviderDelegate(context: self)

        let back = UserDefaults.standard.value(forKey: backGround)

        if back != nil && back as! String != "" {
            coreVersion = back as! String
        }

        let notificationName = Notification.Name(rawValue: "register")
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(register(notification:)),
                                               name: notificationName, object: nil)
        let notificationCall = Notification.Name(rawValue: "call")
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(call(notification:)),
                                               name: notificationCall, object: nil)
        getPushRegion()
    }

    // MARK: - notification -

    @objc func register(notification: Notification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let state: RegistrationState = userInfo["state"] as! RegistrationState

        if state == .Ok {
            loggedIn = true
            // Since core has "Push Enabled", the reception and setting of the push notification token is done automatically
            // It should have been set and used when we log in, you can check here or in the liblinphone logs

            #if targetEnvironment(simulator)

            #else
//                self.mProviderDelegate.incomingCall()
            #endif

        } else {
            loggedIn = false
        }
    }

    @objc func call(notification: Notification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let state: Call.State = userInfo["state"] as! Call.State
        let message: String = userInfo["message"] as! String
        let call: Call = userInfo["call"] as! Call

        callMsg = message
        if state == .PushIncomingReceived {
            // We're being called by someone (and app is in background)
            mCall = call
            isCallIncoming = true
            mProviderDelegate.incomingCall()

        } else if state == .IncomingReceived {
            // If app is in foreground, it's likely that we will receive the SIP invite before the Push notification
            if !isCallIncoming {
                mCall = call
                isCallIncoming = true
                #if targetEnvironment(simulator)

                #else
                    mProviderDelegate.incomingCall()
                #endif
            }
            remoteAddress = call.remoteAddress!.asStringUriOnly()
        } else if state == .Connected {
            isCallIncoming = false
            isCallRunning = true
        } else if state == .Released || state == .End || state == .Error {
            // Call has been terminated by any side

            // Report to CallKit that the call is over, if the terminate action was initiated by other end of the call
//            if isCallRunning {
            mProviderDelegate.stopCall()
//            } else {
//
//            }
            remoteAddress = "Nobody yet"
        }
    }

    // MARK: - action -

    func login() {
        isComeFromVoip = false
        Callmanager.instance().isLogin = true
        if username == "" {
            return
        }

        if passwd == "" {
            return
        }

        if domain == "" {
            return
        }

        if identityString.trim() == "" || serveString.trim() == "" {
            showTip = true
            return
        }

        let dic = [
            "username": username,
            "passwd": passwd,
            "domain": domain,
            "proxy": proxy,
            "transportType": transportType,
            "pushProxy": pushProxy,
            "identity": identityString,
            "server": serveString,
            "expires": expires,
            "stunServer": stunServer,
            "isStun": String(isStun),
        ]
        UserDefaults.standard.setValue(dic, forKey: userDefaultStr)
        UserDefaults.standard.synchronize()
        Callmanager.instance().register(dic: dic as NSDictionary)
    }

    func unregister() {
        loggedIn = false
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
            var encrypt: MediaEncryption = .None
            if encryption == "SRTP" {
                encrypt = .SRTP
            } else if encryption == "ZRTP" {
                encrypt = .ZRTP
            } else if encryption == "DTLS" {
                encrypt = .DTLS
            } else {
                encrypt = .None
            }
//            mProviderDelegate.startCall(remoteAddress: <#T##Address#>)
            Callmanager.instance().mProviderDelegate = mProviderDelegate
            Callmanager.instance().outingCall(address: callAddress, encryption: encrypt)
        }
    }

    func acceptCall() {
        do {
            // if we wanted, we could create a CallParams object
            // and answer using this object to make changes to the call configuration
            // (see OutgoingCall tutorial)
            try Callmanager.instance().mCore.currentCall?.accept()
        } catch { NSLog(error.localizedDescription) }
    }

    func handlerChange(_ tag: Int) {
        UserDefaults.standard.setValue(tag, forKey: handleNotificationType)
        UserDefaults.standard.synchronize()

        print("handlerChange tag: \(tag)")
    }

    // MARK: - network -

    func getPushRegion() {
        AF.request("https://regions.turtle.solutions:1997/api/stg/regions", method: .get, parameters: ["sort_by": "closest"]).responseJSON { response in

            switch response.result {
            case .success:
                let dic = response.value as! NSDictionary
                let array = dic.value(forKey: "data") as! NSArray
                if array.count > 0 {
                    self.pushRegionArray = array
                    UserDefaults.standard.setValue(array, forKey: "pushRegion")
                    UserDefaults.standard.synchronize()
                }

                print("Validation Successful")
            case let .failure(error):
                print(error)
            }
        }
    }

    /*
     {
     "name":"us-region-1",
     "city":"Ashburn",
     "region":"Virginia",
     "country":"America",
     "countryCode":"us",
     "address":"proxy.justrandoms.com",
     "ipAddress":"54.144.43.24",
     "location":{"lat":"39.0437","long":"-77.4875"},
     "timezone":"",
     "transportCapabilites":["udp","tcp","tls","webrtc"],
     "certificate":"public"}
     */
}

extension String {
    func trim() -> String {
        var resultString = trimmingCharacters(in: CharacterSet.whitespaces)
        resultString = resultString.trimmingCharacters(in: CharacterSet.newlines)
        return resultString
    }
}
