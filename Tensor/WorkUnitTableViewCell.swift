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
        self.detailTextLabel?.text = workUnit?.getType()?.rawValue
    }

}
