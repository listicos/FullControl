//
//  Login.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 18/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

import UIKit

class LoginView:MasterView, UITextFieldDelegate, NMSSHSessionDelegate, NMSSHChannelDelegate {
    
    let queue = NSOperationQueue()
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var login: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var closeButton: UIButton!

    var hostname:String = ""
    var ips = []
    var port:Int = 0

    var session:NMSSHSession = NMSSHSession()
    var sshQueue:dispatch_queue_t?
    var onceToken:dispatch_once_t = 0
    var semaphore:dispatch_semaphore_t?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.queue.name = "ssh"
        var color: UIColor = UIColor(red: CGFloat(0.8), green: CGFloat(0.8), blue: CGFloat(0.8), alpha: CGFloat(1.0))

        let attributesDictionary = [NSForegroundColorAttributeName: color]
        username.attributedPlaceholder = NSAttributedString(string: "Username", attributes: attributesDictionary)
        password.attributedPlaceholder = NSAttributedString(string: "Password", attributes: attributesDictionary)
        self.view.bringSubviewToFront(self.closeButton)
        
        self.username.delegate=self
        self.password.delegate=self
        
        var tap = UITapGestureRecognizer(target:self, action:"dismissKeyboard")
        self.view.addGestureRecognizer(tap)
        
        self.sshQueue = dispatch_queue_create("NMSSH.queue", DISPATCH_QUEUE_SERIAL)
        
        self.login.setTitle("Connecting...", forState: UIControlState.Disabled)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        println(segue.identifier)
    }
    
    func dismissKeyboard(){
        self.username.resignFirstResponder()
        self.password.resignFirstResponder()
    }
    
    func registerForKeyboardNotifications(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWasShown (notification: NSNotification ) {
        var  info:NSDictionary = notification.userInfo!
    
        var keyboardSize = info.objectForKey(UIKeyboardFrameBeginUserInfoKey)?.CGRectValue().size
        
        var buttonOrigin = self.login.frame.origin
        var buttonHeight = self.login.frame.size.height
        var visibleRect = self.view.frame
        let keyboardHeight = keyboardSize?.height
        visibleRect.size.height -= keyboardHeight!
        
        if (!CGRectContainsPoint(visibleRect, buttonOrigin)){
            var scrollPoint:CGPoint = CGPointMake(0.0, buttonOrigin.y - visibleRect.size.height + buttonHeight)
            self.scrollView?.setContentOffset(scrollPoint, animated: true)
            self.view.bringSubviewToFront(self.closeButton)
            
            //Hide close button
            UIView.animateWithDuration(0.3,
                delay: 0,
                options: .CurveLinear & .AllowUserInteraction & .BeginFromCurrentState,
                animations: {
                    self.closeButton.alpha = 0
                }, completion: nil)
        }
    }
    
    func keyboardWillBeHidden (notification: NSNotification ) {
        self.scrollView.setContentOffset(CGPoint.zeroPoint, animated: true)
        self.closeButton.alpha = 1
    }
    
    func deregisterFromKeyboardNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIKeyboardDidHideNotification, object:nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:UIKeyboardWillHideNotification, object:nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        deregisterFromKeyboardNotifications()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        registerForKeyboardNotifications()
    }
    
    
    @IBAction func close(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func login(sender: UIButton) {
        loginAction()
    }
    
    func loginAction(){
        var ip:String = ips[0] as String
        
        var cp:Dictionary<String, String> = ConnectionParameters
        cp["ip"] = ip
        cp["password"] = self.password.text
        cp["username"] = self.username.text
        
        var pStorage = ConnectionProperties()
        pStorage.sessionParams = cp
        
        self.login.enabled = false
        var con = Connection()
        self.queue.addOperations([con], waitUntilFinished: true)
        self.login.enabled = true
        
        if(con.authorized){
            var mainControlView = self.storyboard?.instantiateViewControllerWithIdentifier("MainNavigation") as UINavigationController
            Session.sharedInstance.session = con.session
            self.presentViewController(mainControlView, animated: true, completion: nil)
        }else{
            let alert = UIAlertView()
            alert.title = "Error"
            alert.message = "Please check your credentials"
            alert.addButtonWithTitle("OK")
            alert.show()
        }
    }
    
    func session(session: NMSSHSession!, didDisconnectWithError error: NSError!) {
        println("DidDisconnectWithError",error)
    }
    
    //Keyboard delegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool{
        if (textField === self.username) {
            self.password.becomeFirstResponder()
        }else if (textField === self.password) {
            self.password.resignFirstResponder()
            loginAction()
        }
        return true;
    }
}