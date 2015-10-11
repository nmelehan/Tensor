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
    
    // MARK: - Methods
    
    func markActionAsCompleted() {
        guard let action = task else {
            return
        }
        
        print("markActionAsCompleted()")
        
        let manager = LocalParseManager.sharedManager
        
        let workUnit = manager.createWorkUnitForAction(action)
        workUnit.type = WorkUnit.WorkUnitType.Completion.rawValue
        action.workHistory?.append(workUnit)
        action.workConclusion = workUnit
        
        manager.saveLocally(action)
    }
    
    func returnActionToInProgress() {
        guard let action = task else {
            return
        }
        
        print("returnActionToInProgress()")
        
        let manager = LocalParseManager.sharedManager
        
        let workUnit = manager.createWorkUnitForAction(action)
        workUnit.type = WorkUnit.WorkUnitType.Reactivation.rawValue
        action.workHistory?.append(workUnit)
        action.workConclusion = nil
        
        manager.saveLocally(action)
    }
    
    // MARK: - IBOutlets

    @IBOutlet weak var taskNameTextField: UITextField!
    @IBOutlet weak var completionStatusSwitch: UISwitch!
    
    // MARK: - IBActions
    
    @IBAction func completionStatusSwitchValueChanged() {
        switch completionStatusSwitch.on {
        case true: markActionAsCompleted()
        case false: returnActionToInProgress()
        }
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        taskNameTextField.text = task?.name
        
        if  let workConclusionType = task?.workConclusion?.getType()
            where workConclusionType == .Completion
        {
            completionStatusSwitch.on = true
        }
        else {
            completionStatusSwitch.on = false
        }
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
