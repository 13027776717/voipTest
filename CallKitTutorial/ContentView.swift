//
//  ContentView.swift
//  CallKit tutorial
//
//  Created by QuentinArguillere on 09/09/2021.
//  Copyright © 2021 BelledonneCommunications. All rights reserved.
//

import SwiftUI

struct ContentView: View {
	
	@ObservedObject var tutorialContext : CallKitExampleContext
	
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
		
		VStack {
			Group {
				HStack {
					Text("Username:")
						.font(.title)
					TextField("", text : $tutorialContext.username)
						.textFieldStyle(RoundedBorderTextFieldStyle())
						.disabled(tutorialContext.loggedIn)
				}
				HStack {
					Text("Password:")
						.font(.title)
					TextField("", text : $tutorialContext.passwd)
						.textFieldStyle(RoundedBorderTextFieldStyle())
						.disabled(tutorialContext.loggedIn)
				}
				HStack {
					Text("Domain:")
						.font(.title)
					TextField("", text : $tutorialContext.domain)
						.textFieldStyle(RoundedBorderTextFieldStyle())
						.disabled(tutorialContext.loggedIn)
				}
                HStack {
                    Text("Prxoy:")
                        .font(.title)
                    TextField("", text : $tutorialContext.proxy)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(tutorialContext.loggedIn)
                }
				Picker(selection: $tutorialContext.transportType, label: Text("Transport:")) {
					Text("TLS").tag("TLS")
					Text("TCP").tag("TCP")
					Text("UDP").tag("UDP")
				}.pickerStyle(SegmentedPickerStyle()).padding()
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
                                .font(.title2)
								.foregroundColor(Color.white)
								.frame(width: 220.0, height: 40)
								.background(Color.gray)
						}
					}
					HStack {
						Text("Login State : ")
							.font(.footnote)
						Text(tutorialContext.loggedIn ? "Looged in" : "Unregistered")
							.font(.footnote)
							.foregroundColor(tutorialContext.loggedIn ? Color.green : Color.black)
					}.padding(.top, 5.0)
				}
				VStack {
					HStack {
						Text("Caller:").font(.title).underline()
						Text(tutorialContext.remoteAddress)
						Spacer()
					}.padding(.top, 1)
					HStack {
						Text("Call msg:").font(.title3).underline()
						Text(tutorialContext.callMsg)
						Spacer()
					}.padding(.top, 1)
				}.padding(.top, 5)
                Button(action: {if (self.tutorialContext.isCallRunning) {
                    tutorialContext.mProviderDelegate.stopCall()
                } else {
                    Callmanager.instance().terminateCall()
                }})
				{
					Text("End call").font(.title2)
						.foregroundColor(Color.white)
						.frame(width: 120.0, height: 35.0)
						.background(Color.gray)
				}
				.padding(.top, 5)
                
                HStack {
                    Text("CallAddress:")
                        .font(.title)
                    TextField("", text : $tutorialContext.callAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Button(action: tutorialContext.call)
                {
                    Text("CALL").font(.title3)
                        .foregroundColor(Color.white)
                        .frame(width: 120.0, height: 35.0)
                        .background(Color.gray)
                }
                .padding(.top, 5)
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
				Text("Core Version is \(tutorialContext.coreVersion)")
                
			}
		}
		.padding()
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(tutorialContext: CallKitExampleContext())
	}
}
