//
//  AppSettings.swift
//  Tensor
//
//  Created by Nathan Melehan on 10/25/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import Foundation

struct AppSettings {

    //
    //
    //
    //
    // MARK: - Notification constants

    // Naming pattern:
    // "Will": posted before pinInBackgroundWithBlock: is called
    // "Did": posted from block passed to pinInBackgroundWithBlock: on success
    // "DidFailTo": posted from block passed to pinInBackgroundWithBlock: on error
    struct Notifications {
        static let ShowCompletedAndInvalidatedActionsInPlanViewDidChange = "Tensor.Notifications.ShowCompletedAndInvalidatedActionsInPlanViewDidChange"
        static let ShowSkipsInWorkHistoryDidChange = "Tensor.Notifications.ShowSkipsInWorkHistoryDidChange"
    }
    
    struct Keys {
        static let ShowCompletedAndInvalidatedActionsInPlanView = "Tensor.AppSettings.Keys.ShowCompletedAndInvalidatedActionsInPlanView"
        static let ShowSkipsInWorkHistory = "Tensor.AppSettings.Keys.ShowSkipsInWorkHistory"
    }

}