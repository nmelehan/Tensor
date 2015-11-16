//
//  AppDelegate.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/2/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit

import Bolts
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        // Enable storing and querying data from Local Datastore.
        // Remove this line if you don't want to use Local Datastore features or want to use cachePolicy.
        Parse.enableLocalDatastore()
        
        // ****************************************************************************
        // Uncomment this line if you want to enable Crash Reporting
        // ParseCrashReporting.enable()
        //
        // Uncomment and fill in with your Parse credentials:
        // Parse.setApplicationId("your_application_id", clientKey: "your_client_key")
        
        
        // need to make sure these are called before setApplicationID 
        // so PFObject subclassing works
        Action.initialize()
        Scheduler.initialize()
        WorkUnit.initialize()
        
        let path = NSBundle.mainBundle().pathForResource("AuthorizationTokens", ofType: "plist")
        if let tokensDictionary = NSDictionary(contentsOfFile: path!)?.objectForKey("Parse Authorization Tokens")
        {
            let applicationId = tokensDictionary.objectForKey("Application ID") as! String
            let clientKey = tokensDictionary.objectForKey("Client Key") as! String
            Parse.setApplicationId(applicationId, clientKey: clientKey)
        }
        
        //
        // If you are using Facebook, uncomment and add your FacebookAppID to your bundle's plist as
        // described here: https://developers.facebook.com/docs/getting-started/facebook-sdk-for-ios/
        // Uncomment the line inside ParseStartProject-Bridging-Header and the following line here:
        // PFFacebookUtils.initializeFacebook()
        // ****************************************************************************
        
        PFUser.enableAutomaticUser()
        
        let defaultACL = PFACL();
        
        // If you would like all objects to be private by default, remove this line.
//        defaultACL.setPublicReadAccess(true)
        
        PFACL.setDefaultACL(defaultACL, withAccessForCurrentUser:true)
        
        if application.applicationState != UIApplicationState.Background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.respondsToSelector("backgroundRefreshStatus")
            let oldPushHandlerOnly = !self.respondsToSelector("application:didReceiveRemoteNotification:fetchCompletionHandler:")
            var noPushPayload = false;
            if let options = launchOptions {
                noPushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil;
            }
            if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
            }
        }
        if application.respondsToSelector("registerUserNotificationSettings:") {
            let userNotificationTypes: UIUserNotificationType = [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            let types: UIRemoteNotificationType = [UIRemoteNotificationType.Badge, UIRemoteNotificationType.Alert, UIRemoteNotificationType.Sound]
            application.registerForRemoteNotificationTypes(types)
        }
        
        
        
//        LocalParseManager.sharedManager.migrateToAncestorArray()
//        LocalParseManager.sharedManager.migrateToTrashedField()
        
        registerDebuggingNotificationObservers()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    
    //
    //
    //
    //
    // MARK: - Debugging Notification Observers
    
//    static let LocalDatastoreInstallationRequested = "Tensor.LocalDatastoreInstallationRequestedNotification"
//    static let LocalDatastoreDidCompleteMinimumViableInstallation = "Tensor.LocalDatastoreDidCompleteMinimumViableInstallationNotification"
//    static let LocalDatastoreDidCompleteInstallation = "Tensor.LocalDatastoreDidCompleteInstallationNotification"
//    
//    static let LocalDatastoreDidFetchSchedulerFromCloud = "Tensor.LocalDatastoreDidFetchSchedulerFromCloudNotification"
//    static let LocalDatastoreDidFetchActionsFromCloud = "Tensor.LocalDatastoreDidFetchActionsFromCloudNotification"
//    
//    static let LocalDatastoreWillAddAction = "Tensor.LocalDatastoreWillAddActionNotification"
//    static let LocalDatastoreDidAddAction = "Tensor.LocalDatastoreDidAddActionNotification"
//    static let LocalDatastoreDidFailToAddAction = "Tensor.LocalDatastoreDidFailToAddActionNotification"
//    
//    static let LocalDatastoreWillRemoveAction = "Tensor.LocalDatastoreWillRemoveActionNotification"
//    static let LocalDatastoreDidRemoveAction = "Tensor.LocalDatastoreDidRemoveActionNotification"
//    static let LocalDatastoreDidFailToRemoveAction = "Tensor.LocalDatastoreDidFailToRemoveActionNotification"
//    
//    static let LocalDatastoreWillUpdateAction = "Tensor.LocalDatastoreWillUpdateActionNotification"
//    static let LocalDatastoreDidUpdateAction = "Tensor.LocalDatastoreDidUpdateActionNotification"
//    static let LocalDatastoreDidFailToUpdateAction = "Tensor.LocalDatastoreDidFailToUpdateActionNotification"
//    
//    static let LocalDatastoreWillAddWorkUnit = "Tensor.LocalDatastoreWillAddWorkUnitNotification"
//    static let LocalDatastoreDidAddWorkUnit = "Tensor.LocalDatastoreDidAddWorkUnitNotification"
//    static let LocalDatastoreDidFailToAddWorkUnit = "Tensor.LocalDatastoreDidFailToAddWorkUnitNotification"
//    
//    static let LocalDatastoreWillUpdateWorkUnit = "Tensor.LocalDatastoreWillUpdateWorkUnitNotification"
//    static let LocalDatastoreDidUpdateWorkUnit = "Tensor.LocalDatastoreDidUpdateWorkUnitNotification"
//    static let LocalDatastoreDidFailToUpdateWorkUnit = "Tensor.LocalDatastoreDidFailToUpdateWorkUnitNotification"
    
    func registerDebuggingNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidAddAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidAddWorkUnit,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidCompleteInstallation,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidCompleteMinimumViableInstallation,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidFailToAddAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidFailToAddWorkUnit,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidFailToRemoveAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidFailToUpdateAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidFailToUpdateWorkUnit,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidFetchActionsFromCloud,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidFetchSchedulerFromCloud,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidRemoveAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidUpdateAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreDidUpdateWorkUnit,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreInstallationRequested,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreWillAddAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreWillAddWorkUnit,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreWillRemoveAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreWillUpdateAction,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: LocalParseManager.Notifications.LocalDatastoreWillUpdateWorkUnit,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: Scheduler.Notifications.SchedulerDidFailToRefreshScheduledActions,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: Scheduler.Notifications.SchedulerDidPauseWorkUnitInProgress,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: Scheduler.Notifications.SchedulerDidRefreshScheduledActions,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: AppSettings.Notifications.UserDidChangeShowCompletedAndInvalidatedActionsInPlanView,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "listenToNotification:",
            name: AppSettings.Notifications.UserDidChangeShowSkipsInWorkHistory,
            object: nil)
    }
    
    func listenToNotification(notification: NSNotification) {
        print("\n\(notification)")
    }
}

