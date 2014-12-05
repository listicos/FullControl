//
//  MainVC.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 02/12/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

class MainVC:AMSlideMenuMainViewController{
    
    override func segueIdentifierForIndexPathInLeftMenu(indexPath: NSIndexPath!) -> String! {
        var identifier = "";
        switch indexPath.row{
        case 0:
            identifier = "iTunes";
            break;
        case 1:
            identifier = "Keynote";
            break;
        default:
            break
        }
        return identifier;
    }
    
    override func leftMenuWidth() -> CGFloat {
        return 190
    }
/*
    override func configureLeftMenuButton(button: UIButton!) {
        var frame = button.frame;
        frame = CGRectMake(0, 20, 25, 13);
        button.frame = frame;
        button.backgroundColor = UIColor.clearColor()
        button.setImage(UIImage(named: "simpleMenuButton"), forState: .Normal)
    }
  */
    override func configureSlideLayer(layer: CALayer!) {
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.shadowRadius = 10
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: self.view.layer.bounds, cornerRadius: 0).CGPath
    }
    override func openAnimationCurve() -> UIViewAnimationOptions {
        return UIViewAnimationOptions.CurveEaseOut
    }
    
    override func closeAnimationCurve() -> UIViewAnimationOptions {
        return UIViewAnimationOptions.CurveEaseOut
    }
    
    override func primaryMenu() -> AMPrimaryMenu {
        return AMPrimaryMenuLeft
    }
    
    override func deepnessForLeftMenu() -> Bool {
        return true
    }
    
    override func maxDarknessWhileLeftMenu() -> CGFloat {
        return 0.1
    }
}