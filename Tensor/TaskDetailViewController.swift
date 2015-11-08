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
//    {
//        didSet { updateUI() }
//    }
    
    // MARK: - Methods
    
    func stopProgress() {
        let resultBlock: PFObjectResultBlock = { (result, error) in
            if let scheduler = result as? Scheduler {
                if  let actionInProgress = scheduler.workUnitInProgress?.action
                    where actionInProgress == self.task
                {
                    scheduler.pauseWorkUnitInProgress()
                }
                scheduler.refreshScheduledActions(preserveCurrentAction: false)
            }
        }
        
        LocalParseManager.sharedManager
            .fetchSchedulerInBackgroundWithBlock(resultBlock)
    }
    
    func markActionAsCompleted() {
        guard let action = task else {
            return
        }
        
        stopProgress()
        action.complete()
        invalidationStatusSwitch.enabled = false
    }
    
    func markActionAsInvalidated() {
        guard let action = task else {
            return
        }
        
        stopProgress()
        action.invalidate()
        completionStatusSwitch.enabled = false
    }
    
    func returnActionToInProgress() {
        guard let action = task else {
            return
        }
        
        let manager = LocalParseManager.sharedManager
        let workUnit = manager.createWorkUnitForAction(action)
        workUnit.type = WorkUnit.WorkUnitType.Reactivation.rawValue
        action.workConclusion = nil
        manager.saveLocally(action)
        
        completionStatusSwitch.enabled = true
        invalidationStatusSwitch.enabled = true
    }
    
    func updateUI() {
        taskNameTextField.text = task?.name
        
        if  let workConclusionType = task?.workConclusion?.getType()
            where workConclusionType == .Completion
        {
            completionStatusSwitch.on = true
            invalidationStatusSwitch.enabled = false
        }
        else {
            completionStatusSwitch.on = false
        }
        
        if  let workConclusionType = task?.workConclusion?.getType()
            where workConclusionType == .Invalidation
        {
            invalidationStatusSwitch.on = true
            completionStatusSwitch.enabled = false
        }
        else {
            invalidationStatusSwitch.on = false
        }
    }
    
    func actionDidUpdate(notification: NSNotification) {
        if let action = notification.object as? Action where action == task {
            updateUI()
        }
    }
    
    // MARK: - IBOutlets

    @IBOutlet weak var taskNameTextField: UITextField!
    @IBOutlet weak var completionStatusSwitch: UISwitch!
    @IBOutlet weak var invalidationStatusSwitch: UISwitch!
    
    // MARK: - IBActions
    
    @IBAction func completionStatusSwitchValueChanged() {
        switch completionStatusSwitch.on {
        case true: markActionAsCompleted()
        case false: returnActionToInProgress()
        }
    }
    
    @IBAction func invalidationStatusSwitchValueChanged() {
        switch invalidationStatusSwitch.on {
        case true: markActionAsInvalidated()
        case false: returnActionToInProgress()
        }
    }
    
    @IBAction func focusOnActionButtonPressed() {
        let resultBlock: PFObjectResultBlock = { (result, error) in
            if let scheduler = result as? Scheduler {
                scheduler.actionFocus = self.task
                scheduler.refreshScheduledActions(preserveCurrentAction: false)
            }
        }
        
        LocalParseManager.sharedManager
            .fetchSchedulerInBackgroundWithBlock(resultBlock)
    }
    
    @IBAction func immediatelyScheduleButtonPressed() {
        let resultBlock: PFObjectResultBlock = { (result, error) in
            if  let scheduler = result as? Scheduler,
                let action = self.task
            {
                scheduler.immediatelyScheduleAction(action)
            }
        }
        
        LocalParseManager.sharedManager
            .fetchSchedulerInBackgroundWithBlock(resultBlock)
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "actionDidUpdate:",
            name: LocalParseManager.Notifications.LocalDatastoreDidUpdateAction,
            object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
    
    // MARK: - Navigation
    
    struct Storyboard {
        static let ShowWorkHistoryForActionSegueIdentifier = "Show Work History For Action"
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.ShowWorkHistoryForActionSegueIdentifier:
                if let dvc = segue.destinationViewController as? WorkHistoryTableViewController {
                    dvc.action = self.task
                }
            default: break
            }
        }
    }
}
