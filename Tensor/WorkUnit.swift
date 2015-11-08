//
//  WorkUnit.swift
//  Tensor
//
//  Created by Nathan Melehan on 10/9/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import Foundation
import Parse

class WorkUnit : PFObject, PFSubclassing {
    
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
        return "WorkUnit"
    }
    
    // MARK: - Properties
    
    @NSManaged var user: PFUser
    @NSManaged var action: Action
    @NSManaged var type: String
    @NSManaged var startDate: NSDate
    @NSManaged var duration: NSNumber
    
    enum WorkUnitType: String {
        case Progress = "progress"
        case Completion = "completion"
        case Invalidation = "invalidation"
        case Skip = "skip"
        case Reactivation = "reactivation"
    }
    
    func setType(workUnitType: WorkUnitType) {
        type = workUnitType.rawValue
    }
    
    func getType() -> WorkUnitType {
        return WorkUnitType(rawValue: type)!
    }
    
    //
    //
    //
    //
    // MARK: - Constants
    
    struct FieldKeys {
        static let User = "user"
        static let Action = "action"
        static let Type = "type"
        static let StartDate = "startDate"
        static let Duration = "duration"
    }
}
