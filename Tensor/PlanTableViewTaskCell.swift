//
//  PlanTableViewTaskCell.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/3/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit

class PlanTableViewTaskCell: UITableViewCell {
    
    var task: Action? {
        didSet {
            updateUI()
        }
    }
    
    func updateUI() {
        self.textLabel?.text = task?.name
    }
}
