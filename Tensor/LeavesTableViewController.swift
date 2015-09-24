//
//  LeavesTableViewController.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/5/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit
import Parse

class LeavesTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var tasks = [Action]()
    
    // MARK: - Methods
    
    func fetchTasks() {
        let resultsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [Action] {
                    self.tasks = objects
                    dispatch_async(dispatch_get_main_queue()) { self.tableView.reloadData() }
                }
            } else {
            }
        }
        
        if PFUser.currentUser()?.objectId != nil {
            let query = PFQuery(className:"Action")
            query.fromLocalDatastore()
            query.whereKey("isLeaf", equalTo: 1)
            query.whereKey("completionStatus", equalTo: Action.CompletionStatus.InProgress.rawValue)
            query.whereKey("user", equalTo: PFUser.currentUser()!)
            query.findObjectsInBackgroundWithBlock(resultsBlock)
        }
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        fetchTasks()
        
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "actionDidPin:",
            name: LocalParseManager.Notification.LocalDatastoreDidAddAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "actionDidFailToPin:",
            name: LocalParseManager.Notification.LocalDatastoreDidFailToAddAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "actionDidUpdate:",
            name: LocalParseManager.Notification.LocalDatastoreDidUpdateAction,
            object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
    }
    
    // MARK: - Notifications
    
    func actionDidPin(notification: NSNotification) {
        print("\n\nLeaves.actionDidPin: \(notification)\n")
        fetchTasks()
    }
    
    func actionDidFailToPin(notification: NSNotification) {
        print("\n\nLeaves.actionDidFailToPin: \(notification)")
    }
    
    func actionDidUpdate(notification: NSNotification) {
        print("\n\nLeaves.actionDidUpdate: \(notification)")
        fetchTasks()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // #warning Incomplete implementation, return the number of rows
        return tasks.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Task Cell", forIndexPath: indexPath) as! PlanTableViewTaskCell
        
        // Configure the cell...
        cell.task = tasks[indexPath.row]
        
        return cell
    }}
