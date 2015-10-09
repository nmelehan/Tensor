//
//  PlanTableViewController.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/2/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit
import Parse

class PlanTableViewController: UITableViewController, ParseLoginViewControllerDelegate {
    
    // MARK: - Properties
    
    var tasks = [Action]()
    
    var parentTask: Action?
    {
        didSet
        {
            // set tasks var
            fetchTasks()
        }
    }
    
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
        
        if parentTask == nil
        {
            // condition ensures we don't query against an anonymous
            // user that hasn't been saved to Parse yet
            if PFUser.currentUser()?.objectId != nil {
                let query = PFQuery(className:"Action")
                query.fromLocalDatastore()
                query.whereKeyDoesNotExist("parentAction")
                query.whereKey("user", equalTo: PFUser.currentUser()!)
                query.whereKey("inSandbox", equalTo: LocalParseManager.sharedManager.currentPersistenceMode.rawValue)
                query.findObjectsInBackgroundWithBlock(resultsBlock)
            }
        }
        else
        {
            LocalParseManager.sharedManager
                .fetchDependenciesOfActionInBackground(parentTask!, withBlock: resultsBlock)
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func logOutButtonPressed(sender: UIBarButtonItem) {
        PFUser.logOut()
        self.performSegueWithIdentifier(Storyboard.ShowAuthenticationUISegueIdentifier, sender: self)
    }
    
    @IBAction func createNewTask(sender: UIBarButtonItem)
    {
        let newAction = parentTask != nil
            ? LocalParseManager.sharedManager.createDependencyForAction(parentTask!)
            : LocalParseManager.sharedManager.createAction()
        newAction.name = "New Task"
//        self.tasks.append(newAction)
//        self.tableView.reloadData()
    }
    
    // MARK: - View lifecycle

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {
            performSegueWithIdentifier("Show Authentication UI", sender: self)
        }
        else {
            fetchTasks()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "actionsWereFetchedFromCloud:",
            name: LocalParseManager.Notification.LocalDatastoreDidFetchActionsFromCloud,
            object: nil)
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
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Notifications
    
    func actionsWereFetchedFromCloud(notification: NSNotification) {
        print("\n\nactionsWereFetchedFromCloud: \(notification)\n")
        fetchTasks()
    }
    
    func actionDidPin(notification: NSNotification) {
        print("\n\nactionDidPin: \(notification)\n")
        fetchTasks()
    }
    
    func actionDidFailToPin(notification: NSNotification) {
        print("\n\nactionDidFailToPin: \(notification)")
    }
    
    func actionDidUpdate(notification: NSNotification) {
        print("\n\nactionDidUpdate: \(notification)")
        fetchTasks()
    }
    
    // MARK: - ParseLoginViewControllerDelegate
    
    func parseLoginViewController(plvc: ParseLoginViewController, didAuthenticateUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
        LocalParseManager.sharedManager.becomeUser(user)
    }
    
    func parseLoginViewControllerDidCancel(plvc: ParseLoginViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
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
        let cell = tableView.dequeueReusableCellWithIdentifier("Task Cell", forIndexPath: indexPath) as! TableViewTaskCell

        // Configure the cell...
        cell.task = tasks[indexPath.row]

        return cell
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(Storyboard.ShowDetailForTaskSegueIdentifier, sender: tableView.cellForRowAtIndexPath(indexPath))
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
        static let ShowPlanForTaskSegueIdentifier = "Show Plan For Task"
        static let ShowDetailForTaskSegueIdentifier = "Show Detail For Task"
        static let ShowAuthenticationUISegueIdentifier = "Show Authentication UI"
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ShowPlanForTaskSegueIdentifier:
                if let dvc = segue.destinationViewController as? PlanTableViewController {
                    dvc.parentTask = (sender as? TableViewTaskCell)?.task
                }
            case Storyboard.ShowDetailForTaskSegueIdentifier:
                if let dvc = segue.destinationViewController as? TaskDetailViewController {
                    dvc.task = (sender as? TableViewTaskCell)?.task
                }
            case Storyboard.ShowAuthenticationUISegueIdentifier:
                if let dvc = segue.destinationViewController as? ParseLoginViewController {
                    dvc.delegate = self
                }
            default: break
            }
        }
    }

}
