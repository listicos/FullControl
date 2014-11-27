//
//  MasterView.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 19/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

import UIKit

class MasterView:UIViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        UIGraphicsBeginImageContext(self.view.frame.size)
        var bg = UIImage(named: "bg")!
        bg.drawInRect(self.view.bounds)
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.view.backgroundColor = UIColor(patternImage: image.applyDarkEffect())
        */
        //var color: UIColor = UIColor(red: CGFloat(0.114), green: CGFloat(0.463), blue: CGFloat(0.475), alpha: CGFloat(1.0))
        //self.view.backgroundColor = color
        self.view.backgroundColor = UIColor.blackColor()
    }
}