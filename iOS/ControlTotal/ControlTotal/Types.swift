//
//  Types.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 19/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//
/*class ConnectionParameters:NSObject{
    var username:String = ""
    var password:String = ""
    var ip:String = ""
    var port:Int = -1
}*/
var ConnectionParameters:Dictionary<String, String> = ["username": "",
    "password": "",
    "company": "",
    "ip": "",
    "port": "-1"]

class Hosts:NSObject{
    var connections:[Dictionary<String, String>]?
}