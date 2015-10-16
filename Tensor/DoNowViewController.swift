//
//  DoNowViewController.swift
//  Tensor
//
//  Created by Nathan Melehan on 10/11/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit
import Parse

class DoNowViewController: UIViewController {
    
    // MARK: - Properties
    
    var scheduler: Scheduler?
    var timer: NSTimer?
    
    // MARK: - Methods
    
    func updateUI() {
        actionNameLabel.text = self.scheduler?.currentAction?.name
    }
    
    func timerTicked(timer: NSTimer) {
        guard let startDate = scheduler?.workUnitInProgress?.startDate else {
            return
        }
        
        let interval = Int(-1*startDate.timeIntervalSinceNow)
        self.timeIntervalLabel.text = "\(interval)"
        
        if interval % 30 == 0 {
            scheduler?.workUnitInProgress?.duration = interval
            LocalParseManager.sharedManager.saveLocally(scheduler!)
        }
    }
    
    func pauseWork() {
        startButton.enabled = true
        pauseButton.enabled = false
        timer?.invalidate()
        timer = nil
        
        elapsedLabel.hidden = true
        timeIntervalLabel.hidden = true
        
        guard let startDate = scheduler?.workUnitInProgress?.startDate else {
            return
        }
        
        let interval = Int(-1*startDate.timeIntervalSinceNow)
        self.timeIntervalLabel.text = "\(interval)"
        
        scheduler?.workUnitInProgress?.duration = interval
        scheduler?.workUnitInProgress = nil
        LocalParseManager.sharedManager.saveLocally(scheduler!)
    }
    
    // MARK: - @IBOutlets
    
    @IBOutlet weak var actionNameLabel: UILabel!
    @IBOutlet weak var elapsedLabel: UILabel!
    @IBOutlet weak var timeIntervalLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var markActionAsCompleteButton: UIButton!
    @IBOutlet weak var saveProgressAndSkipButton: UIButton!
    
    
    // MARK: - @IBActions
    
    @IBAction func markActionAsCompleteButtonPressed()
    {
        if scheduler?.workUnitInProgress != nil {
            pauseWork()
        }
        
        guard let action = scheduler?.currentAction else {
            return
        }
        
        let manager = LocalParseManager.sharedManager
        let workUnit = manager.createWorkUnitForAction(action)
        workUnit.setType(.Completion)
        action.workConclusion = workUnit
        manager.saveLocally(action)
        
        scheduler?.refreshScheduledActions()
        updateUI()
    }
    
    @IBAction func saveProgressAndSkipToNextActionButtonPressed() {
        if scheduler?.workUnitInProgress != nil {
            pauseWork()
        }
        scheduler?.skip()
        updateUI()
    }
    
    @IBAction func pauseButtonPressed() {
        pauseWork()
    }
    
    @IBAction func startButtonPressed() {
        if self.timer == nil {
            guard let action = self.scheduler?.currentAction else {
                return
            }
            
            timer = NSTimer.scheduledTimerWithTimeInterval(1,
                target: self,
                selector: "timerTicked:",
                userInfo: nil,
                repeats: true)
            startButton.enabled = false
            pauseButton.enabled = true
            
            elapsedLabel.hidden = false
            timeIntervalLabel.hidden = false
            timeIntervalLabel.text = "0"
            
            let manager = LocalParseManager.sharedManager
            scheduler?.workUnitInProgress = manager.createWorkUnitForAction(action)
            manager.saveLocally(scheduler!)
        }
    }
    
    @IBAction func clearHeuristicsButtonPressed() {
        self.scheduler?.actionFocus = nil
        self.scheduler?.refreshScheduledActions(preserveCurrentAction: false)
    }
    
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
                self.updateUI()
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
    
    // MARK: - Notifications
    
    func schedulerDidRefreshScheduledActions(notification: NSNotification)
    {
        print("\n\nschedulerDidRefreshScheduledActions: \(notification)\n")
        
        if  let scheduler = notification.object as? Scheduler
            where scheduler == self.scheduler
        {
            updateUI()
        }
    }
    
    func schedulerDidFailToRefreshScheduledActions(notification: NSNotification) {
        print("\n\nschedulerDidFailToRefreshScheduledActions: \(notification)\n")
    }
    
    func localDatastoreDidChangeActions(notification: NSNotification) {
        print("\n\nlocalDatastoreDidChangeActions: \(notification)\n")
        self.scheduler?.refreshScheduledActions()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
