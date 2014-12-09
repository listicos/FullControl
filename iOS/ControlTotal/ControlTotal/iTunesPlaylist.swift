//
//  iTunesPlaylist.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 05/12/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

class iTunesPlaylist:UIViewController, UITableViewDataSource, UITableViewDelegate, CommandDelegate{
    var session:NMSSHSession?
    let queue = NSOperationQueue()
    var playlist:[[String]] = []
    
    @IBOutlet weak var tableView: UITableView!
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        self.tableView.addSubview(refreshControl)
        self.refreshControl.beginRefreshing()
        self.tableView.setContentOffset(CGPointMake(0, self.tableView.contentOffset.y-self.refreshControl.frame.size.height), animated: true)
        self.session = Session.sharedInstance.session
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.executeCommand(.Playlists)
    }
    
    func refresh(refreshControl: UIRefreshControl){
        self.executeCommand(.Playlists)
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
        if command.command == .Playlists{
            self.playlist = []
            var playlistString = command.response["response"]!
            var playlistArray:[String] = playlistString.componentsSeparatedByString("\n")
            for track in playlistArray{
                if !track.isEmpty{
                    var trackInfo = track.componentsSeparatedByString("|@|")
                    if trackInfo.count == 4{
                        self.playlist.append(trackInfo)
                    }
                }
            }
            NSOperationQueue.mainQueue().addOperationWithBlock({ () in
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
            })
        }
    }
    
    func commandDidError(command: Command) {
        println("Error \(command.response)")
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        cell.textLabel?.text =  self.playlist[indexPath.row][0]
        var type =  self.playlist[indexPath.row][1]
        let imageSmall = Icons.get(type)
        var sizes = imageSmall.size
        let size = CGSizeApplyAffineTransform(sizes, CGAffineTransformMakeScale(0.5, 0.5))
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        imageSmall.drawInRect(CGRect(origin: CGPointZero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        cell.imageView?.image = scaledImage
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlist.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("Songs", sender: self.playlist[indexPath.row][3])
//        self.executeCommand(.Playtrack, extra: "\(self.playlist[indexPath.row][1])")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Songs"{
            var songs = segue.destinationViewController as iTunesSongs
            songs.playlistNumber = sender as String
        }
    }
    
}