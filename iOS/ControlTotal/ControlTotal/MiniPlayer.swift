//
//  MiniPlayer.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 09/12/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

class MiniPlayer:UIView, CommandDelegate,  NMSSHSessionDelegate, NMSSHChannelDelegate, CommandDownloadDelegate{
    var fontBig = UIFont(name: "FontAwesome",size: 28)
    var fontLabel = UIFont(name: "HelveticaNeue",size: 11)
    var fontLabelBold = UIFont(name: "HelveticaNeue-Bold",size: 11)

    var cover = UIImage(named: "CoverDefaultMini.png")
    var artworkDefault = UIImage(named: "CoverDefaultMini.png")

    var play = UIButton()
    var backward = UIButton()
    var next = UIButton()
    
    var track = UILabel()
    var artist = UILabel()
    
    var sessionInstance = Session.sharedInstance

    var disabledCounter = 0
    
    let CONTROL_DIAMETER:CGFloat = 36
    var coverImageView:UIImageView!
        
    override init() {
        super.init()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
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

        backward.frame = CGRectMake(self.frame.width - CONTROL_DIAMETER*3-20, self.frame.height/2-(CONTROL_DIAMETER/2), CONTROL_DIAMETER, CONTROL_DIAMETER)
        play.frame = CGRectMake(self.frame.width-CONTROL_DIAMETER*2 - 11, self.frame.height/2-(CONTROL_DIAMETER/2), CONTROL_DIAMETER, CONTROL_DIAMETER)
        next.frame = CGRectMake(self.frame.width-CONTROL_DIAMETER - 7, self.frame.height/2 - (CONTROL_DIAMETER/2), CONTROL_DIAMETER, CONTROL_DIAMETER)
        
        track.font = self.fontLabelBold
        track.textColor = UIColor.whiteColor()
        track.frame = CGRectMake(50, 10, 145, 15)
        
        artist.font = self.fontLabel
        artist.textColor = UIColor.whiteColor()
        artist.frame = CGRectMake(50, 25, 145, 15)
        
        var coverView = UIView(frame: CGRectMake(5, 5, 50, 50))
        self.coverImageView = UIImageView(image: self.cover)
        self.coverImageView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        coverView.addSubview(self.coverImageView)
        self.addSubview(coverView)
        
        self.addSubview(play)
        self.addSubview(backward)
        self.addSubview(next)
        
        self.addSubview(track)
        self.addSubview(artist)
        refresh()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func play(sender:UIButton){
        self.disabledCounter = 1
        NSOperationQueue.mainQueue().addOperationWithBlock({ () in
            if self.sessionInstance.musicState == "paused" {
                self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-pause"), forState: .Normal)
            }else{
                self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-play"), forState: .Normal)
            }
        })
        self.executeCommand(.Play)
        self.executeCommand(.Info)
    }
    
    func refresh(){
        NSOperationQueue.mainQueue().addOperationWithBlock({ () in
        self.refreshPlayerState()
        self.sessionInstance.refreshTimer?.invalidate()
        self.refreshTrack()
        self.sessionInstance.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: Selector("refreshTrack"), userInfo: nil, repeats: true)
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
    
    func refreshArtwork(){
        self.executeCommand(.Artwork, extra: "current track")
    }
    
    var lastArtist = ""
    func commandDidResolve(command: Command) {
        if command.command == .Info {
            if self.disabledCounter > 0{
                self.disabledCounter--
                return
            }
            NSOperationQueue.mainQueue().addOperationWithBlock({ () in
                self.sessionInstance.musicState = command.response["state"]!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                
                let track = command.response["track"]
                if track!.isEmpty {
                    self.track.text = ""
                }else{
                    self.track.text = track
                }
                
                var titleAA:String = command.response["artist"]!
                
                if titleAA.isEmpty{
                    self.artist.text = ""
                }else{
                    titleAA += " - "
                    titleAA += command.response["album"]!
                    self.artist.text = titleAA
                }
                if titleAA != self.lastArtist{
                    self.refreshArtwork()
                }
                self.lastArtist = titleAA
                
                self.refreshPlayerState()
            })
        }else if command.command == .Artwork{
            
            var macPath = (command.response["response"]! as NSString).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())

            if macPath != "false"{
                //Download file
                let c = CommandDownload(session: self.sessionInstance.session!, app:.iTunes, command: .DownloadArtwork, path:macPath)
                c.delegate = self
                if self.sessionInstance.lastOperation != nil{
                    c.addDependency(self.sessionInstance.lastOperation!)
                }
                self.sessionInstance.lastOperation = c
                self.sessionInstance.queue.addOperation(c)
            
            } else{
                NSOperationQueue.mainQueue().addOperationWithBlock({ () in
                    self.coverImageView?.image = self.artworkDefault
                    self.backgroundColor = UIColor.blackColor()
                })
            }
        }
    }
    
    func downloadDidResolve(command: CommandDownload) {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () in
            let imageArtwork = UIImage(named: command.pathDownloaded)
        
            let size = CGSizeApplyAffineTransform(self.frame.size, CGAffineTransformMakeScale(1, 1))
            UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
            imageArtwork!.drawInRect(CGRect(origin: CGPointZero, size: size))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            var tintColor = UIColor.blackColor()
        
            self.backgroundColor = UIColor(patternImage: scaledImage.applyBlurWithRadius(30, tintColor: tintColor.colorWithAlphaComponent(0.4), saturationDeltaFactor: 2, maskImage: nil))
            self.coverImageView?.image = imageArtwork
        })

    }
    
    func downloadDidError(command: AnyObject) {
        
    }
    
    func commandDidError(command: Command){
        println("Error mini malo: \(command.error)")
    }
}