//
//  LocalParseManager.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/22/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import Foundation
import Parse

class LocalParseManager
{
    //
    //
    //
    //
    // MARK: - Notification constants
    
    // Naming pattern:
    // "Will": posted before pinInBackgroundWithBlock: is called
    // "Did": posted from block passed to pinInBackgroundWithBlock: on success
    // "DidFailTo": posted from block passed to pinInBackgroundWithBlock: on error
    struct Notifications {
        static let LocalDatastoreInstallationRequested = "Tensor.LocalParseManager.Notifications.LocalDatastoreInstallationRequested"
        static let LocalDatastoreDidCompleteMinimumViableInstallation = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidCompleteMinimumViableInstallation"
        static let LocalDatastoreDidCompleteInstallation = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidCompleteInstallation"
        
        static let LocalDatastoreDidFetchSchedulerFromCloud = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidFetchSchedulerFromCloud"
        static let LocalDatastoreDidFetchActionsFromCloud = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidFetchActionsFromCloud"
        
        static let LocalDatastoreWillAddAction = "Tensor.LocalParseManager.Notifications.LocalDatastoreWillAddAction"
        static let LocalDatastoreDidAddAction = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidAddAction"
        static let LocalDatastoreDidFailToAddAction = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidFailToAddAction"
        
        static let LocalDatastoreWillRemoveAction = "Tensor.LocalParseManager.Notifications.LocalDatastoreWillRemoveAction"
        static let LocalDatastoreDidRemoveAction = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidRemoveAction"
        static let LocalDatastoreDidFailToRemoveAction = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidFailToRemoveAction"
        
        static let LocalDatastoreWillUpdateAction = "Tensor.LocalParseManager.Notifications.LocalDatastoreWillUpdateAction"
        static let LocalDatastoreDidUpdateAction = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidUpdateAction"
        static let LocalDatastoreDidFailToUpdateAction = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidFailToUpdateAction"
        
        static let LocalDatastoreWillAddWorkUnit = "Tensor.LocalParseManager.Notifications.LocalDatastoreWillAddWorkUnit"
        static let LocalDatastoreDidAddWorkUnit = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidAddWorkUnit"
        static let LocalDatastoreDidFailToAddWorkUnit = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidFailToAddWorkUnit"
        
        static let LocalDatastoreWillUpdateWorkUnit = "Tensor.LocalParseManager.Notifications.LocalDatastoreWillUpdateWorkUnit"
        static let LocalDatastoreDidUpdateWorkUnit = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidUpdateWorkUnit"
        static let LocalDatastoreDidFailToUpdateWorkUnit = "Tensor.LocalParseManager.Notifications.LocalDatastoreDidFailToUpdateWorkUnit"
    }
    
    
    
    //
    //
    //
    //
    // MARK: - Properties
    
    static let sharedManager = LocalParseManager()
    
    var lastFetchTime: NSDate?
    
    var user: PFUser = PFUser.currentUser()!
    var isSubscribed: Bool = true
    
    enum PersistenceMode: Int {
        case Persistent = 0
        case Sandbox = 1
    }

    var currentPersistenceMode: PersistenceMode = .Sandbox
    
    
    
    //
    //
    //
    //
    // MARK: - Datastore initialization
    
    enum AchievedInstallationProgressStatus {
        case InstallationNotRequested
        case InstallationRequested
        case MinimumViableInstallationComplete
        case InstallationComplete
    }
    
    enum CurrentInstallationProgressStatus {
        case NoOperationsInProgress
        case OperationsInProgress
        case OperationsPausedWillTryAgainLater
    }
    
    typealias InstallationProgressStatus
        = (achievedInstallationProgress: AchievedInstallationProgressStatus,
            currentInstallationProgress: CurrentInstallationProgressStatus)
    
    var installationProgress: InstallationProgressStatus
        = (.InstallationNotRequested, .NoOperationsInProgress)
    
    func logOutOfUser(user: PFUser)
    {
        // unpin all Actions and Schedulers
    }
    
    func signUpWithUser(user: PFUser) {
        
    }
    
    func loginWithUser(user: PFUser) {
        
    }
    
