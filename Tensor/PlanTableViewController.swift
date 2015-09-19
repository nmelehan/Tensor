//
//  PlanTableViewController.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/2/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit
import Parse

class PlanTableViewController: UITableViewController, TaskDetailViewControllerDelegate {
    
    var parentTask: Action?
    {
        didSet
        {
            // set tasks var
            fetchTasks()
        }
    }
    
    var tasks = [Action]()
    
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
            let query = PFQuery(className:"Action")
            query.whereKeyDoesNotExist("parentAction")
            query.findObjectsInBackgroundWithBlock(resultsBlock)
        }
        else
        {
            parentTask!.fetchDependenciesInBackgroundWithBlock(resultsBlock)
        }
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        fetchTasks()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func createNewTask(sender: UIBarButtonItem)
    {
        let newAction = Action()
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
    
    // MARK: - TaskDetailViewControllerDelegate
    
    func taskDetailViewControllerDidUpdateTask(controller: TaskDetailViewController) {
        self.tableView.reloadData()
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
            default: break
            }
        }
    }

}
