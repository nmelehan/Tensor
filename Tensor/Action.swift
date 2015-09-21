//
//  Action.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/3/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import Foundation
import Parse

class Action : PFObject, PFSubclassing {
    override class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    static func parseClassName() -> String {
        return "Action"
    }
    
    @NSManaged var user: PFUser?
    @NSManaged var name: String
    @NSManaged var parentAction: Action
    @NSManaged var isLeaf: Bool
    
    func addDependency(dependency: Action, saveInBackgroundWithBlock block: PFBooleanResultBlock?) {
        self.isLeaf = false
        dependency.parentAction = self
        
        self.saveInBackground()
        dependency.saveInBackgroundWithBlock(block)
    }
    
    func fetchDependenciesInBackgroundWithBlock(block: PFArrayResultBlock?) {
        let query = PFQuery(className:"Action")
        query.whereKey("parentAction", equalTo:self)
        query.findObjectsInBackgroundWithBlock(block)
    }
}