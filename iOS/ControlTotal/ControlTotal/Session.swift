//
//  Session.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 05/12/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

class Session {
    var session:NMSSHSession?
    let queue = NSOperationQueue()
    var lastOperation:NSOperation?
    var refreshTimer:NSTimer?
    var musicState = ""
    
    class var sharedInstance: Session {
        struct Static {
            static var instance: Session?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = Session()
        }
        
        return Static.instance!
    }
}