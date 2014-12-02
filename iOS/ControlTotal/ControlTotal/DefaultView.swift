//
//  MainView.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 20/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

import UIKit

class DefaultView: MasterView, CommandDelegate,  NMSSHSessionDelegate, NMSSHChannelDelegate, StarRatingDelegate{
    
    @IBOutlet weak var volumen: UISlider!
    @IBOutlet weak var backward: UIButton!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var next: UIButton!
    @IBOutlet weak var visuals: UIButton!
    @IBOutlet weak var volumenUp: UIButton!
    @IBOutlet weak var volumenDown: UIButton!
    @IBOutlet weak var track: UILabel!
    @IBOutlet weak var artist: UILabel!
    @IBOutlet weak var progress: UISlider!
    @IBOutlet weak var timeLeft: UILabel!
    @IBOutlet weak var timeRight: UILabel!
    @IBOutlet weak var rating: StarRatingControl!
    @IBOutlet weak var artworkImage: UIImageView!
    
    var lastVolumen = -1
    var session:NMSSHSession = NMSSHSession()
    let queue = NSOperationQueue()
    var refreshTimer:NSTimer!
    var disabledCounter:Int = 0
    
    var fontBig = UIFont(name: "FontAwesome",size: 32)
    var fontMedium = UIFont(name: "FontAwesome",size: 22)
    var fontSmall = UIFont(name: "FontAwesome",size: 15)
    
    var state = ""
    var visualsState:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.rating.delegate = self
        self.backward.titleLabel?.font = self.fontBig
        self.backward.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-backward"), forState: .Normal)
        
        self.play.titleLabel?.font = self.fontBig
        self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-play"), forState: .Normal)
        
        self.next.titleLabel?.font = self.fontBig
        self.next.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-forward"), forState: .Normal)
        
        self.volumenUp.titleLabel?.font = self.fontSmall
        self.volumenUp.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-volume-up"), forState: .Normal)

        self.volumenDown.titleLabel?.font = self.fontSmall
        self.volumenDown.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-volume-off"), forState: .Normal)
        
        self.visuals.titleLabel?.font = self.fontMedium
        self.visuals.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-expand"), forState: .Normal)

        let imageSmall = UIImage(named: "sliderThumb")
        var sizes = imageSmall?.size
        let size = CGSizeApplyAffineTransform(sizes!, CGAffineTransformMakeScale(0.3, 0.3))
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        imageSmall?.drawInRect(CGRect(origin: CGPointZero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        self.progress.setThumbImage(scaledImage, forState: .Normal)

        let imageMedium = UIImage(named: "sliderThumb")
        let sizesMedium = imageMedium?.size
        let sizeMedium = CGSizeApplyAffineTransform(sizesMedium!, CGAffineTransformMakeScale(0.5, 0.5))
        
        UIGraphicsBeginImageContextWithOptions(sizeMedium, false, 0.0)
        imageMedium?.drawInRect(CGRect(origin: CGPointZero, size: sizeMedium))
        let scaledImageMedium = UIGraphicsGetImageFromCurrentImageContext()
        self.volumen.setThumbImage(scaledImageMedium, forState: .Normal)
        
        refreshTrack()
        refreshArtwork()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.executeCommand(.Info)
        self.refreshTimer?.invalidate()
        self.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: Selector("refreshTrack"), userInfo: nil, repeats: true)
        super.viewWillAppear(animated)
    }
    
    @IBAction func visualsAction(sender: UIButton) {
        self.disabledCounter = 1
        if self.visualsState == "1"{
            self.visuals.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-expand"), forState: .Normal)
        }else{
            self.visuals.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-compress"), forState: .Normal)
        }
        self.executeCommand(.Visuals)

    }
    
    func starRatingControl(control: StarRatingControl!, didUpdateRating rating: UInt) {
        self.disabledCounter = 1
        var nRating = 1
        if rating > 0{
            nRating = Int(rating)*20
        }
        self.executeCommand(.Rating, extra: String(nRating))
    }
    
    func starRatingControl(control: StarRatingControl!, willUpdateRating rating: UInt) {
        self.disabledCounter = 1
    }
    
    @IBAction func volumeChange(sender: UISlider) {
        var volumenValue = Int(sender.value)
        
        if(abs(volumenValue - self.lastVolumen) > 9 || (volumenValue == 0 && self.lastVolumen != 0) || (volumenValue == 100 && self.lastVolumen != 100)){
            self.lastVolumen = volumenValue
            self.disabledCounter = 2
            self.executeCommand(.Volume, extra: String(volumenValue))
        }
    }

    @IBAction func volumeDidFinishChange(sender: UISlider) {
        var volumenValue = Int(sender.value)
        self.executeCommand(.Volume, extra: String(volumenValue))
    }
    
