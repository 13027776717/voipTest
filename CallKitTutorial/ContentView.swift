//
//  ContentView.swift
//  CallKit tutorial
//
//  Created by QuentinArguillere on 09/09/2021.
//  Copyright © 2021 BelledonneCommunications. All rights reserved.
//

import CoreMedia
import SwiftUI

struct ContentView: View {
    @ObservedObject var tutorialContext: CallKitExampleContext
    @State var showIDSheet = false
    @State var showServeSheet = false
    @State var showPushRegion = false

    func callStateString() -> String {
        if tutorialContext.isCallRunning {
            return "Call running"
        } else if tutorialContext.isCallIncoming {
            return "Incoming call"
        } else {
            return "No Call"
        }
    }

    var body: some View {
        ScrollView {
            VStack {
                Group {
                    HStack {
                        Text("Username:")
                            .font(.title3)
                        TextField("", text: $tutorialContext.username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(tutorialContext.loggedIn)
                    }
                    HStack {
                        Text("Password:")
                            .font(.title3)
                        TextField("", text: $tutorialContext.passwd)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(tutorialContext.loggedIn)
                    }
                    Group {
                        HStack {
                            Text("Stun:")
                                .font(.title3)
                            TextField("", text: $tutorialContext.stunServer)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(tutorialContext.loggedIn)
                        }
                        HStack {
                            Toggle(isOn: $tutorialContext.isStun) {
                                Text("Use Stun:")
                            }.disabled(tutorialContext.loggedIn)
                        }
                        HStack {
                            Text("Expires:")
                                .font(.title3)
                            TextField("", text: $tutorialContext.expires)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(tutorialContext.loggedIn)
                        }
                        HStack {
                            Text("Domain:")
                                .font(.title3)
                            TextField("", text: $tutorialContext.domain)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(tutorialContext.loggedIn)
                        }
                        HStack {
                            Text("Prxoy:")
                                .font(.title3)
                            TextField("", text: $tutorialContext.proxy)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(tutorialContext.loggedIn)
                        }
                        HStack {
                            Text("PushPrxoy:")
                                .font(.title3)
                            Button(action: {

                                self.showPushRegion = true


                            }) {
                                Text(tutorialContext.pushProxy)
                            }.actionSheet(isPresented: $showPushRegion, content: { pushRegionSheet })
                                .disabled(tutorialContext.loggedIn)
//                            TextField("", text: $tutorialContext.pushProxy)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .disabled(tutorialContext.loggedIn)
                        }
                    }

                    Picker(selection: $tutorialContext.transportType, label: Text("Transport:")) {
                        Text("TLS").tag("TLS")
                        Text("TCP").tag("TCP")
                        Text("UDP").tag("UDP")
                    }.pickerStyle(SegmentedPickerStyle()).padding()
                        .disabled(tutorialContext.loggedIn)

                    Group {
                        HStack {
                            Text("identity: ")
                                .font(.title3)
                            Button(action: {
                                self.showIDSheet = true
                            }) {
                                Text(tutorialContext.identityString)
                            }.actionSheet(isPresented: $showIDSheet, content: { idSheet })
                                .disabled(tutorialContext.loggedIn)

                        }.padding(.top, 1.0)

                        HStack {
                            Text("serverAddress: ")
                                .font(.title3)
                            Button(action: {
                                self.showServeSheet = true
                            }) {
                                Text(tutorialContext.serveString)
                            }.actionSheet(isPresented: $showServeSheet, content: { serveSheet })
                                .disabled(tutorialContext.loggedIn)

                        }.padding(.top, 1.0)
                    }

                    VStack {
                        HStack {
                            Button(action: {
                                if self.tutorialContext.loggedIn {
                                    self.tutorialContext.unregister()
                                    self.tutorialContext.delete()
                                } else {
                                    self.tutorialContext.login()
                                }
                            }) {
                                Text(tutorialContext.loggedIn ? "Log out" : "log in account")
                                    .font(.title3)
                                    .foregroundColor(Color.white)
                                    .frame(width: 220.0, height: 30)
                                    .background(Color.gray)
                            }
                        }
                        HStack {
                            Text("Login State : ")
                                .font(.footnote)
                            Text(tutorialContext.loggedIn ? "Logged in" : "Unregistered")
                                .font(.footnote)
                                .foregroundColor(tutorialContext.loggedIn ? Color.green : Color.black)
                        }.padding(.top, 1.0)
                    }
                    Group {
                        Picker(selection: $tutorialContext.handlerPushType, label: Text("Handle:")) {
                            Text("None").tag(0)
                            Text("CallId").tag(1)
                            Text("Unregister-register").tag(2)
                        }.onChange(of: tutorialContext.handlerPushType) { tag in

                            tutorialContext.handlerChange(tag)
                        }.pickerStyle(SegmentedPickerStyle()).padding()
                    }
                    Group {
                        VStack {
                            HStack {
                                Text("Caller:").font(.title3).underline()
                                Text(tutorialContext.remoteAddress)
                                Spacer()
                            }.padding(.top, 1)
                            HStack {
                                Text("Call msg:").font(.title3).underline()
                                Text(tutorialContext.callMsg)
                                Spacer()
                            }.padding(.top, 1)
                        }.padding(.top, 1)
                        Group {
                            HStack {
                                Button(action: { if self.tutorialContext.isCallRunning {
                                    tutorialContext.mProviderDelegate.stopCall()
                                } else {
                                    Callmanager.instance().terminateCall()
                                }}) {
                                    Text("End call").font(.title2)
                                        .foregroundColor(Color.white)
                                        .frame(width: 120.0, height: 25.0)
                                        .background(Color.gray)
                                }

                                Button(action: tutorialContext.acceptCall) {
                                    Text("Accept call").font(.title2)
                                        .foregroundColor(Color.white)
                                        .frame(width: 120.0, height: 25.0)
                                        .background(Color.gray)
                                }
                            }
                        }

                        HStack {
                            Text("CallAddress:")
                                .font(.title3)
                            TextField("", text: $tutorialContext.callAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        Picker(selection: $tutorialContext.encryption, label: Text("Encryption:")) {
                            Text("None").tag("None")
                            Text("SRTP").tag("SRTP")
                            Text("ZRTP").tag("ZRTP")
                            Text("DTLS").tag("DTLS")
                        }.pickerStyle(SegmentedPickerStyle()).padding()

                        Button(action: tutorialContext.call) {
                            Text("CALL").font(.title3)
                                .foregroundColor(Color.white)
                                .frame(width: 120.0, height: 35.0)
                                .background(Color.gray)
                        }
                        .padding(.top, 5)
                    }
                }
                Group {
                    Spacer()
                    HStack {
                        Button(action: self.tutorialContext.showFlex) {
                            Text("show Debug Tool").frame(width: 180, height: 30, alignment: .center)
                        }
                    }
                    //				Text("Core Version is \(tutorialContext.coreVersion)")
                }
                .alert(isPresented: $tutorialContext.showTip) {
                    () -> Alert in
                    Alert(title: Text("identity or serverAddress is nil"))
                }
            }
            .padding()
        }
    }

    private var idSheet: ActionSheet {
        let action = ActionSheet(title: Text("Select Indentity Address"),
                                 message: Text(""),
                                 buttons:
                                 [.default(Text(tutorialContext.domain), action: {
                                     tutorialContext.identityString = tutorialContext.domain
                                     self.showIDSheet = false
                                 }), .default(Text(tutorialContext.proxy), action: {
                                     tutorialContext.identityString = tutorialContext.proxy
                                     self.showIDSheet = false
                                 }),
                                 .default(Text(tutorialContext.pushProxy), action: {
                                     tutorialContext.identityString = tutorialContext.pushProxy
                                     self.showIDSheet = false
                                 }), .cancel({
                                     print("Cancel")
                                     self.showIDSheet = false
                                 })])
        return action
    }

    private var serveSheet: ActionSheet {
        let action = ActionSheet(title: Text("Select Server Address"),
                                 message: Text(""),
                                 buttons:
                                 [.default(Text(tutorialContext.domain), action: {
                                     tutorialContext.serveString = tutorialContext.domain
                                     self.showServeSheet = false
                                 }), .default(Text(tutorialContext.proxy), action: {
                                     tutorialContext.serveString = tutorialContext.proxy
                                     self.showServeSheet = false
                                 }),
                                 .default(Text(tutorialContext.pushProxy), action: {
                                     tutorialContext.serveString = tutorialContext.pushProxy
                                     self.showServeSheet = false
                                 }), .cancel({
                                     print("Cancel")
                                     self.showServeSheet = false
                                 })])
        return action
    }

    private var pushRegionSheet: ActionSheet {
        let buttons: [ActionSheet.Button] = tutorialContext.pushRegionArray.enumerated().map { _, option in

            let dic = option as! NSDictionary
//            let name = dic["name"] as! String
            let address = dic["address"] as! String

            return ActionSheet.Button.default(Text(address), action: {
                tutorialContext.pushProxy = address
                self.showServeSheet = false
            })
        }

        let action = ActionSheet(title: Text("Select PushRegion"),
                                 message: Text(""),
                                 buttons: buttons + [ActionSheet.Button.cancel()]
        )
        return action
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(tutorialContext: CallKitExampleContext())
    }
}
