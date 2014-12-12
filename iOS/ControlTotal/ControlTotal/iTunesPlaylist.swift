//
//  iTunesPlaylist.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 05/12/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

class iTunesPlaylist:UIViewController, UITableViewDataSource, UITableViewDelegate, CommandDelegate{
    var session:NMSSHSession?
    var queue:NSOperationQueue?
    var lastOperation:NSOperation?
    
    var playlist:[[String]] = []

    @IBOutlet weak var tableView: UITableView!
   // @IBOutlet var miniMediaPlayer: MiniPlayer?
    var miniMediaPlayer:MiniPlayer!
    
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        self.tableView.addSubview(refreshControl)
        self.refreshControl.beginRefreshing()
        self.tableView.setContentOffset(CGPointMake(0, self.tableView.contentOffset.y-self.refreshControl.frame.size.height), animated: true)
        self.session = Session.sharedInstance.session
        self.queue = Session.sharedInstance.queue
        self.lastOperation = Session.sharedInstance.lastOperation
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.executeCommand(.Playlists)
        self.title = "Playlists"
        
        self.miniMediaPlayer = MiniPlayer(frame: CGRectMake(0, self.view.frame.height-100, self.view.frame.width, 50))
        self.miniMediaPlayer.backgroundColor = UIColor.blackColor()
        self.view.addSubview(self.miniMediaPlayer)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.miniMediaPlayer?.frame = CGRectMake(0, self.view.frame.height-100, self.view.frame.width, 50)
        self.view.addSubview(self.miniMediaPlayer!)
    }
    
    
    func refresh(refreshControl: UIRefreshControl){
        self.executeCommand(.Playlists)
    }
    
    func executeCommand(command:BasicCommand, extra:String = ""){
        let c = Command(session: self.session!, app:.iTunes, command: command, extra:extra)
        c.delegate = self
        if lastOperation != nil{
            c.addDependency(lastOperation!)
        }
        lastOperation = c
        self.queue?.addOperation(c)
    }
    func commandDidResolve(command: Command) {
        if command.command == .Playlists{
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
        self.performSegueWithIdentifier("Songs", sender: self.playlist[indexPath.row])
//        self.executeCommand(.Playtrack, extra: "\(self.playlist[indexPath.row][1])")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "Songs"{
            var dataSelected = sender as [String]
            var songs = segue.destinationViewController as iTunesSongs
            songs.title = dataSelected[0]
            songs.playlistNumber = dataSelected[3]
            songs.playlistClass = dataSelected[4]
            songs.miniPlayer = self.miniMediaPlayer
        }
    }
}