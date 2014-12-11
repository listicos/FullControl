//
//  LeftMenuVC.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 02/12/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

class LeftMenuVC:AMSlideMenuLeftTableViewController{
    var myTableView:UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
        //self.setFixedStatusBar()
    }
    
    func setFixedStatusBar(){
        self.myTableView = self.tableView
        self.view = UIView(frame: self.view.bounds)
        self.view.backgroundColor = self.myTableView?.backgroundColor
        self.view.addSubview(self.myTableView!)
        var statusBarView = UIView(frame: CGRectMake(0,0, max(self.view.frame.size.width, self.view.frame.size.height), 20))
        statusBarView.backgroundColor = UIColor.blackColor()
        self.view.addSubview(statusBarView)
    }
}