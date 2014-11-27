//
//  MainView.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 20/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

import UIKit

class DefaultView: MasterView, CommandDelegate,  NMSSHSessionDelegate, NMSSHChannelDelegate{
    
    @IBOutlet weak var volumen: UISlider!
    
    @IBOutlet weak var backward: UIButton!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var forward: UIButton!
    @IBOutlet weak var volumenUp: UIButton!
    @IBOutlet weak var volumenDown: UIButton!
    @IBOutlet weak var track: UILabel!
    @IBOutlet weak var artist: UILabel!
    @IBOutlet weak var progress: UISlider!
    @IBOutlet weak var timeLeft: UILabel!
    @IBOutlet weak var timeRight: UILabel!
    
    var lastVolumen = -1
    var session:NMSSHSession = NMSSHSession()
    let queue = NSOperationQueue()
    var refreshTimer:NSTimer!
    
    var fontBig = UIFont(name: "FontAwesome",size: 32)
    var fontMedium = UIFont(name: "FontAwesome",size: 17)
    
    var state = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.backward.titleLabel?.font = self.fontBig
        self.backward.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-backward"), forState: .Normal)
        
        self.play.titleLabel?.font = self.fontBig
        self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-play"), forState: .Normal)
        
        self.forward.titleLabel?.font = self.fontBig
        self.forward.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-forward"), forState: .Normal)
        
        self.volumenUp.titleLabel?.font = self.fontMedium
        self.volumenUp.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-volume-up"), forState: .Normal)

        self.volumenDown.titleLabel?.font = self.fontMedium
        self.volumenDown.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-volume-off"), forState: .Normal)
        
        let imageSmall = UIImage(named: "sliderThumb")
        var sizes = imageSmall?.size
        let size = CGSizeApplyAffineTransform(sizes!, CGAffineTransformMakeScale(0.3, 0.3))
        
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        imageSmall?.drawInRect(CGRect(origin: CGPointZero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        self.progress.setThumbImage(scaledImage, forState: .Normal)

        let imageMedium = UIImage(named: "sliderThumb")
        let sizesMedium = imageMedium?.size
        let sizeMedium = CGSizeApplyAffineTransform(sizesMedium!, CGAffineTransformMakeScale(0.5, 0.5))
        
        UIGraphicsBeginImageContextWithOptions(sizeMedium, true, 0.0)
        imageMedium?.drawInRect(CGRect(origin: CGPointZero, size: sizeMedium))
        let scaledImageMedium = UIGraphicsGetImageFromCurrentImageContext()
        self.volumen.setThumbImage(scaledImageMedium, forState: .Normal)
        
        
        refreshTrack()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.executeCommand(.Info)
        self.refreshTimer?.invalidate()
        self.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("refreshTrack"), userInfo: nil, repeats: true)
        super.viewWillAppear(animated)
    }
    
    @IBAction func volumeChange(sender: UISlider) {
        var volumenValue = Int(sender.value)
        
        if(abs(volumenValue - self.lastVolumen) > 9 || (volumenValue == 0 && self.lastVolumen != 0) || (volumenValue == 100 && self.lastVolumen != 100)){
            self.lastVolumen = volumenValue
            self.executeCommand(.Volume, extra: String(volumenValue))
        }
    }
    
    @IBAction func backward(sender: UIButton) {
        self.executeCommand(.Backward)
        refreshTrack()
    }
    
    @IBAction func playAction(sender: UIButton) {
        self.executeCommand(.Play)
        refreshTrack()
        if self.state == "paused" {
            self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-pause"), forState: .Normal)
        }else{
            self.play.setTitle(NSString.fontAwesomeIconStringForIconIdentifier("fa-play"), forState: .Normal)
        }
    }
    
    @IBAction func forwardAction(sender: UIButton) {
        self.executeCommand(.Forward)
        refreshTrack()
    }
    
    var lastOperation:NSOperation?
    
    func executeCommand(command:BasicCommand, extra:String = ""){
        let c = Command(session: self.session, app:.iTunes, command: command, extra:extra)
        c.delegate = self
        
        if lastOperation != nil {
            c.addDependency(lastOperation!)
        }
        
        lastOperation = c
        self.queue.addOperation(c)
    }
    
    func refreshTrack(){
        self.executeCommand(.Info)
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
    
    func commandDidResolve(command: Command) {
        if command.command == .Info {
            NSOperationQueue.mainQueue().addOperationWithBlock({ () in
            self.track.text = command.response["track"]
            var titleAA:String = command.response["artist"]!
                titleAA += " - "
                titleAA += command.response["album"]!
            
            self.artist.text = titleAA
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
            })
        }
    }
    
    func commandDidError(command: Command){
        println("Error!!")
    }
}