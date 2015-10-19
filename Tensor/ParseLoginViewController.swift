//
//  ParseLoginViewController.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/19/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit
import Parse

protocol ParseLoginViewControllerDelegate {
    func parseLoginViewController(plvc: ParseLoginViewController, didAuthenticateUser user: PFUser)
    func parseLoginViewControllerDidCancel(plvc: ParseLoginViewController)
}

class ParseLoginViewController: UIViewController, UITextFieldDelegate {
    
    // Mark: - Properties
    
    var delegate: ParseLoginViewControllerDelegate?
    
    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let user = PFUser.currentUser() {
            print(user)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // MARK: - IBActions
    
    @IBAction func signupButtonPressed()
    {
        guard   let email = emailTextField.text,
                let password = passwordTextField.text
                where !email.isEmpty && !password.isEmpty
        else {
            return
        }
        
        let trimmedEmail = email.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        let user = PFUser.currentUser() ?? PFUser()
        user.username = trimmedEmail.lowercaseString
        user.email = trimmedEmail.lowercaseString
        user.password = password
        
        user.signUpInBackgroundWithBlock { (succeeded, error) -> Void in
            if error != nil {
                print("signup error occurred")
            }
            else {
                self.delegate?.parseLoginViewController(self, didAuthenticateUser: user)
            }
        }
    }
    
    @IBAction func cancelButtonPressed() {
        self.delegate?.parseLoginViewControllerDidCancel(self)
    }
    
    @IBAction func loginButtonPressed()
    {
        guard   let email = emailTextField.text,
                let password = passwordTextField.text
                where !email.isEmpty && !password.isEmpty
        else {
            return
        }
        
        let trimmedEmail = email.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        PFUser.logInWithUsernameInBackground(trimmedEmail.lowercaseString, password:password) {
            (user: PFUser?, error: NSError?) -> Void in
            if user != nil {
                // Do stuff after successful login.
                self.delegate?.parseLoginViewController(self, didAuthenticateUser: user!)
            } else {
                // The login failed. Check error to see why.
                let errorString = error?.userInfo["error"] as? NSString
                print(errorString)
            }
        }
    }

    @IBAction func resetPasswordButtonPressed()
    {
        guard   let email = emailTextField.text
                where !email.isEmpty
        else {
            return
        }
        
        let trimmedEmail = email.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        PFUser.requestPasswordResetForEmailInBackground(trimmedEmail.lowercaseString)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
