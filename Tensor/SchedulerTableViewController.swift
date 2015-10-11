//
//  SchedulerTableViewController.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/25/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit
import Parse

class SchedulerTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var scheduler: Scheduler?
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // fetch scheduler from local datastore
        // otherwise, create one 
        // -- don't wait to fetch it from network. 
        // UNLESS this is immediately after user authentication
        
        let sharedManager = LocalParseManager.sharedManager
        
        let resultBlock: PFObjectResultBlock = { (result, error) in
            if let scheduler = result as? Scheduler {
                self.scheduler = scheduler
            }
            else {
                let newScheduler = sharedManager.createScheduler()
                self.scheduler = newScheduler
            }
            
            if self.scheduler?.currentAction != nil {
                self.tableView.reloadData()
            }
            self.scheduler?.refreshScheduledActions()
        }
        
        sharedManager.fetchSchedulerInBackgroundWithBlock(resultBlock)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "schedulerDidRefreshScheduledActions:",
            name: Scheduler.Notification.SchedulerDidRefreshScheduledActions,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "schedulerDidFailToRefreshScheduledActions:",
            name: Scheduler.Notification.SchedulerDidFailToRefreshScheduledActions,
            object: nil)
    
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "localDatastoreDidChangeActions:",
            name: LocalParseManager.Notification.LocalDatastoreDidAddAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "localDatastoreDidChangeActions:",
            name: LocalParseManager.Notification.LocalDatastoreDidRemoveAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "localDatastoreDidChangeActions:",
            name: LocalParseManager.Notification.LocalDatastoreDidUpdateAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "localDatastoreDidChangeActions:",
            name: LocalParseManager.Notification.LocalDatastoreDidFetchActionsFromCloud,
            object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - IBActions
    
    @IBAction func skipButtonPressed(sender: UIBarButtonItem) {
        scheduler?.skip()
        self.tableView.reloadData()
    }
    
    // MARK: - Notifications
    
    func schedulerDidRefreshScheduledActions(notification: NSNotification)
    {
        print("\n\nschedulerDidRefreshScheduledActions: \(notification)\n")
        
        if  let scheduler = notification.object as? Scheduler
            where scheduler == self.scheduler
        {
            self.tableView.reloadData()
        }
    }
    
    func schedulerDidFailToRefreshScheduledActions(notification: NSNotification) {
        print("\n\nschedulerDidFailToRefreshScheduledActions: \(notification)\n")
    }
    
    func localDatastoreDidChangeActions(notification: NSNotification) {
        print("\n\nlocalDatastoreDidChangeActions: \(notification)\n")
        self.scheduler?.refreshScheduledActions()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return scheduler?.scheduledActions?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Task Cell", forIndexPath: indexPath) as! TableViewTaskCell
        
        // Configure the cell...
        if let task = scheduler?.scheduledActions?[indexPath.row] {
            cell.task = task
        }
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
