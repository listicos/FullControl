//
//  ConnectionProperties.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 20/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

class ConnectionProperties{
    var hosts: Hosts{
        get{
            var savedValue = NSUserDefaults.standardUserDefaults().objectForKey("hosts") as? Hosts
            return savedValue!
        }
        set(newValue){
            NSUserDefaults.standardUserDefaults().setObject(newValue as Hosts, forKey: "hosts")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var sessionParams: Dictionary<String, String>{
        get{
            var value = NSUserDefaults.standardUserDefaults().objectForKey("sessionParams") as? Dictionary<String, String>
            return value!
        }
        set(value){
            NSUserDefaults.standardUserDefaults().setObject(value as Dictionary<String, String>, forKey: "sessionParams")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
}