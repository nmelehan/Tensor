//
//  PlanTableViewController.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/2/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit
import Parse

class PlanTableViewController: UITableViewController, TaskDetailViewControllerDelegate, ParseLoginViewControllerDelegate {
    
    // Mark: - Properties
    
    var tasks = [Action]()
    
    var parentTask: Action?
    {
        didSet
        {
            // set tasks var
            fetchTasks()
        }
    }
    
    // Mark: - Methods
    
    func fetchTasks() {
        let resultsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded.
                print("Successfully retrieved \(objects!.count) actions.", terminator: "")
                // Do something with the found objects
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
                query.whereKeyDoesNotExist("parentAction")
                query.whereKey("user", equalTo: PFUser.currentUser()!)
                query.findObjectsInBackgroundWithBlock(resultsBlock)
            }
        }
        else
        {
            parentTask!.fetchDependenciesInBackgroundWithBlock(resultsBlock)
        }
    }
    
    // Mark: - IBActions
    
    @IBAction func logOutButtonPressed(sender: UIBarButtonItem) {
        PFUser.logOut()
        self.performSegueWithIdentifier(Storyboard.ShowAuthenticationUISegueIdentifier, sender: self)
    }
    
    @IBAction func createNewTask(sender: UIBarButtonItem)
    {
        let newAction = Action()
        newAction.user = PFUser.currentUser()
        newAction.name = "New Task"
        newAction.isLeaf = true
        
        let savingBlock = { (success: Bool, error: NSError?) -> Void in
            if (success) {
                // The object has been saved.
                self.tasks.append(newAction)
                dispatch_async(dispatch_get_main_queue()) { self.tableView.reloadData() }
            }  else {
                // There was a problem, check error.description
            }
        }
        
        if let parent = parentTask {
            parent.addDependency(newAction, saveInBackgroundWithBlock: savingBlock)
        }
        else {
            newAction.saveInBackgroundWithBlock(savingBlock)
        }
    }
    
    // Mark: - View lifecycle

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
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - TaskDetailViewControllerDelegate
    
    func taskDetailViewControllerDidUpdateTask(controller: TaskDetailViewController) {
        self.tableView.reloadData()
    }
    
    // Mark: - ParseLoginViewControllerDelegate
    
    func parseLoginViewController(plvc: ParseLoginViewController, didAuthenticateUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
        fetchTasks()
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
        let cell = tableView.dequeueReusableCellWithIdentifier("Task Cell", forIndexPath: indexPath) as! PlanTableViewTaskCell

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
                    dvc.parentTask = (sender as? PlanTableViewTaskCell)?.task
                }
            case Storyboard.ShowDetailForTaskSegueIdentifier:
                if let dvc = segue.destinationViewController as? TaskDetailViewController {
                    dvc.task = (sender as? PlanTableViewTaskCell)?.task
                    dvc.delegate = self
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
