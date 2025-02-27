//
//  Command.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 20/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//
@objc protocol CommandDelegate{
    optional func commandDidResolve(command:AnyObject)
    optional func commandDidError(command:AnyObject)
}

class Command : NSOperation, NMSSHChannelDelegate{
    var delegate:CommandDelegate?
    var cg = CommandGenerator()
    var session:NMSSHSession = NMSSHSession()
    var app:AppsSupported
    var command:BasicCommand
    var extra:String!
    var response:Dictionary<String, String>!
    var error:NSError?
    
    init(session:NMSSHSession, app:AppsSupported, command: BasicCommand, extra:String = "") {
        self.app = app
        self.extra = extra
        self.command = command
        self.session = session
    }
    
    override func main() {
        autoreleasepool { () -> () in
            var c = CommandGenerator.app(self.app, command: self.command, extra:self.extra)
            if(!c.isEmpty){
                self.session.channel.delegate = self
                println("CHANNEL DELEGATE")
                if !self.cancelled{
                    println("no cancelled")
                    if self.session.channel != nil{
                        println("con session channel")
                        var r = self.session.channel.execute(c, error: &self.error)
                        println("after execute")
                        if r != nil{
                            println("Executed")
                            self.response = self.cg.handleResponse(self.command, response:r)
                            self.delegate?.commandDidResolve!(self)
                            if self.error != nil{
                                self.delegate?.commandDidError!(self)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func channel(channel: NMSSHChannel!, didReadError error: String!) {
        println("Woow:")
        println(error)
        
    }
    
    func channel(channel: NMSSHChannel!, didReadData message: String!) {
        println("mmmm")
    }
        
}