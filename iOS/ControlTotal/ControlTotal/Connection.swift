//
//  SSH.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 20/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//


class Connection:NSOperation, NMSSHChannelDelegate{
    var session:NMSSHSession = NMSSHSession()
    var params = ConnectionProperties().sessionParams
    var authorized = false
    
    override func main() -> (){
        autoreleasepool { () -> () in
            self.authorized = false
            self.session = NMSSHSession.connectToHost(self.params["ip"], withUsername: self.params["username"])! as NMSSHSession
            if (!self.session.connected) {
                println("Connection error")
            }else{
                println("connected")
                var authenticated:Bool = self.session.authenticateByKeyboardInteractiveUsingBlock({
                    (var passString:String!) -> String! in
                    return self.params["password"]
                })
                if (self.session.authorized) {
                    println("authorized")
                    self.session.channel.delegate = self;
                    self.session.channel.requestPty = true;
                    self.session.channel.ptyTerminalType = NMSSHChannelPtyTerminal.VT100
                    
                    //self.session.channel.startShell(nil)
                    self.authorized = true
                }
            }
        }
    }
}