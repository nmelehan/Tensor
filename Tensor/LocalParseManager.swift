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
    // MARK: - Notification constants
    
    // Naming pattern:
    // "Will": posted before pinInBackgroundWithBlock: is called
    // "Did": posted from block passed to pinInBackgroundWithBlock: on success
    // "DidFailTo": posted from block passed to pinInBackgroundWithBlock: on error
    struct Notification {
        static let LocalDatastoreInstallationRequested = "Tensor.LocalDatastoreInstallationRequestedNotification"
        static let LocalDatastoreDidCompleteMinimumViableInstallation = "Tensor.LocalDatastoreDidCompleteMinimumViableInstallationNotification"
        static let LocalDatastoreDidCompleteInstallation = "Tensor.LocalDatastoreDidCompleteInstallationNotification"
        
        static let LocalDatastoreDidFetchSchedulerFromCloud = "Tensor.LocalDatastoreDidFetchSchedulerFromCloudNotification"
        static let LocalDatastoreDidFetchActionsFromCloud = "Tensor.LocalDatastoreDidFetchActionsFromCloudNotification"
        
        static let LocalDatastoreWillAddAction = "Tensor.LocalDatastoreWillAddActionNotification"
        static let LocalDatastoreDidAddAction = "Tensor.LocalDatastoreDidAddActionNotification"
        static let LocalDatastoreDidFailToAddAction = "Tensor.LocalDatastoreDidFailToAddActionNotification"
        
        static let LocalDatastoreWillRemoveAction = "Tensor.LocalDatastoreWillRemoveActionNotification"
        static let LocalDatastoreDidRemoveAction = "Tensor.LocalDatastoreDidRemoveActionNotification"
        static let LocalDatastoreDidFailToRemoveAction = "Tensor.LocalDatastoreDidFailToRemoveActionNotification"
        
        static let LocalDatastoreWillUpdateAction = "Tensor.LocalDatastoreWillUpdateActionNotification"
        static let LocalDatastoreDidUpdateAction = "Tensor.LocalDatastoreDidUpdateActionNotification"
        static let LocalDatastoreDidFailToUpdateAction = "Tensor.LocalDatastoreDidFailToUpdateActionNotification"
    }
    
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
                            .postNotificationName(Notification.LocalDatastoreDidFetchActionsFromCloud,
                                object: objects as? [Action])
                    }
                })
            } else {
            }
        }
        
        installationProgress.currentInstallationProgress = .OperationsInProgress
        let query = PFQuery(className:"Action")
        query.whereKey("user", equalTo: user)
        query.findObjectsInBackgroundWithBlock(resultsBlock)
    }
    
    // MARK: - Public factory and query methods
    
    func createScheduler() -> Scheduler {
        let newScheduler = Scheduler()
        newScheduler.user = user
        newScheduler.inSandbox = currentPersistenceMode.rawValue
        
//        NSNotificationCenter.defaultCenter()
//            .postNotificationName(Notification.LocalDatastoreWillAddScheduler, object: newScheduler)
        
        newScheduler.pinInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
//                NSNotificationCenter.defaultCenter().postNotificationName(Notification.LocalDatastoreDidAddScheduler, object: newScheduler)
            }
            else {
//                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
//                NSNotificationCenter.defaultCenter()
//                    .postNotificationName(Notification.LocalDatastoreDidFailToAddSchduler,
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
        newAction.completionStatus = Action.CompletionStatus.InProgress.rawValue
        newAction.user = user
        newAction.inSandbox = currentPersistenceMode.rawValue
        
        NSNotificationCenter.defaultCenter()
            .postNotificationName(Notification.LocalDatastoreWillAddAction, object: newAction)
        
        newAction.pinInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
                NSNotificationCenter.defaultCenter().postNotificationName(Notification.LocalDatastoreDidAddAction, object: newAction)
            }
            else {
                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
                NSNotificationCenter.defaultCenter()
                    .postNotificationName(Notification.LocalDatastoreDidFailToAddAction,
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
        action.isLeaf = false
        
        if isSubscribed {
            queueToSaveRemotely(newAction)
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
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.LocalDatastoreWillUpdateAction, object: action)
        action.pinInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
                NSNotificationCenter.defaultCenter().postNotificationName(Notification.LocalDatastoreDidUpdateAction, object: action)
            }
            else {
                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
                NSNotificationCenter.defaultCenter()
                    .postNotificationName(Notification.LocalDatastoreDidFailToUpdateAction,
                        object: action,
                        userInfo: userInfo)
            }
        }
        
        if isSubscribed {
            queueToSaveRemotely(action)
        }
    }
    
    func saveLocally(scheduler: Scheduler) {
//        NSNotificationCenter.defaultCenter().postNotificationName(Notification.LocalDatastoreWillUpdateAction, object: action)
        scheduler.pinInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
//                NSNotificationCenter.defaultCenter().postNotificationName(Notification.LocalDatastoreDidUpdateAction, object: action)
            }
            else {
//                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
//                NSNotificationCenter.defaultCenter()
//                    .postNotificationName(Notification.LocalDatastoreDidFailToUpdateAction,
//                        object: scheduler,
//                        userInfo: userInfo)
            }
        }
        
        if isSubscribed {
            queueToSaveRemotely(scheduler)
        }
    }
    
    func fetchDependenciesOfActionInBackground(action: Action, withBlock block: PFArrayResultBlock?) {
        let query = PFQuery(className: "Action")
        query.fromLocalDatastore()
        query.whereKey("parentAction", equalTo:action)
        query.findObjectsInBackgroundWithBlock(block)
    }
    
    func fetchSchedulerInBackgroundWithBlock(block: PFObjectResultBlock?) {
        let query = PFQuery(className: "Scheduler")
        query.fromLocalDatastore()
        query.whereKey("user", equalTo: user)
        query.whereKey("inSandbox", equalTo: LocalParseManager.sharedManager.currentPersistenceMode.rawValue)
        query.includeKey("scheduledActions")
        query.getFirstObjectInBackgroundWithBlock(block)
    }
    
    func fetchSchedulersInBackgroundWithBlock(block: PFArrayResultBlock?) {
        let query = PFQuery(className: "Scheduler")
        query.fromLocalDatastore()
        query.whereKey("user", equalTo: user)
        query.findObjectsInBackgroundWithBlock(block)
    }
    
    private func queueToSaveRemotely(object: PFObject) {
        object.saveEventually()
    }
}