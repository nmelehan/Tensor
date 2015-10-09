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
    
    // Naming pattern:
    struct Notification {
        static let SchedulerDidRefreshScheduledActions = "Tensor.SchedulerDidRefreshScheduledActionsNotification"
        static let SchedulerDidFailToRefreshScheduledActions = "Tensor.SchedulerDidFailToRefreshScheduledActionsNotification"
    }
    
    // MARK: - Properties
    
    @NSManaged var user: PFUser?
    @NSManaged var inSandbox: NSNumber?
    @NSManaged var scheduledActions: [Action]?
    @NSManaged var actionsIneligibleForScheduling: [Action]?
    
    var currentAction: Action? {
        get {
            return scheduledActions?.first
        }
    }
    
    // MARK: - Methods
    
    func refreshScheduledActions() {
        guard user != nil else {
            return // but this should really be a thrown error
        }
        
        let resultsBlock: PFArrayResultBlock = { (results, error) -> Void in
            if error == nil {
                if let scheduledActions = results as? [Action] {
                    let filteredScheduledActions = scheduledActions.filter
                        { !(self.actionsIneligibleForScheduling?.contains($0) ?? false) }
                    
                    if scheduledActions.count > 0 && filteredScheduledActions.count == 0 {
                        // if we skipped all available actions, 
                        // empty out the filtering array and reschedule
                        
                        self.actionsIneligibleForScheduling = [Action]()
                        self.refreshScheduledActions()
                    }
                    else {
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
        query.whereKey("completionStatus", equalTo: Action.CompletionStatus.InProgress.rawValue)
        query.whereKey("user", equalTo: user!)
        query.whereKey("inSandbox", equalTo: LocalParseManager.sharedManager.currentPersistenceMode.rawValue)
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
        
        let currentAction = scheduledActions!.removeAtIndex(0)
        
        if actionsIneligibleForScheduling == nil {
            actionsIneligibleForScheduling = [Action]()
        }
        actionsIneligibleForScheduling!.append(currentAction)
        
        self.refreshScheduledActions()
    }
    
//    func refreshScheduledActionsWithBlock() {
//        
//    }
}