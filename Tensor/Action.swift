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
    
    enum CompletionStatus: Int {
        case InProgress = 0
        case Completed = 1
        case Invalidated = 2
    }
    
    @NSManaged var user: PFUser?
    @NSManaged var name: String
    @NSManaged var parentAction: Action
    @NSManaged var isLeaf: Bool
    
    @NSManaged var completionStatus: Int
    @NSManaged var completionDate: NSDate
    
    // MARK: Convenience methods
    
    
}