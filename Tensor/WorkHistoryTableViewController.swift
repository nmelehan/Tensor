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
    
    
    
    //
    //
    //
    //
    // MARK: - Properties
    
    var history = [WorkUnit]()
    
    var action: Action?
    {
        didSet { fetchHistory() }
    }
    
    
    
    //
    //
    //
    //
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
        
        let manager = LocalParseManager.sharedManager
        if let action = action {
            manager.fetchWorkHistoryForActionInBackground(action, withBlock: resultsBlock)
        }
        else {
            manager.fetchWorkHistoryInBackgroundWithBlock(resultsBlock)
        }
    }
    
    
    
    //
    //
    //
    //
    // MARK: - IBActions
    
    
    
    //
    //
    //
    //
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
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "historyDidChange:",
            name: LocalParseManager.Notification.LocalDatastoreDidUpdateWorkUnit,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "settingDidChange:",
            name: AppSettings.Notifications.ShowSkipsInWorkHistoryDidChange,
            object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    //
    //
    //
    //
    // MARK: - Notifications
    
    func historyDidChange(notification: NSNotification) {
        fetchHistory()
    }
    
    func settingDidChange(notification: NSNotification) {
        print("\n\nsettingDidChange: \(notification)")
        fetchHistory()
    }
    
    
    
    //
    //
    //
    //
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
    
    
    
    //
    //
    //
    //
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
