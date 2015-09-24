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
    // Naming pattern:
    // "Will": posted before pinInBackgroundWithBlock: is called
    // "Did": posted from block passed to pinInBackgroundWithBlock: on success
    // "DidFailTo": posted from block passed to pinInBackgroundWithBlock: on error
    enum Notification {
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
    
    static let sharedManager = LocalParseManager()
    
    var lastFetchTime: NSDate?
    
    var user: PFUser?
    var isSubscribed: Bool = true
    
    func becomeUser(user: PFUser) {
//        var previousUser = self.user
        self.user = user
        // unpin all actions from previous user
        
        // fetch new actions from new user and pin them
        let resultsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                PFObject.pinAllInBackground(objects, block: { (success, error) -> Void in
                    if success {
                        NSNotificationCenter.defaultCenter()
                            .postNotificationName(Notification.LocalDatastoreDidFetchActionsFromCloud,
                                object: objects as? [Action])
                    }
                })
            } else {
            }
        }
        
        let query = PFQuery(className:"Action")
        query.whereKey("user", equalTo: user)
        query.findObjectsInBackgroundWithBlock(resultsBlock)
    }
    
    func createAction() -> Action {
        let newAction = Action()
        newAction.isLeaf = true
        newAction.completionStatus = Action.CompletionStatus.InProgress.rawValue
        newAction.user = PFUser.currentUser()
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.LocalDatastoreWillAddAction, object: newAction)
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
    
    func fetchDependenciesOfActionInBackground(action: Action, withBlock block: PFArrayResultBlock?) {
        let query = PFQuery(className:"Action")
        query.fromLocalDatastore()
        query.whereKey("parentAction", equalTo:action)
        query.findObjectsInBackgroundWithBlock(block)
    }
    
    private func queueToSaveRemotely(action: Action) {
        action.saveEventually()
    }
}