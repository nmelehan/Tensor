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
    
    //
    //
    //
    //
    // MARK: - IBOutlets
    
    
    @IBOutlet weak var authenticationButton: UIButton!
    
    //
    //
    //
    //
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateAuthenticationButtonLabel()
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