    func becomeUser(user: PFUser) {
        installationProgress.achievedInstallationProgress = .InstallationRequested
        
        //        var previousUser = self.user
        self.user = user
        // unpin all actions from previous user
        
        // fetch new actions from new user and pin them
        let resultsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                PFObject.pinAllInBackground(objects, block: { (success, error) -> Void in
                    if success {
                        self.installationProgress = (.InstallationComplete, .NoOperationsInProgress)
                        NSNotificationCenter.defaultCenter()
                            .postNotificationName(Notifications.LocalDatastoreDidFetchActionsFromCloud,
                                object: objects as? [Action])
                    }
                })
            } else {
            }
        }
        
        installationProgress.currentInstallationProgress = .OperationsInProgress
        let query = PFQuery(className: Action.parseClassName())
        query.whereKey(Action.FieldKeys.User, equalTo: user)
        query.includeKey(Action.FieldKeys.WorkConclusion)
        query.findObjectsInBackgroundWithBlock(resultsBlock)
        
        
        // fetch workunits from new user and pin them
        let workUnitResultsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                //                PFObject.pinAllInBackground(objects)
                PFObject.pinAllInBackground(objects, block: { (succeeded, error) -> Void in
                    print(succeeded)
                    print(error)
                    if succeeded {
                        //
                    }
                    else {
                        
                    }
                })
            } else {
            }
        }
        
        let workUnitQuery = PFQuery(className: WorkUnit.parseClassName())
        workUnitQuery.whereKey(WorkUnit.FieldKeys.User, equalTo: user)
        workUnitQuery.includeKey(WorkUnit.FieldKeys.Action)
        workUnitQuery.findObjectsInBackgroundWithBlock(workUnitResultsBlock)
        
        //        currentPersistenceMode = .Persistent
    }
    
    
    
    //
    //
    //
    //
    // MARK: - Factory and saving methods
    
    func createWorkUnitForAction(action: Action) -> WorkUnit
    {
        let newWorkUnit = WorkUnit()
        newWorkUnit.user = user
        newWorkUnit.action = action
        newWorkUnit.setType(.Progress)
        newWorkUnit.startDate = NSDate()
        newWorkUnit.duration = 0
        
        NSNotificationCenter.defaultCenter()
            .postNotificationName(Notifications.LocalDatastoreWillAddWorkUnit, object: newWorkUnit)
        
        newWorkUnit.pinInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.LocalDatastoreDidAddWorkUnit, object: newWorkUnit)
                
                if self.isSubscribed {
                    self.queueToSaveRemotely(newWorkUnit)
                }
            }
            else {
                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
                NSNotificationCenter.defaultCenter()
                    .postNotificationName(Notifications.LocalDatastoreDidFailToAddWorkUnit,
                        object: newWorkUnit,
                        userInfo: userInfo)
            }
        }
        
        return newWorkUnit
    }
    
    func createScheduler() -> Scheduler {
        let newScheduler = Scheduler()
        newScheduler.user = user
        newScheduler.inSandbox = currentPersistenceMode.rawValue
        
//        NSNotificationCenter.defaultCenter()
//            .postNotificationName(Notifications.LocalDatastoreWillAddScheduler, object: newScheduler)
        
        newScheduler.pinInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
//                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.LocalDatastoreDidAddScheduler, object: newScheduler)
            }
            else {
//                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
//                NSNotificationCenter.defaultCenter()
//                    .postNotificationName(Notifications.LocalDatastoreDidFailToAddSchduler,
//                        object: newScheduler,
//                        userInfo: userInfo)
            }
        }
        
        if isSubscribed {
            queueToSaveRemotely(newScheduler)
        }
        
        return newScheduler
    }
    
    func createAction() -> Action {
        let newAction = Action()
        newAction.isLeaf = true
//        newAction.completionStatus = Action.CompletionStatus.InProgress.rawValue
        newAction.user = user
        newAction.inSandbox = currentPersistenceMode.rawValue
        newAction.depth = 0
        newAction.trashed = false
        newAction.numberOfDependencies = 0
        newAction.numberOfInProgressDependencies = 0
        newAction.setDueDateSetting(.Inherit)
        
        NSNotificationCenter.defaultCenter()
            .postNotificationName(Notifications.LocalDatastoreWillAddAction, object: newAction)
        
        newAction.pinInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.LocalDatastoreDidAddAction, object: newAction)
            }
            else {
                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
                NSNotificationCenter.defaultCenter()
                    .postNotificationName(Notifications.LocalDatastoreDidFailToAddAction,
                        object: newAction,
                        userInfo: userInfo)
            }
        }
        
        if isSubscribed {
            queueToSaveRemotely(newAction)
        }
        
        return newAction
    }
    
    func createDependencyForAction(action: Action) -> Action {
        let newAction = self.createAction()
        
        newAction.parentAction = action
        
        var ancestors = action.ancestors ?? []
        ancestors.insert(action, atIndex: 0)
        newAction.ancestors = ancestors
        newAction.depth = action.depth + 1
        
        action.isLeaf = false
        
        action.numberOfDependencies++
        action.numberOfInProgressDependencies++
//        action.incrementKey(Action.FieldKeys.NumberOfDescendents)
//        action.incrementKey(Action.FieldKeys.NumberOfInProgressDescendents)
        
        if isSubscribed {
            queueToSaveRemotely(newAction)
            queueToSaveRemotely(action)
        }
        
        return newAction
    }
    
    func addDependency(dependency: Action, toAction parentAction: Action) {
        parentAction.isLeaf = false
        dependency.parentAction = parentAction
        
        if isSubscribed {
            queueToSaveRemotely(dependency)
        }
    }
    
    func saveLocally(action: Action) {
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.LocalDatastoreWillUpdateAction, object: action)
        action.pinInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.LocalDatastoreDidUpdateAction, object: action)
            }
            else {
                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
                NSNotificationCenter.defaultCenter()
                    .postNotificationName(Notifications.LocalDatastoreDidFailToUpdateAction,
                        object: action,
                        userInfo: userInfo)
            }
        }
        
        if isSubscribed {
            queueToSaveRemotely(action)
        }
    }
    
    func saveLocally(scheduler: Scheduler) {
//        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.LocalDatastoreWillUpdateAction, object: action)
        scheduler.pinInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
//                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.LocalDatastoreDidUpdateAction, object: action)
            }
            else {
//                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
//                NSNotificationCenter.defaultCenter()
//                    .postNotificationName(Notifications.LocalDatastoreDidFailToUpdateAction,
//                        object: scheduler,
//                        userInfo: userInfo)
            }
        }
        
        if isSubscribed {
            queueToSaveRemotely(scheduler)
        }
    }
    
    func saveLocally(workUnit: WorkUnit) {
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.LocalDatastoreWillUpdateWorkUnit, object: workUnit)
        workUnit.pinInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.LocalDatastoreDidUpdateWorkUnit, object: workUnit)
            }
            else {
                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
                NSNotificationCenter.defaultCenter()
                    .postNotificationName(Notifications.LocalDatastoreDidFailToUpdateWorkUnit,
                        object: workUnit,
                        userInfo: userInfo)
            }
        }
        
        if isSubscribed {
            queueToSaveRemotely(workUnit)
        }
    }
    
    private func queueToSaveRemotely(object: PFObject) {
        object.saveEventually()
    }
    
    
    
    //
    //
    //
    //
    // MARK: - Queries
    
    //    func fetchDependenciesOfActionInBackground(action: Action, withBlock block: PFArrayResultBlock?) {
    //        let query = PFQuery(className: "Action")
    //        query.fromLocalDatastore()
    //        query.whereKey("parentAction", equalTo:action)
    //        query.includeKey("workConclusion")
    //        query.includeKey("parentAction")
    //        query.findObjectsInBackgroundWithBlock(block)
    //    }
    
    func fetchTopLevelActionsInBackgroundWithBlock(block: PFArrayResultBlock?) {
        let query = PFQuery(className: Action.parseClassName())
        query.fromLocalDatastore()
        query.whereKeyDoesNotExist(Action.FieldKeys.ParentAction)
        query.whereKey(Action.FieldKeys.User, equalTo: user)
        query.whereKey(Action.FieldKeys.InSandbox, equalTo: LocalParseManager.sharedManager.currentPersistenceMode.rawValue)
        query.whereKey(Action.FieldKeys.Trashed, equalTo: 0)
        
        let showConcludedActions = NSUserDefaults.standardUserDefaults()
            .boolForKey(AppSettings.Keys.ShowCompletedAndInvalidatedActionsInPlanView)
        if showConcludedActions
        {
            query.includeKey(Action.FieldKeys.WorkConclusion)
        }
        else
        {
            query.whereKeyDoesNotExist(Action.FieldKeys.WorkConclusion)
        }
        
        query.findObjectsInBackgroundWithBlock(block)
    }
    
    func fetchDependenciesOfActionInBackground(action: Action, withBlock block: PFArrayResultBlock?) {
        let query = PFQuery(className: Action.parseClassName())
        query.whereKey(Action.FieldKeys.Trashed, equalTo: 0)
        query.fromLocalDatastore()
        query.whereKey(Action.FieldKeys.Ancestors, containsAllObjectsInArray: [action])
        query.whereKey(Action.FieldKeys.Depth, equalTo: action.depth+1)
        query.includeKey(Action.FieldKeys.ParentAction)
        
        let showConcludedActions = NSUserDefaults.standardUserDefaults()
            .boolForKey(AppSettings.Keys.ShowCompletedAndInvalidatedActionsInPlanView)
        if showConcludedActions
        {
            query.includeKey(Action.FieldKeys.WorkConclusion)
        }
        else
        {
            query.whereKeyDoesNotExist(Action.FieldKeys.WorkConclusion)
        }
        
        query.findObjectsInBackgroundWithBlock(block)
    }
    
    func fetchParentOfAction(action: Action, withBlock block: PFObjectResultBlock) {
        action.ancestors?.first?.fetchFromLocalDatastoreInBackgroundWithBlock(block)
    }
    
    func fetchSchedulerInBackgroundWithBlock(block: PFObjectResultBlock?) {
        let query = PFQuery(className: Scheduler.parseClassName())
        query.fromLocalDatastore()
        query.whereKey(Scheduler.FieldKeys.User, equalTo: user)
        query.whereKey(Scheduler.FieldKeys.InSandbox, equalTo: LocalParseManager.sharedManager.currentPersistenceMode.rawValue)
        query.includeKey(Scheduler.FieldKeys.ScheduledActions)
        query.includeKey(Scheduler.FieldKeys.WorkUnitInProgress)
        query.getFirstObjectInBackgroundWithBlock(block)
    }
    
    func fetchSchedulersInBackgroundWithBlock(block: PFArrayResultBlock?) {
        let query = PFQuery(className: Scheduler.parseClassName())
        query.fromLocalDatastore()
        query.whereKey(Scheduler.FieldKeys.User, equalTo: user)
        query.findObjectsInBackgroundWithBlock(block)
    }
    
    func fetchWorkHistoryInBackgroundWithBlock(block: PFArrayResultBlock?)
    {
        let query = PFQuery(className: WorkUnit.parseClassName())
        query.fromLocalDatastore()
        query.whereKey(WorkUnit.FieldKeys.User, equalTo: user)
        query.orderByDescending(WorkUnit.FieldKeys.StartDate)
        query.includeKey(WorkUnit.FieldKeys.Action)
        
        let showSkips = NSUserDefaults.standardUserDefaults()
            .boolForKey(AppSettings.Keys.ShowSkipsInWorkHistory)
        if !showSkips
        {
            query.whereKey(WorkUnit.FieldKeys.Type, notEqualTo: WorkUnit.WorkUnitType.Skip.rawValue)
        }
        
        query.findObjectsInBackgroundWithBlock(block)
    }
    
    func fetchWorkHistoryForActionInBackground(action: Action, withBlock block: PFArrayResultBlock?)
    {
        let query = PFQuery(className: WorkUnit.parseClassName())
        query.fromLocalDatastore()
        query.whereKey(WorkUnit.FieldKeys.User, equalTo: user)
        query.whereKey(WorkUnit.FieldKeys.Action, equalTo: action)
        query.orderByDescending(WorkUnit.FieldKeys.StartDate)
        query.includeKey(WorkUnit.FieldKeys.Action)
        query.findObjectsInBackgroundWithBlock(block)
    }

    
    //
    //
    //
    //
    // MARK: - Model migration methods
    
    func assignAncestorsForAction(action: Action) {
        defer {
            let resultsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
                if error == nil {
                    if let objects = objects as? [Action] {
                        for action in objects {
                            self.assignAncestorsForAction(action)
                        }
                    }
                }
            }
            
            self.fetchDependenciesOfActionInBackground(action, withBlock: resultsBlock)
        }
        
