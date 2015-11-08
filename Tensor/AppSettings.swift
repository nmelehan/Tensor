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
    // MARK: - Constants

    struct Notifications {
        static let UserDidChangeShowCompletedAndInvalidatedActionsInPlanView = "Tensor.AppSettings.Notifications.UserDidChangeShowCompletedAndInvalidatedActionsInPlanView"
        static let UserDidChangeShowSkipsInWorkHistory = "Tensor.AppSettings.Notifications.UserDidChangeShowSkipsInWorkHistory"
    }
    
    struct Keys {
        static let ShowCompletedAndInvalidatedActionsInPlanView = "Tensor.AppSettings.Keys.ShowCompletedAndInvalidatedActionsInPlanView"
        static let ShowSkipsInWorkHistory = "Tensor.AppSettings.Keys.ShowSkipsInWorkHistory"
    }

}