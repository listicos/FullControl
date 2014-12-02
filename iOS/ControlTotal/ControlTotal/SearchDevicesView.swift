//
//  ViewController.swift
//  ControlTotal
//
//  Created by Ruben Velazquez Calva on 13/11/14.
//  Copyright (c) 2014 listico. All rights reserved.
//

import UIKit

class SearchDevicesView: MasterView,  NSNetServiceBrowserDelegate, NSNetServiceDelegate, UITableViewDataSource, UITableViewDelegate {
    
    let BM_DOMAIN = "local."
    let BM_TYPE = "_ssh._tcp."
    let nsb = NSNetServiceBrowser()
    var services = [NSNetService]()
    var myService = NSNetService()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        nsb.delegate = self
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.rowHeight = 70
        super.viewDidLoad()
        
        nsb.searchForServicesOfType(BM_TYPE, inDomain: BM_DOMAIN)
    }
    
    @IBAction func doRefresh(sender: UIRefreshControl) {
        sender.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func netServiceBrowserWillSearch(aNetServiceBrowser: NSNetServiceBrowser!){
        println("netServiceBrowserWillSearch")
    }
    
    func netServiceBrowserDidStopSearch(aNetServiceBrowser: NSNetServiceBrowser!){
        println("netServiceBrowserDidStopSearch")
    }
    
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser!, didNotSearch errorDict: NSDictionary!){
        println("netServiceBrowser:didNotSearch \(aNetServiceBrowser) \(errorDict)")
    }
    
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser!, didFindDomain domainString: String!, moreComing: Bool){
        println("netServiceBrowser:didFindDomain")
    }
    
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser!, didFindService aNetService: NSNetService!, moreComing: Bool){
        println(aNetService.domain)
        println(aNetService.name)
        println(aNetService.type)
        println(aNetService.port)
        println(aNetService.hostName)
        
        println("netServiceBrowser:didFindService \(aNetService) moreComing:\(moreComing)")
        self.services.append(aNetService)
        self.tableView.reloadData()
    }
    
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser!, didRemoveDomain domainString: String!, moreComing: Bool){
        println("netServiceBrowser:didRemoveDomain")
    }
    
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser!, didRemoveService aNetService: NSNetService!, moreComing: Bool){
        println("netServiceBrowser:didRemoveService \(aNetService)")
        for i in 0..<services.count {
            if (services[i] == aNetService) {
                services.removeAtIndex(i);
                println("removed !");
            }
        }
    }
    
    func netService(sender: NSNetService, didNotResolve errorDict: [NSObject : AnyObject]) {
        println("didNotResolve")
        println(errorDict)
    }
    func netServiceBrowser(aNetServiceBrowser: NSNetServiceBrowser, didNotSearch errorDict: [NSObject : AnyObject]) {
        println("didNotSearch")
        println(errorDict)
    }
    func netServiceBrowserDidStopSearch(aNetServiceBrowser: NSNetServiceBrowser) {
        println("DidStopSearch")
    }
    func netServiceDidStop(sender: NSNetService) {
        println("DidStop")
    }
    
    func netService(sender: NSNetService, didNotPublish errorDict: [NSObject : AnyObject]) {
        println("didNotPublish")
    }
    
    func netServiceDidResolveAddress(sender: NSNetService) {
        println("netServiceDidResolveAddress")
        self.myService.stop()
        if let addresses = sender.addresses
        {
            var ips: [String] = []
            for address in addresses{
                let ptr = UnsafePointer<sockaddr_in>(address.bytes)
                var addr = ptr.memory.sin_addr
                var buf = UnsafeMutablePointer<Int8>.alloc(Int(INET6_ADDRSTRLEN))
                var family = ptr.memory.sin_family
                var ipc = UnsafePointer<Int8>()
                if family == __uint8_t(AF_INET){
                    ipc = inet_ntop(Int32(family), &addr, buf, __uint32_t(INET6_ADDRSTRLEN))
                    if let ip = String.fromCString(ipc){
                        ips.append(ip)
                    }
                }
                /*For MAC
                else if family == __uint8_t(AF_INET6){
                    let ptr6 = UnsafePointer<sockaddr_in6>(address.bytes)
                    var addr6 = ptr6.memory.sin6_addr
                    family = ptr6.memory.sin6_family
                    ipc = inet_ntop(Int32(family), &addr6, buf, __uint32_t(INET6_ADDRSTRLEN))
                }*/
            }
            self.loginView.port = sender.port
            self.loginView.ips = ips
        }
    }
    
    //Table protocol

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        var cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        cell.textLabel?.text =  self.services[indexPath.row].name
        cell.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.0)
        cell.textLabel?.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    var loginView:LoginView = LoginView()
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var count = self.services.count
        if (count != 0) {
            self.myService = self.services[indexPath.row] as NSNetService
            self.myService.delegate = self;
            self.myService.resolveWithTimeout(0.0)
        }
        
        loginView = self.storyboard?.instantiateViewControllerWithIdentifier("Login") as LoginView
        loginView.hostname = self.services[indexPath.row].name
        self.presentViewController(loginView, animated: true, completion: nil)
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}