//
//  ContentView.swift
//  CallKit tutorial
//
//  Created by QuentinArguillere on 09/09/2021.
//  Copyright © 2021 BelledonneCommunications. All rights reserved.
//

import SwiftUI
import CoreMedia

struct ContentView: View {
	
	@ObservedObject var tutorialContext : CallKitExampleContext
    @State var showIDSheet = false
    @State var showServeSheet = false

	func callStateString() -> String {
		if (tutorialContext.isCallRunning) {
			return "Call running"
		} else if (tutorialContext.isCallIncoming) {
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
					TextField("", text : $tutorialContext.username)
						.textFieldStyle(RoundedBorderTextFieldStyle())
						.disabled(tutorialContext.loggedIn)
                }
				HStack {
					Text("Password:")
						.font(.title3)
					TextField("", text : $tutorialContext.passwd)
						.textFieldStyle(RoundedBorderTextFieldStyle())
						.disabled(tutorialContext.loggedIn)
				}
				HStack {
					Text("Domain:")
						.font(.title3)
					TextField("", text : $tutorialContext.domain)
						.textFieldStyle(RoundedBorderTextFieldStyle())
						.disabled(tutorialContext.loggedIn)
				}
                HStack {
                    Text("Prxoy:")
                        .font(.title3)
                    TextField("", text : $tutorialContext.proxy)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(tutorialContext.loggedIn)
                }
                HStack {
                    Text("PushPrxoy:")
                        .font(.title3)
                    TextField("", text : $tutorialContext.pushProxy)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(tutorialContext.loggedIn)
                }
				Picker(selection: $tutorialContext.transportType, label: Text("Transport:")) {
					Text("TLS").tag("TLS")
					Text("TCP").tag("TCP")
					Text("UDP").tag("UDP")
				}.pickerStyle(SegmentedPickerStyle()).padding()
               
                Group {
                    HStack {
                        Text("identity: ")
                            .font(.title3)
                        Button(action: {
                            self.showIDSheet = true
                        }){
                            
                            Text(tutorialContext.identityString != "" ? tutorialContext.identityString: tutorialContext.domain)
                        }.actionSheet(isPresented: $showIDSheet, content: {idSheet})
                            
                    }.padding(.top, 1.0)
                    
                    HStack {
                        Text("serverAddress: ")
                            .font(.title3)
                        Button(action: {
                            self.showServeSheet = true
                        }){
                            
                            Text(tutorialContext.serveString != "" ? tutorialContext.serveString: tutorialContext.domain)
                        }.actionSheet(isPresented: $showServeSheet, content: {serveSheet})
                            
                    }.padding(.top, 1.0)
                }
                
				VStack {
					HStack {
						Button(action:  {
							if (self.tutorialContext.loggedIn)
							{
								self.tutorialContext.unregister()
								self.tutorialContext.delete()
							} else {
								self.tutorialContext.login()
							}
						})
						{
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
						Text(tutorialContext.loggedIn ? "Looged in" : "Unregistered")
							.font(.footnote)
							.foregroundColor(tutorialContext.loggedIn ? Color.green : Color.black)
					}.padding(.top, 1.0)
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
                    Button(action: {if (self.tutorialContext.isCallRunning) {
                        tutorialContext.mProviderDelegate.stopCall()
                    } else {
                        Callmanager.instance().terminateCall()
                    }})
                    {
                        Text("End call").font(.title2)
                            .foregroundColor(Color.white)
                            .frame(width: 120.0, height: 25.0)
                            .background(Color.gray)
                    }
                    .padding(.top, 5)
                    
                    HStack {
                        Text("CallAddress:")
                            .font(.title3)
                        TextField("", text : $tutorialContext.callAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    Picker(selection: $tutorialContext.encryption, label: Text("Encryption:")) {
                        Text("None").tag("None")
                        Text("SRTP").tag("SRTP")
                        Text("ZRTP").tag("ZRTP")
                        Text("DTLS").tag("DTLS")
                    }.pickerStyle(SegmentedPickerStyle()).padding()
                    
                    Button(action: tutorialContext.call)
                    {
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
                    Button(action: self.tutorialContext.showFlex){
                        Text("show Debug Tool").frame(width: 180, height: 30, alignment: .center)
                    }
                    
//                    Button(action: self.tutorialContext.deleteUserDefault){
//                        Text("rest").frame(width: 80, height: 30, alignment: .center)
//                    }
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
    
    private var serveSheet :ActionSheet {
        
         let action =  ActionSheet(title: Text("Select Server Address"),
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
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(tutorialContext: CallKitExampleContext())
	}
}
