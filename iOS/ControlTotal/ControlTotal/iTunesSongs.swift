//
//  iTunesSongs.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 05/12/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

class iTunesSongs:UIViewController, UITableViewDataSource, UITableViewDelegate, CommandDelegate{
    var session:NMSSHSession?
    let queue = NSOperationQueue()
    var playlist:[[String]] = []
    
    @IBOutlet weak var tableView: UITableView!
    var refreshControl = UIRefreshControl()
    var playlistNumber = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        self.tableView.addSubview(refreshControl)
        self.refreshControl.beginRefreshing()
        self.tableView.setContentOffset(CGPointMake(0, self.tableView.contentOffset.y-self.refreshControl.frame.size.height), animated: true)
        self.session = Session.sharedInstance.session
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.executeCommand(.Songs, extra: self.playlistNumber)
    }
    
    func refresh(refreshControl: UIRefreshControl){
        self.executeCommand(.Songs, extra: "\(self.playlistNumber)")
    }
    
    var lastOperation:NSOperation?
    
    func executeCommand(command:BasicCommand, extra:String = ""){
        let c = Command(session: self.session!, app:.iTunes, command: command, extra:extra)
        c.delegate = self
        if lastOperation != nil{
            c.addDependency(lastOperation!)
        }
        lastOperation = c
        self.queue.addOperation(c)
    }
    func commandDidResolve(command: Command) {
        if command.command == .Songs{
            self.playlist = []
            var playlistString = command.response["response"]!
            var playlistArray:[String] = playlistString.componentsSeparatedByString("\n")
            for track in playlistArray{
                if !track.isEmpty{
                    var trackInfo = track.componentsSeparatedByString("|@|")
                    if trackInfo.count == 5{
                        self.playlist.append(trackInfo)
                    }
                }
            }
            NSOperationQueue.mainQueue().addOperationWithBlock({ () in
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
                /*if self.playlist.count == 0{
                    var messageLabel = UILabel(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
                    
                    messageLabel.text = "No data is currently available. Please pull down to refresh.";
                    messageLabel.textColor = UIColor.blackColor()
                    messageLabel.numberOfLines = 0
                    messageLabel.textAlignment = NSTextAlignment.Center;
                    messageLabel.font = UIFont(name: "Palatino-Italic", size: 25)
                    messageLabel.sizeToFit()
                    
                    self.tableView.backgroundView = messageLabel;
                    self.tableView.separatorStyle = .None;
                }*/
            })
        }
    }
    
    func commandDidError(command: Command) {
        println("Error \(command.response)")
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        cell.textLabel?.text =  self.playlist[indexPath.row][0]
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlist.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.executeCommand(.Playtrack, extra: "\(self.playlist[indexPath.row][4])")
    }

}