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
    @objc static func instance() -> Callmanager {
        if theCallManager == nil {
            theCallManager = Callmanager()
        }
        return theCallManager!
    }
    
    override init() {
        
        
    }
    
    
}
