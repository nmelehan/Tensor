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
        newAction.pinInBackground() // add block/notification
        
        return newAction
    }
    
    func createDependencyForAction(action: Action) -> Action {
        let newAction = Action()
        newAction.isLeaf = true
        newAction.parentAction = action
        action.isLeaf = false
        
        newAction.pinInBackground() // add block/notification
        return newAction
    }
    
    func addDependency(dependency: Action, toAction parentAction: Action, saveInBackgroundWithBlock block: PFBooleanResultBlock?) {
        parentAction.isLeaf = false
        dependency.parentAction = parentAction
    }
    
    func fetchDependenciesOfActionInBackground(action: Action, withBlock block: PFArrayResultBlock?) {
        let query = PFQuery(className:"Action")
        query.fromLocalDatastore()
        query.whereKey("parentAction", equalTo:self)
        query.findObjectsInBackgroundWithBlock(block)
    }
}