//
//  TaskDetailViewController.swift
//  Tensor
//
//  Created by Nathan Melehan on 9/12/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit
import Parse

class TaskDetailViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    
    var task: Action?
    
    // MARK: - IBOutlets

    @IBOutlet weak var taskNameTextField: UITextField!
    @IBOutlet weak var completionStatusSwitch: UISwitch!
    
    // MARK: - IBActions
    
    @IBAction func completionStatusSwitchChanged(sender: UISwitch) {
        if sender == completionStatusSwitch {
            task?.completionStatus = completionStatusSwitch.on
                ? Action.CompletionStatus.Completed.rawValue
                : Action.CompletionStatus.InProgress.rawValue
            if let action = task {
                LocalParseManager.sharedManager.saveLocally(action)
            }
        }
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        taskNameTextField.text = task?.name
        
        var setOn = false
        if let completionStatus = task?.completionStatus
            where completionStatus == Action.CompletionStatus.Completed.rawValue
        {
            setOn = true
        }
        completionStatusSwitch.setOn(setOn, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == taskNameTextField {
            task?.name = textField.text ?? ""
            if let action = task {
                LocalParseManager.sharedManager.saveLocally(action)
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
