//
//  CommandDownload.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 12/12/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

@objc protocol CommandDownloadDelegate{
    optional func downloadDidResolve(command:AnyObject)
    optional func downloadDidError(command:AnyObject)
}

class CommandDownload : NSOperation, NMSSHChannelDelegate{
    var delegate:CommandDownloadDelegate?
    var cg = CommandGenerator()
    var session:NMSSHSession = NMSSHSession()
    var app:AppsSupported
    var command:BasicCommand
    var path:String!
    var pathDownloaded:String!
    var error:NSError?
    
    init(session:NMSSHSession, app:AppsSupported, command: BasicCommand, path:String = "") {
        self.app = app
        self.path = path
        self.command = command
        self.session = session
    }
    
    override func main() {
        autoreleasepool { () -> () in
            var macFolder = self.path.stringByReplacingOccurrencesOfString(":", withString: "/").stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            var folders = macFolder.componentsSeparatedByString("/")
            var macAbsolute = macFolder.stringByReplacingOccurrencesOfString(folders.first!, withString: "")
            var tmpFile = NSTemporaryDirectory().stringByAppendingPathComponent(String(arc4random_uniform(UInt32(123))*arc4random_uniform(UInt32(123)))+".jpg")
            
            self.session.channel.downloadFile(macAbsolute, to: tmpFile, progress: {(a:UInt, b:UInt) -> Bool in
                if a == b{
                    self.pathDownloaded = tmpFile
                    self.delegate?.downloadDidResolve!(self)
                }
                return true
            })
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