//        guard action.ancestors != nil else { return }
        
        if action.parentAction == nil {
            action.ancestors = nil
            action.depth = 0
        }
        else {
            var ancestors = action.parentAction?.ancestors ?? []
            ancestors.insert(action.parentAction!, atIndex: 0)
            action.ancestors = ancestors
            action.depth = action.parentAction!.depth + 1
        }
        
        self.saveLocally(action)
    }
    
    func migrateToAncestorArray() {
        let resultsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [Action] {
                    for action in objects {
                        self.assignAncestorsForAction(action)
                    }
                }
            }
        }
        
        // condition ensures we don't query against an anonymous
        // user that hasn't been saved to Parse yet
        let query = PFQuery(className: Action.parseClassName())
//        query.fromLocalDatastore()
        query.whereKeyDoesNotExist(Action.FieldKeys.ParentAction)
        query.findObjectsInBackgroundWithBlock(resultsBlock)
    }
    
    func assignDependencyCountForAction(action: Action) {
        let numberOfDescendentsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if let objects = objects as? [Action]
            {
                action.numberOfDependencies = objects.count
                
                for action in objects {
                    self.assignDependencyCountForAction(action)
                }
            }
            else {
                action.numberOfDependencies = 0
            }
            
            self.saveLocally(action)
        }
        
        let numberOfDescendentsQuery = PFQuery(className: Action.parseClassName())
