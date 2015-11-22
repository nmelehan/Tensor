//
//  AppSettingsTableViewController.swift
//  Tensor
//
//  Created by Nathan Melehan on 10/25/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit
import Parse

class AppSettingsTableViewController: UITableViewController, ParseLoginViewControllerDelegate {
    
    //
    //
    //
    //
    // MARK: - Methods
    
    func updateAuthenticationButtonLabel() {
        if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {
            authenticationButton.setTitle("Log In", forState: UIControlState.Normal)
        }
        else {
            authenticationButton.setTitle("Log Out", forState: UIControlState.Normal)
        }
    }
    
    func updateUI() {
        updateAuthenticationButtonLabel()
        
        showCompletedAndInvalidatedActionsSwitch.on = NSUserDefaults
            .standardUserDefaults()
            .boolForKey(AppSettings.Keys.ShowCompletedAndInvalidatedActionsInPlanView)
        
        showSkipsInWorkHistorySwitch.on = NSUserDefaults
            .standardUserDefaults()
            .boolForKey(AppSettings.Keys.ShowSkipsInWorkHistory)
    }
    

    
    //
    //
    //
    //
    // MARK: - IBOutlets
    
    @IBOutlet weak var authenticationButton: UIButton!
    @IBOutlet weak var showCompletedAndInvalidatedActionsSwitch: UISwitch!
    @IBOutlet weak var showSkipsInWorkHistorySwitch: UISwitch!
    
    
    
    //
    //
    //
    //
    // MARK: - IBActions
    
    @IBAction func showCompletedAndInvalidatedActionsSwitchValueChanged() {
        let showConcludedActions = showCompletedAndInvalidatedActionsSwitch.on
        
        NSUserDefaults.standardUserDefaults()
            .setBool(showConcludedActions,
                forKey: AppSettings.Keys.ShowCompletedAndInvalidatedActionsInPlanView)
        let userInfo = [AppSettings.Keys.ShowCompletedAndInvalidatedActionsInPlanView : showConcludedActions]
        NSNotificationCenter.defaultCenter()
            .postNotificationName(AppSettings.Notifications.UserDidChangeShowCompletedAndInvalidatedActionsInPlanView,
                object: nil,
                userInfo: userInfo)
    }
    
    @IBAction func showSkipsInWorkHistorySwitchValueChanged() {
        let showSkips = showSkipsInWorkHistorySwitch.on
        
        NSUserDefaults.standardUserDefaults()
            .setBool(showSkips, forKey: AppSettings.Keys.ShowSkipsInWorkHistory)
        let userInfo = [AppSettings.Keys.ShowSkipsInWorkHistory : showSkips]
        NSNotificationCenter.defaultCenter()
            .postNotificationName(AppSettings.Notifications.UserDidChangeShowSkipsInWorkHistory,
                object: nil,
                userInfo: userInfo)
    }
    
    @IBAction func migrateToAncestoryArrayButtonPressed(sender: AnyObject) {
        LocalParseManager.sharedManager.migrateToAncestorArray()
    }
    
    @IBAction func migrateToTrashedFieldButtonPressed(sender: AnyObject) {
        LocalParseManager.sharedManager.migrateToTrashedField()
    }
    
    @IBAction func migrateToDependencyCountButtonPressed(sender: AnyObject) {
        LocalParseManager.sharedManager.migrateToDependencyCount()
    }
    
    
    
    // 
    //
    //
    //
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    //
    //
    //
    //
    // MARK: - ParseLoginViewControllerDelegate
    
    func parseLoginViewController(plvc: ParseLoginViewController, didAuthenticateUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
        updateAuthenticationButtonLabel()
        LocalParseManager.sharedManager.becomeUser(user)
    }
    
    func parseLoginViewControllerDidCancel(plvc: ParseLoginViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    //
    //
    //
    //
    // MARK: - Navigation
    
    struct Storyboard {
        static let ShowAuthenticationUISegueIdentifier = "Show Authentication UI"
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ShowAuthenticationUISegueIdentifier:
                if let dvc = segue.destinationViewController as? ParseLoginViewController {
                    dvc.delegate = self
                }
            default: break
            }
        }
    }

}
