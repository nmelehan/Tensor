//
//  PlanTableViewController.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/2/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit
import Parse

class PlanTableViewController: UITableViewController, UISearchResultsUpdating, ParseLoginViewControllerDelegate {
    
    //
    //
    //
    //
    // MARK: - Properties
    
    var tasks = [Action]()
    var filteredActions = [Action]()
    var searchController: UISearchController!
    
    var parentTask: Action?
    {
        didSet
        {
            // set tasks var
            fetchTasks()
        }
    }
    
    
    
    //
    //
    //
    //
    // MARK: - Methods
    
    func fetchTasks() {
        let resultsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil
            {
                if let objects = objects as? [Action]
                {
                    self.tasks = objects
                    dispatch_async(dispatch_get_main_queue()) { self.tableView.reloadData() }
                }
                self.refreshControl?.endRefreshing()
            }
        }
        
        if parentTask == nil
        {
            LocalParseManager.sharedManager
                .fetchTopLevelActionsInBackgroundWithBlock(resultsBlock)
        }
        else
        {
            LocalParseManager.sharedManager
                .fetchDependenciesOfActionInBackground(parentTask!, withBlock: resultsBlock)
        }
    }
    
    func filterContentForSearchText(searchText: String)
    {
        // Filter the array using the filter method
        self.filteredActions = self.tasks.filter
        {   (action: Action) -> Bool in
                let stringMatch = action.name?.rangeOfString(searchText)
                return stringMatch != nil
        }
    }
    
    func refresh(refreshControl: UIRefreshControl) {
        // Do your job, when done:
        fetchTasks()
    }
    
    func addNotificationCenterObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "actionsWereFetchedFromCloud:",
            name: LocalParseManager.Notifications.LocalDatastoreDidFetchActionsFromCloud,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "actionDidPin:",
            name: LocalParseManager.Notifications.LocalDatastoreDidAddAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "actionDidFailToPin:",
            name: LocalParseManager.Notifications.LocalDatastoreDidFailToAddAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "actionDidUpdate:",
            name: LocalParseManager.Notifications.LocalDatastoreDidUpdateAction,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "settingDidChange:",
            name: AppSettings.Notifications.UserDidChangeShowCompletedAndInvalidatedActionsInPlanView,
            object: nil)
    }
    
    
    
    //
    //
    //
    //
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
    }
    
    
    
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
        
        if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {
            performSegueWithIdentifier("Show Authentication UI", sender: self)
        }
        else {
            fetchTasks()
        }
        
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchController.searchBar
        
        addNotificationCenterObservers()
        
        self.refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    //
    //
    //
    //
    // MARK: - Notifications
    
    func actionsWereFetchedFromCloud(notification: NSNotification) {
        fetchTasks()
    }
    
    func actionDidPin(notification: NSNotification) {
        fetchTasks()
    }
    
    func actionDidFailToPin(notification: NSNotification) {
    }
    
    func actionDidUpdate(notification: NSNotification) {
        fetchTasks()
    }
    
    func settingDidChange(notification: NSNotification) {
        fetchTasks()
    }
    
    
    
    //
    //
    //
    //
    // MARK: - ParseLoginViewControllerDelegate
    
    func parseLoginViewController(plvc: ParseLoginViewController, didAuthenticateUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
        LocalParseManager.sharedManager.becomeUser(user)
    }
    
    func parseLoginViewControllerDidCancel(plvc: ParseLoginViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
        fetchTasks()
    }
    
    
    
    //
    //
    //
    //
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        self.filteredActions.removeAll(keepCapacity: false)
        
        let searchPredicate = NSPredicate(format: "name CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (self.tasks as NSArray).filteredArrayUsingPredicate(searchPredicate)
        self.filteredActions = array as! [Action]
        
        self.tableView.reloadData()
    }
    
    
    
    //
    //
    //
    //
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.searchController.active
            ? filteredActions.count
            : tasks.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Task Cell", forIndexPath: indexPath) as! TableViewTaskCell

        // Configure the cell...
        if (self.searchController.active) {
            cell.task = filteredActions[indexPath.row]
        }
        else {
            cell.task = tasks[indexPath.row]
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(Storyboard.ShowDetailForTaskSegueIdentifier, sender: tableView.cellForRowAtIndexPath(indexPath))
    }
    
    
    
    //
    //
    //
    //
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