//        numberOfDescendentsQuery.fromLocalDatastore()
        numberOfDescendentsQuery.whereKey(Action.FieldKeys.Ancestors, containsAllObjectsInArray: [action])
        numberOfDescendentsQuery.whereKey(Action.FieldKeys.Depth, equalTo: action.depth+1)
        numberOfDescendentsQuery.whereKey(Action.FieldKeys.Trashed, equalTo: 0)
        numberOfDescendentsQuery.findObjectsInBackgroundWithBlock(numberOfDescendentsBlock)
        
        
        let numberOfInProgressDescendentsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if let objects = objects as? [Action]
            {
                action.numberOfInProgressDependencies = objects.count
            }
            else {
                action.numberOfInProgressDependencies = 0
            }
            
            self.saveLocally(action)
        }
        
        let numberOfInProgressDescendentsQuery = PFQuery(className: Action.parseClassName())
//        numberOfInProgressDescendentsQuery.fromLocalDatastore()
        numberOfInProgressDescendentsQuery.whereKey(Action.FieldKeys.Ancestors, containsAllObjectsInArray: [action])
        numberOfInProgressDescendentsQuery.whereKey(Action.FieldKeys.Depth, equalTo: action.depth+1)
        numberOfInProgressDescendentsQuery.whereKeyDoesNotExist(Action.FieldKeys.WorkConclusion)
        numberOfInProgressDescendentsQuery.whereKey(Action.FieldKeys.Trashed, equalTo: 0)
        numberOfInProgressDescendentsQuery.findObjectsInBackgroundWithBlock(numberOfInProgressDescendentsBlock)
    }
    
    func migrateToDependencyCount() {
        let resultsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [Action] {
                    for action in objects {
                        self.assignDependencyCountForAction(action)
                    }
                }
            }
        }
        
        // condition ensures we don't query against an anonymous
        // user that hasn't been saved to Parse yet
        let query = PFQuery(className: Action.parseClassName())
        //        query.fromLocalDatastore()
        query.whereKeyDoesNotExist(Action.FieldKeys.ParentAction)
        query.findObjectsInBackgroundWithBlock(resultsBlock)
    }
    
    func migrateToTrashedField() {
        let resultsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [Action] {
                    for action in objects {
                        action.trashed = false
                        self.saveLocally(action)
                    }
                }
            }
        }
        
        // condition ensures we don't query against an anonymous
        // user that hasn't been saved to Parse yet
        let query = PFQuery(className: Action.parseClassName())
//        query.fromLocalDatastore()
        query.findObjectsInBackgroundWithBlock(resultsBlock)
    }
    
    func migrateToDueDateSettingField() {
        let resultsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [Action] {
                    for action in objects {
                        action.setDueDateSetting(.Inherit)
                        self.saveLocally(action)
                    }
                }
            }
        }
        
        // condition ensures we don't query against an anonymous
        // user that hasn't been saved to Parse yet
        let query = PFQuery(className: Action.parseClassName())
//        query.fromLocalDatastore()
        query.findObjectsInBackgroundWithBlock(resultsBlock)
    }
}