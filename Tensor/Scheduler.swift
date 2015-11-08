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
    
    
    
    //
    //
    //
    //
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
    
    
    
    //
    //
    //
    //
    // MARK: - Notification constants
    
    struct Notifications {
        static let SchedulerDidRefreshScheduledActions = "Tensor.Scheduler.Notifications.SchedulerDidRefreshScheduledActions"
        static let SchedulerDidFailToRefreshScheduledActions = "Tensor.Scheduler.Notifications.SchedulerDidFailToRefreshScheduledActions"
        static let SchedulerDidPauseWorkUnitInProgress = "Tensor.Scheduler.Notifications.SchedulerDidPauseWorkUnitInProgress"
    }
    
    
    
    //
    //
    //
    //
    // MARK: - Properties
    
    @NSManaged var user: PFUser
    @NSManaged var inSandbox: NSNumber
    @NSManaged var scheduledActions: [Action]?
    @NSManaged var actionsIneligibleForScheduling: [Action]?
    @NSManaged var workUnitInProgress: WorkUnit?
    
    var currentAction: Action? {
        get {
            return scheduledActions?.first
        }
    }
    
    
    
    //
    //
    //
    //
    // MARK: - Heuristics
    
    @NSManaged var actionFocus: Action?
    
    
    
    //
    //
    //
    //
    // MARK: - Constants
    
    struct FieldKeys {
        static let User = "user"
        static let InSandbox = "inSandbox"
        static let ScheduledActions = "scheduledActions"
        static let ActionsIneligibleForScheduling = "actionsIneligibleForScheduling"
        static let WorkUnitInProgress = "workUnitInProgress"
        static let ActionFocus = "actionFocus"
    }
    
    
    
    //
    //
    //
    //
    // MARK: - Methods
    
    func hasHeuristics() -> Bool {
        return actionFocus != nil
    }
    
    func refreshScheduledActions() {
        self.refreshScheduledActions(preserveCurrentAction: true)
    }
    
    func refreshScheduledActions(preserveCurrentAction preserveCurrentAction: Bool) {
//        guard user != nil else {
//            return // but this should really be a thrown error
//        }
        
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
                    else if scheduledActions.count == 0 && self.hasHeuristics() {
                        // relax heuristics
                        self.actionFocus = nil
                        self.refreshScheduledActions()
                    }
                    else {
                        if      preserveCurrentAction
                            &&  self.currentAction != nil
                            &&  self.currentAction?.workConclusion == nil // don't preserve invalidated or completed actions
                        {
                            // filter array again to ensure that first element
                            // doesn't appear again later in schedule
                            filteredScheduledActions = filteredScheduledActions.filter
                                { $0 != self.currentAction! }
                            filteredScheduledActions.insert(self.currentAction!, atIndex: 0)
                        }
                        self.scheduledActions = filteredScheduledActions
                        NSNotificationCenter.defaultCenter()
                            .postNotificationName(Notifications.SchedulerDidRefreshScheduledActions, object: self)
                    }
                }
            } else {
                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
                NSNotificationCenter.defaultCenter()
                    .postNotificationName(Notifications.SchedulerDidFailToRefreshScheduledActions,
                        object: self,
                        userInfo: userInfo)
            }
            
            LocalParseManager.sharedManager.saveLocally(self)
        }
        
        let query = PFQuery(className: Action.parseClassName())
        query.fromLocalDatastore()
        
        query.whereKey(Action.FieldKeys.IsLeaf, equalTo: 1)
        query.whereKeyDoesNotExist(Action.FieldKeys.WorkConclusion)
        query.whereKey(Action.FieldKeys.User, equalTo: user)
        query.includeKey(Action.FieldKeys.ParentAction)
        query.whereKey(Action.FieldKeys.InSandbox, equalTo: LocalParseManager.sharedManager.currentPersistenceMode.rawValue)
        
        // heuristics
        if let actionFocus = actionFocus {
            query.whereKey(Action.FieldKeys.Ancestors, equalTo: actionFocus)
        }
        
        query.findObjectsInBackgroundWithBlock(resultsBlock)
    }
    
    func skip() {
        guard scheduledActions != nil && scheduledActions!.count > 0 else
        {
            return // or throw?
        }
        
//        guard user != nil else
//        {
//            return // or throw?
//        }
        
        // remove current action from scheduled actions and reschedule
        let skippedAction = scheduledActions!.removeAtIndex(0)
        if actionsIneligibleForScheduling == nil {
            actionsIneligibleForScheduling = [Action]()
        }
        actionsIneligibleForScheduling!.append(skippedAction)
        self.refreshScheduledActions(preserveCurrentAction: false)
        
        // add a 'skip' WorkUnit to the skipped action
        let manager = LocalParseManager.sharedManager
        let workUnit = manager.createWorkUnitForAction(skippedAction)
        workUnit.setType(.Skip)
    }
    
    func pauseWorkUnitInProgress() {
        guard   let workUnitInProgress = workUnitInProgress
                where workUnitInProgress.getType() == .Progress else {
            return // #warning throw?
        }
        
        let manager = LocalParseManager.sharedManager
        let interval = Int(-1*workUnitInProgress.startDate.timeIntervalSinceNow)
        workUnitInProgress.duration = interval
        manager.saveLocally(workUnitInProgress)
        
        self.workUnitInProgress = nil
        manager.saveLocally(self)
        
        let userInfo = ["workUnit" : workUnitInProgress]
        NSNotificationCenter.defaultCenter()
            .postNotificationName(Notifications.SchedulerDidPauseWorkUnitInProgress,
                object: self, userInfo: userInfo)
    }
    
    func immediatelyScheduleAction(action: Action) {
        if workUnitInProgress != nil {
            pauseWorkUnitInProgress()
        }
        
        if scheduledActions != nil {
            scheduledActions!.insert(action, atIndex: 0)
        }
        else {
            scheduledActions = [action]
        }
        
        LocalParseManager.sharedManager.saveLocally(self)
        NSNotificationCenter.defaultCenter()
            .postNotificationName(Notifications.SchedulerDidRefreshScheduledActions, object: self)
    }
}