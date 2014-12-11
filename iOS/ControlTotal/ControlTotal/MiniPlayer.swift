//
//  MiniPlayer.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 09/12/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

class MiniPlayer:UIView, CommandDelegate,  NMSSHSessionDelegate, NMSSHChannelDelegate{
    var fontBig = UIFont(name: "FontAwesome",size: 28)

    var play = UIButton()
    var backward = UIButton()
    var next = UIButton()
    var sessionInstance = Session.sharedInstance

    var disabledCounter = 0
    
    let CONTROL_DIAMETER:CGFloat = 36
    
    override func layoutSubviews() {
        backward.frame = CGRectMake(self.frame.width - CONTROL_DIAMETER*3-30, self.frame.height/2-(CONTROL_DIAMETER/2), CONTROL_DIAMETER, CONTROL_DIAMETER)
        play.frame = CGRectMake(self.frame.width-CONTROL_DIAMETER*2 - 15, self.frame.height/2-(CONTROL_DIAMETER/2), CONTROL_DIAMETER, CONTROL_DIAMETER)
        next.frame = CGRectMake(self.frame.width-CONTROL_DIAMETER - 7, self.frame.height/2 - (CONTROL_DIAMETER/2), CONTROL_DIAMETER, CONTROL_DIAMETER)
    }
    
    override init() {
        super.init()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        play.titleLabel?.font = self.fontBig
        play.titleLabel?.textColor = UIColor.whiteColor()
        play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-play"), forState: .Normal)
        play.addTarget(self, action: "play:", forControlEvents: .TouchUpInside)
        
        backward.titleLabel?.textColor = UIColor.whiteColor()
        backward.titleLabel?.font = self.fontBig
        backward.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-backward"), forState: .Normal)
        backward.addTarget(self, action: "backward:", forControlEvents: .TouchUpInside)
        
        next.titleLabel?.textColor = UIColor.whiteColor()
        next.titleLabel?.font = self.fontBig
        next.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-forward"), forState: .Normal)
        next.addTarget(self, action: "next:", forControlEvents: .TouchUpInside)
        
        self.addSubview(play)
        self.addSubview(backward)
        self.addSubview(next)
        refreshTrack()
    }
    func play(sender:UIButton){
        self.disabledCounter = 1
        NSOperationQueue.mainQueue().addOperationWithBlock({ () in
            println("PLAY STATE-->\(self.sessionInstance.musicState)")
            if self.sessionInstance.musicState == "paused" {
                self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-pause"), forState: .Normal)
            }else{
                self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-play"), forState: .Normal)
            }
        })
        self.executeCommand(.Play)
    }
    
    func refresh(){
        println("REFRESHING....")
        NSOperationQueue.mainQueue().addOperationWithBlock({ () in
        self.refreshPlayerState()
        self.sessionInstance.refreshTimer?.invalidate()
        self.sessionInstance.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: Selector("refreshTrack"), userInfo: nil, repeats: true)
        })
    }
    
    func refreshPlayerState(){
        NSOperationQueue.mainQueue().addOperationWithBlock({ () in
        if (self.sessionInstance.musicState == "playing") {
            self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-pause"), forState: .Normal)
        }else{
            self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-play"), forState: .Normal)
        }
        })
    }
    
    func backward(sender:UIButton){
        self.executeCommand(.Back)
        self.refreshTrack()
        
    }
    func next(sender:UIButton){
        self.executeCommand(.Next)
        self.refreshTrack()
    }
    
    func refreshTrack(){
        println("TAG:\(self.superview?.tag)")
        if self.sessionInstance.queue.operationCount == 0{
            self.executeCommand(.Info)
        }
    }
    
    func executeCommand(command:BasicCommand, extra:String = ""){
        let c = Command(session: self.sessionInstance.session!, app:.iTunes, command: command, extra:extra)
        c.delegate = self
        if self.sessionInstance.lastOperation != nil{
            c.addDependency(self.sessionInstance.lastOperation!)
        }
        self.sessionInstance.lastOperation = c
        self.sessionInstance.queue.addOperation(c)
    }
    
    func commandDidResolve(command: Command) {
        if command.command == .Info {
            if self.disabledCounter > 0{
                self.disabledCounter--
                return
            }
            NSOperationQueue.mainQueue().addOperationWithBlock({ () in
                self.sessionInstance.musicState = command.response["state"]!
                println("command did resolve:\(self.sessionInstance.musicState)")
                self.refreshPlayerState()
            })
        }
    }
    
    func commandDidError(command: Command){
        println("Error mini malo: \(command.error)")
    }
}