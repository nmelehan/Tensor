//
//  Scheduler.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/25/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import Foundation
import Parse

class Scheduler : PFObject, PFSubclassing {
    
    // MARK: - PFSubclassing
    
    override class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    static func parseClassName() -> String {
        return "Scheduler"
    }
    
    // MARK: - Notification constants
    
    struct Notification {
        static let SchedulerDidRefreshScheduledActions = "Tensor.SchedulerDidRefreshScheduledActionsNotification"
        static let SchedulerDidFailToRefreshScheduledActions = "Tensor.SchedulerDidFailToRefreshScheduledActionsNotification"
    }
    
    // MARK: - Properties
    
    @NSManaged var user: PFUser?
    @NSManaged var inSandbox: NSNumber?
    @NSManaged var scheduledActions: [Action]?
    @NSManaged var actionsIneligibleForScheduling: [Action]?
    @NSManaged var workUnitInProgress: WorkUnit?
    
    var currentAction: Action? {
        get {
            return scheduledActions?.first
        }
    }
    
    // MARK: - Heuristics
    
    @NSManaged var actionFocus: Action?
    
    // MARK: - Methods
    
    func refreshScheduledActions() {
        self.refreshScheduledActions(preserveCurrentAction: true)
    }
    
    func refreshScheduledActions(preserveCurrentAction preserveCurrentAction: Bool) {
        guard user != nil else {
            return // but this should really be a thrown error
        }
        
        let resultsBlock: PFArrayResultBlock = { (results, error) -> Void in
            if error == nil {
                if let scheduledActions = results as? [Action] {
                    var filteredScheduledActions = scheduledActions.filter
                        { !(self.actionsIneligibleForScheduling?.contains($0) ?? false) }
                    
                    if scheduledActions.count > 0 && filteredScheduledActions.count == 0 {
                        // if we skipped all available actions,
                        // empty out the filtering array and reschedule
                        
                        self.actionsIneligibleForScheduling = [Action]()
                        self.refreshScheduledActions()
                    }
                    else {
                        if preserveCurrentAction && self.currentAction != nil {
                            filteredScheduledActions.insert(self.currentAction!, atIndex: 0)
                        }
                        self.scheduledActions = filteredScheduledActions
                        NSNotificationCenter.defaultCenter()
                            .postNotificationName(Notification.SchedulerDidRefreshScheduledActions, object: self)
                    }
                }
            } else {
                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
                NSNotificationCenter.defaultCenter()
                    .postNotificationName(Notification.SchedulerDidFailToRefreshScheduledActions,
                        object: self,
                        userInfo: userInfo)
            }
            
            LocalParseManager.sharedManager.saveLocally(self)
        }
        
        let query = PFQuery(className:"Action")
        query.fromLocalDatastore()
        query.whereKey("isLeaf", equalTo: 1)
        query.whereKeyDoesNotExist("workConclusion")
        query.whereKey("user", equalTo: user!)
        query.whereKey("inSandbox", equalTo: LocalParseManager.sharedManager.currentPersistenceMode.rawValue)
        
        // heuristics
        if let actionFocus = actionFocus {
            query.whereKey("parentAction", equalTo: actionFocus)
        }
        
        query.findObjectsInBackgroundWithBlock(resultsBlock)
    }
    
    func skip() {
        guard scheduledActions != nil else
        {
            return // or throw?
        }
        
        guard user != nil else
        {
            return // or throw?
        }
        
        // remove current action from scheduled actions and reschedule
        let skippedAction = scheduledActions!.removeAtIndex(0)
        if actionsIneligibleForScheduling == nil {
            actionsIneligibleForScheduling = [Action]()
        }
        actionsIneligibleForScheduling!.append(skippedAction)
        self.refreshScheduledActions()
        
        // add a 'skip' WorkUnit to the skipped action
        let manager = LocalParseManager.sharedManager
        let workUnit = manager.createWorkUnitForAction(skippedAction)
        workUnit.setType(.Skip)
        skippedAction.workHistory?.append(workUnit)
        manager.saveLocally(skippedAction)
    }
    
//    func refreshScheduledActionsWithBlock() {
//        
//    }
}