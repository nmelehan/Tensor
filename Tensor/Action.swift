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
    
    @NSManaged var user: PFUser
    @NSManaged var name: String?
    @NSManaged var parentAction: Action?
    @NSManaged var ancestors: [Action]?
    @NSManaged var depth: Int
    @NSManaged var isLeaf: Bool
    @NSManaged var inSandbox: NSNumber
    @NSManaged var workConclusion: WorkUnit?
    @NSManaged var trashed: Bool
    @NSManaged var numberOfDependencies: Int
    @NSManaged var numberOfInProgressDependencies: Int
    @NSManaged var dueDateSetting: String
    @NSManaged var inheritedDueDate: NSDate?
    @NSManaged var userSetDueDate: NSDate?
    @NSManaged var effectiveDueDate: NSDate?
    
    enum AttributeSettingMethod: String {
        case Inherit = "inherit"
        case SetByUser = "setbyuser"
    }
    
    func setDueDateSetting(attributeSettingMethod: AttributeSettingMethod) {
        dueDateSetting = attributeSettingMethod.rawValue
    }
    
    func getDueDateSetting() -> AttributeSettingMethod {
        return AttributeSettingMethod(rawValue: dueDateSetting)!
    }
    
    func setEffectiveDueDate() {
        if inheritedDueDate == nil && userSetDueDate == nil {
            effectiveDueDate = nil
        }
        else if inheritedDueDate == nil && userSetDueDate != nil {
            effectiveDueDate = userSetDueDate
        }
        else if inheritedDueDate != nil && userSetDueDate == nil {
            effectiveDueDate = inheritedDueDate
        }
        else if inheritedDueDate!.compare(userSetDueDate!) == .OrderedAscending {
            effectiveDueDate = inheritedDueDate
        }
        else {
            effectiveDueDate = userSetDueDate
        }
    }
    
    func inheritDueDate(date: NSDate?) {
        inheritedDueDate = date
        setEffectiveDueDate()
        LocalParseManager.sharedManager.saveLocally(self)
        
        // recurse
        LocalParseManager.sharedManager.fetchDependenciesOfActionInBackground(self) { (results, error) -> Void in
            if let dependencies = results as? [Action] {
                for dependency in dependencies {
                    dependency.inheritDueDate(self.effectiveDueDate)
                }
            }
        }
    }
    
    func setDueDate(date: NSDate?) {
        userSetDueDate = date
        setEffectiveDueDate()
        LocalParseManager.sharedManager.saveLocally(self)
        
        // recurse
        LocalParseManager.sharedManager.fetchDependenciesOfActionInBackground(self) { (results, error) -> Void in
            if let dependencies = results as? [Action] {
                for dependency in dependencies {
                    dependency.inheritDueDate(self.effectiveDueDate)
                }
            }
        }
    }
    
    
    
    //
    //
    //
    //
    // MARK: Constants
    
    struct FieldKeys {
        static let User = "user"
        static let Name = "name"
        static let ParentAction = "parentAction"
        static let Ancestors = "ancestors"
        static let Depth = "depth"
        static let IsLeaf = "isLeaf"
        static let InSandbox = "inSandbox"
        static let WorkConclusion = "workConclusion"
        static let Trashed = "trashed"
        static let NumberOfDependencies = "numberOfDependencies"
        static let NumberOfInProgressDependencies = "numberOfInProgressDependencies"
        static let InheritedDueDate = "inheritedDueDate"
        static let UserSetDueDate = "userSetDueDate"
        static let EffectiveDueDate = "effectiveDueDate"
    }
    
    
    
    //
    //
    //
    //
    // MARK: Convenience methods
    
    func invalidate() {
        guard workConclusion == nil else { return } // throw?
        
        let manager = LocalParseManager.sharedManager
        let workUnit = manager.createWorkUnitForAction(self)
        workUnit.setType(.Invalidation)
        workConclusion = workUnit
        
        manager.fetchParentOfAction(self, withBlock: { (result, error) in
            if let parentAction = result as? Action {
                parentAction.numberOfInProgressDependencies--
                manager.saveLocally(parentAction)
            }
        })
        
        manager.saveLocally(self)
        
        let resultsBlock: PFArrayResultBlock = { (results, error) in
            if let dependencies = results as? [Action] {
                for dependency in dependencies {
                    dependency.invalidate()
                }
            }
        }
        manager.fetchDependenciesOfActionInBackground(self, withBlock: resultsBlock)
    }
    
    func complete() {
        guard workConclusion == nil else { return } // throw?
        
        let manager = LocalParseManager.sharedManager
        let workUnit = manager.createWorkUnitForAction(self)
        workUnit.setType(.Completion)
        workConclusion = workUnit
        
        
        manager.fetchParentOfAction(self, withBlock: { (result, error) in
            if let parentAction = result as? Action {
                parentAction.numberOfInProgressDependencies--
                manager.saveLocally(parentAction)
            }
        })
        
        manager.saveLocally(self)
        
        let resultsBlock: PFArrayResultBlock = { (results, error) in
            if let dependencies = results as? [Action] {
                for dependency in dependencies {
                    dependency.complete()
                }
            }
        }
        manager.fetchDependenciesOfActionInBackground(self, withBlock: resultsBlock)
    }
    
    func reactivate() {
        guard workConclusion != nil else { return } // throw?
        
        let manager = LocalParseManager.sharedManager
        let workUnit = manager.createWorkUnitForAction(self)
        workUnit.type = WorkUnit.WorkUnitType.Reactivation.rawValue
        workConclusion = nil
        manager.saveLocally(self)
        
        manager.fetchParentOfAction(self, withBlock: { (result, error) in
            if let parentAction = result as? Action {
                parentAction.numberOfInProgressDependencies++
                manager.saveLocally(parentAction)
            }
        })
    }
    
    func trash() {
        guard isLeaf == true else { return } // throw?
        
        self.trashed = true
        
        let manager = LocalParseManager.sharedManager
        manager.fetchParentOfAction(self, withBlock: { (result, error) in
            if let parentAction = result as? Action {
                parentAction.numberOfDependencies--
                parentAction.numberOfInProgressDependencies--
                manager.saveLocally(parentAction)
            }
        })
        manager.saveLocally(self)
    }
}