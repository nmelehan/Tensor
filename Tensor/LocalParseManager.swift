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
    enum Notification {
        static let LocalDatastoreDidPinAction = "Tensor.LocalDatastoreDidPinActionNotification"
        static let LocalDatastoreDidFailToPinAction = "Tensor.LocalDatastoreDidFailToPinActionNotification"
        static let LocalDatastoreDidUnpinAction = "Tensor.LocalDatastoreDidUnpinActionNotification"
        static let LocalDatastoreDidUpdateAction = "Tensor.LocalDatastoreDidUpdateActionNotification"
    }
    
    static let sharedManager = LocalParseManager()
    
    var lastFetchTime: NSDate?
    
    var user: PFUser?
    
    func becomeUser(user: PFUser) {
        var previousUser = self.user
        self.user = user
        // unpin all actions from previous user
        
        // fetch new actions from new user and pin them
        let resultsBlock = { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded.
                print("Successfully retrieved \(objects!.count) actions.", terminator: "")
                // Do something with the found objects
                PFObject.pinAllInBackground(objects, block: { (success, error) -> Void in
                    if success {
                        print("Successfully pinned all results in background")
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
        newAction.user = PFUser.currentUser()
        newAction.pinInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
                NSNotificationCenter.defaultCenter().postNotificationName(Notification.LocalDatastoreDidPinAction, object: newAction)
            }
            else {
                let userInfo: [NSObject : AnyObject]? = error != nil ? ["error" : error!] : nil
                NSNotificationCenter.defaultCenter()
                    .postNotificationName(Notification.LocalDatastoreDidFailToPinAction,
                        object: newAction,
                        userInfo: userInfo)
            }
        }
        
        return newAction
    }
    
    func createDependencyForAction(action: Action) -> Action {
        let newAction = self.createAction()
        newAction.parentAction = action
        action.isLeaf = false
        
        return newAction
    }
    
    func addDependency(dependency: Action, toAction parentAction: Action) {
        parentAction.isLeaf = false
        dependency.parentAction = parentAction
    }
    
    func saveLocally(action: Action) {
        action.pinInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
                print("LocalParseManager.saveLocally() successfully pinned action: \(action)")
            }
            else {
                print("LocalParseManager.saveLocally() failed to pin action: \(action)")
            }
        }
        NSNotificationCenter.defaultCenter()
            .postNotificationName(Notification.LocalDatastoreDidUpdateAction,
                object: action,
                userInfo: nil)
    }
    
    func fetchDependenciesOfActionInBackground(action: Action, withBlock block: PFArrayResultBlock?) {
        let query = PFQuery(className:"Action")
        query.fromLocalDatastore()
        query.whereKey("parentAction", equalTo:action)
        query.findObjectsInBackgroundWithBlock(block)
    }
}