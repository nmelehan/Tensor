//
//  WorkUnitTableViewCell.swift
//  Tensor
//
//  Created by Nathan Melehan on 10/10/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit

class WorkUnitTableViewCell: UITableViewCell {

    var workUnit: WorkUnit? {
        didSet {
            updateUI()
        }
    }
    
    func labelForDuration(seconds: Int) -> String {
        switch seconds {
        case 0..<60: return "\(seconds) seconds"
        case 60..<3600: return "\(seconds/60) minutes"
        case 3600..<86400: return "\(seconds/3600) hours"
        default: return "\(seconds) seconds"
        }
    }
    
    func updateUI() {
        self.textLabel?.text = workUnit?.action?.name
        
//        let detailText: String
//        if  let type = workUnit?.getType()
//        {
//            switch type {
//            case .Completion: detailText = "Completion"
//            case .Invalidation: detailText = "Invalidation"
//            default: detailText = ""
//            }
//        }
//        else {
//            detailText = "In Progress"
//        }
        
        if let type = workUnit?.getType() {
            let labelText: String
            switch type {
            case .Progress:
                if let duration = workUnit?.duration {
                    labelText = "\(type.rawValue), \(labelForDuration(Int(duration)))"
                }
                else {
                    fallthrough
                }
            default: labelText = type.rawValue
            }
            self.detailTextLabel?.text = labelText
        }
    }

}