    var rewindStartTime:NSDate?
    var rewindTimer:NSTimer?
    
    @IBAction func backward(sender: UIButton) {
        self.rewindTimer!.invalidate()
        var currentTime = NSDate()
        var elapsedTime = currentTime.timeIntervalSinceDate(self.rewindStartTime!)
        if(elapsedTime<1){
            self.progress.value = 0.0
            self.timeLeft.text = "00:00"
            self.executeCommand(.Back)
            refreshTrack()
        }
    }
    
    @IBAction func rewindBegan(sender: UIButton) {
        self.rewindStartTime = NSDate()
        self.rewindTimer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: Selector("rewind"), userInfo: nil, repeats: true)
    }
    
    func rewind(){
        var currentTime = NSDate()
        var elapsedTime = currentTime.timeIntervalSinceDate(self.rewindStartTime!)*10.0
        self.executeCommand(.Rewind, extra: elapsedTime.description)
        refreshTrack()
    }
    
    var lastJump:NSDate?
    var jumpTimer:NSTimer?
    var lastJumpValue:Float = -1
    
    @IBAction func JumpInTrack(sender: UISlider) {
        self.lastJump = NSDate()
        self.jumpTimer?.invalidate()
        self.lastJumpValue = sender.value
        self.disabledCounter = 1
        self.progressTimer?.invalidate()
        self.jumpTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: Selector("toJumpTrack"), userInfo: nil, repeats: true)
    }
    
    func toJumpTrack(){
        var currentTime = NSDate()
        var elapsedTime = currentTime.timeIntervalSinceDate(self.lastJump!)
        if(elapsedTime > 0.2){
            self.executeCommand(.Jump, extra: self.lastJumpValue.description)
            self.refreshTrack()
            self.jumpTimer?.invalidate()
        }
    }
    
    @IBAction func playAction(sender: UIButton) {
        if self.state == "paused" {
            self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-pause"), forState: .Normal)
        }else{
            self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-play"), forState: .Normal)
        }
        self.disabledCounter = 1
        self.executeCommand(.Play)
        refreshTrack()
    }
    
    @IBAction func forwardAction(sender: UIButton) {
        self.forwardTimer!.invalidate()
        var currentTime = NSDate()
        var elapsedTime = currentTime.timeIntervalSinceDate(self.forwardStartTime!)
        if(elapsedTime < 1){
            self.progress.value = 0.0
            self.timeLeft.text = "00:00"
            self.executeCommand(.Next)
            refreshTrack()
        }
    }
    
    var forwardStartTime:NSDate?
    var forwardTimer:NSTimer?
    
    @IBAction func forwardBegan(sender: UIButton) {
        self.forwardStartTime = NSDate()
        self.forwardTimer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: Selector("forward"), userInfo: nil, repeats: true)
    }
    
    func forward(){
        var currentTime = NSDate()
        var elapsedTime = currentTime.timeIntervalSinceDate(self.forwardStartTime!)*10.0
        self.executeCommand(.Forward, extra: elapsedTime.description)
        refreshTrack()
    }
    
    var lastOperation:NSOperation?
    
    func executeCommand(command:BasicCommand, extra:String = ""){
        let c = Command(session: self.session, app:.iTunes, command: command, extra:extra)
        c.delegate = self
        if lastOperation != nil{
            c.addDependency(lastOperation!)
        }
        lastOperation = c
        self.queue.addOperation(c)
    }
    
    func refreshTrack(){
        if self.queue.operationCount <= 1{
            self.executeCommand(.Info)
        }
    }
    
    func refreshArtwork(){
        self.executeCommand(.Artwork, extra: "current track")
    }
    
    var currentTime:Float = 0
    var totalTime:Float = 0
    var currentTimeDate:NSDate?
    var totalTimeDate:NSDate?
    
    func setTrackTime(currentMinutes:String, currentSeconds:String, totalMinutes:String, totalSeconds:String){
        if(!currentSeconds.isEmpty && !currentMinutes.isEmpty && !totalMinutes.isEmpty && !totalSeconds.isEmpty){
            var cm = currentMinutes as NSString
            var cs = currentSeconds as NSString
            var tm = totalMinutes as NSString
            var ts = totalSeconds as NSString
            
            var newCurrentTime = cm.floatValue*60+cs.floatValue
            if(abs(newCurrentTime-self.currentTime)>=1){
                self.currentTime = newCurrentTime
            }
            self.totalTime = tm.floatValue*60+ts.floatValue
            
            self.currentTimeDate = NSDate(dateString: currentMinutes+":"+String(cs.intValue), format: "mm:ss")
            self.totalTimeDate = NSDate(dateString: totalMinutes+":"+String(ts.intValue), format: "mm:ss")
            self.generateProgressBarTimer()
            self.refreshProgressBar()
        }
    }
    var progressTimer:NSTimer?
    
    func generateProgressBarTimer(){
        self.progressTimer?.invalidate()
        self.progressTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("refreshProgressBar"), userInfo: nil, repeats: true)
    }
    
    func refreshProgressBar(){
        if self.state != "playing" {
            return
        }
        NSOperationQueue.mainQueue().addOperationWithBlock({ () in
            self.progress.maximumValue = self.totalTime
            self.progress.value = self.currentTime
            self.currentTime+=1
            
            var dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "mm:ss"
            self.timeLeft.text = dateFormatter.stringFromDate(self.currentTimeDate!)
            self.timeRight.text = dateFormatter.stringFromDate(self.totalTimeDate!)
            if(!self.totalTimeDate!.isEqualToDate(self.currentTimeDate!)){
                self.currentTimeDate = self.currentTimeDate?.dateByAddingTimeInterval(NSTimeInterval(1))
            }
        })
    }
    
    var lastArtist = ""
    var artworkDefault = UIImage(named: "CoverDefault.png")
    var bgDefault = UIImage(named: "bg.jpg")
    
    func commandDidResolve(command: Command) {
        if command.command == .Info {
            if self.disabledCounter > 0{
                self.disabledCounter--
                return
            }
            NSOperationQueue.mainQueue().addOperationWithBlock({ () in
            var rating = command.response["rating"]! as NSString
            self.rating.rating = UInt(rating.integerValue)/20
                let track = command.response["track"]
                if track!.isEmpty {
                    self.track.text = "No track"
                }else{
                    self.track.text = track
                }
            
            var titleAA:String = command.response["artist"]!
                titleAA += " - "
                titleAA += command.response["album"]!
            
            self.artist.text = titleAA
                
                if titleAA != self.lastArtist{
                    self.refreshArtwork()
                }
            self.lastArtist = titleAA
            
        
            let volumeString = command.response["volume"]! as NSString
            let volume = volumeString.floatValue
            self.volumen.value = volume
            
            self.setTrackTime(command.response["currentMinutes"]!, currentSeconds: command.response["currentSeconds"]!, totalMinutes: command.response["totalMinutes"]! , totalSeconds: command.response["totalSeconds"]!)
            
            self.state = command.response["state"]!
                
                if self.state == "playing" {
                    self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-pause"), forState: .Normal)
                }else{
                    self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-play"), forState: .Normal)
                }
                
            self.visualsState = command.response["visuals"]!
                if self.visualsState == "0"{
                    self.visuals.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-expand"), forState: .Normal)
                }else{
                    self.visuals.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-compress"), forState: .Normal)
                }
            })
        }else if command.command == .Artwork{
            
            var macPath = command.response["response"]! as NSString
            
            if macPath != "false"{
                var macFolder = macPath.stringByReplacingOccurrencesOfString(":", withString: "/").stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
                var folders = macFolder.componentsSeparatedByString("/")
                var macAbsolute = macFolder.stringByReplacingOccurrencesOfString(folders.first!, withString: "")
                var tmpFile = NSTemporaryDirectory().stringByAppendingPathComponent(String(arc4random_uniform(UInt32(123))*arc4random_uniform(UInt32(123))))
                self.session.channel.downloadFile(macAbsolute, to: tmpFile, progress: {(a:UInt, b:UInt) -> Bool in
                    if a == b{
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () in
                            let imageArtwork = UIImage(named: tmpFile)
                            
                            let size = CGSizeApplyAffineTransform(self.view.frame.size, CGAffineTransformMakeScale(1, 1))
                            
                            UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
                            imageArtwork!.drawInRect(CGRect(origin: CGPointZero, size: size))
                            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
                            var tintColor = UIColor.blackColor()
                            
                            self.view.backgroundColor = UIColor(patternImage: scaledImage.applyBlurWithRadius(30, tintColor: tintColor.colorWithAlphaComponent(0.4), saturationDeltaFactor: 2, maskImage: nil))
                            self.artworkImage.image = imageArtwork
                        })
                    }
                    return true
                })
 
            }else{
                NSOperationQueue.mainQueue().addOperationWithBlock({ () in
                    self.artworkImage.image = self.artworkDefault
                    UIGraphicsBeginImageContext(self.view.frame.size)
                    self.bgDefault!.drawInRect(self.view.bounds)
                    var image = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    self.view.backgroundColor = UIColor(patternImage: image.applyLightEffect())
                })
            }
        }
    }
    
    func commandDidError(command: Command){
        println("Error!!")
    }
}