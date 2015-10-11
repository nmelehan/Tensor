//
//  TableViewTaskCell.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/3/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit

class TableViewTaskCell: UITableViewCell {
    
    var task: Action? {
        didSet {
            updateUI()
        }
    }
    
    func updateUI() {
        self.textLabel?.text = task?.name
        
        let detailText: String
        if  let workConclusionType = self.task?.workConclusion?.getType()
        {
            switch workConclusionType {
            case .Completion: detailText = "Completed"
            case .Invalidation: detailText = "Invalidated"
            default: detailText = ""
            }
        }
        else {
            detailText = "In Progress"
        }
        self.detailTextLabel?.text = detailText
    }
    
}
