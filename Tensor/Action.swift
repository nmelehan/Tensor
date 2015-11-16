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
    
    func trash() {
        guard isLeaf == true else { return } // throw?
        
        self.trashed = true
        LocalParseManager.sharedManager.saveLocally(self)
    }
}