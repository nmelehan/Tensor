//
//  WorkHistoryTableViewController.swift
//  Tensor
//
//  Created by Nathan Melehan on 10/10/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit
import Parse

class WorkHistoryTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var history = [WorkUnit]()
    
    var action: Action?
    {
        didSet { fetchHistory() }
    }
    
    // MARK: - Methods
    
    func fetchHistory()
    {
        let resultsBlock = { (results: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let history = results as? [WorkUnit] {
                    self.history = history
                    dispatch_async(dispatch_get_main_queue()) { self.tableView.reloadData() }
                }
            } else {
            }
        }
        
        // condition ensures we don't query against an anonymous
        // user that hasn't been saved to Parse yet
        if PFUser.currentUser()?.objectId != nil {
            let query = PFQuery(className:"WorkUnit")
            query.fromLocalDatastore()
            query.whereKey("user", equalTo: PFUser.currentUser()!)
            if let action = action {
                query.whereKey("action", equalTo: action)
            }
            query.orderByDescending("startDate")
            query.includeKey("action")
            query.findObjectsInBackgroundWithBlock(resultsBlock)
        }
    }
    
    // MARK: - IBActions
    
    // MARK: - View lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        fetchHistory()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "historyDidChange:",
            name: LocalParseManager.Notification.LocalDatastoreDidAddWorkUnit,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "historyDidChange:",
            name: LocalParseManager.Notification.LocalDatastoreDidUpdateAction,
            object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Notifications
    
    func historyDidChange(notification: NSNotification) {
        fetchHistory()
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
        return history.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Work Unit Cell", forIndexPath: indexPath) as! WorkUnitTableViewCell
        
        // Configure the cell...
        cell.workUnit = history[indexPath.row]
        
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
    
    // MARK: - Navigation
    
    struct Storyboard {
        static let ShowActionForWorkUnitSegueIdentifier = "Show Action For Work Unit"
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ShowActionForWorkUnitSegueIdentifier:
                if let dvc = segue.destinationViewController as? TaskDetailViewController {
                    dvc.task = (sender as? WorkUnitTableViewCell)?.workUnit?.action
                }
            default: break
            }
        }
    }

}
