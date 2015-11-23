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
    
    
    
    //
    //
    //
    //
    // MARK: - Properties
    
    var task: Action?
//    {
//        didSet { updateUI() }
//    }
    
    
    
    //
    //
    //
    //
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
        
        action.reactivate()
        completionStatusSwitch.enabled = true
        invalidationStatusSwitch.enabled = true
    }
    
    func updateUI() {
        taskNameTextField.text = task?.name
        
        if let dueDateSetting = task?.getDueDateSetting() {
            dueDateSettingTextField.text = dueDateSettingPrompts[dueDateSetting]
        }
        else {
            dueDateSettingTextField.text = dueDateSettingPrompts[dueDateSettingPromptOrdering.first!]
        }
        
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
        
        if  let action = task
            where (action.isLeaf == false || action.trashed == true)
        {
            deleteButton.enabled = false
        }
    }
    
    func actionDidUpdate(notification: NSNotification) {
        if let action = notification.object as? Action where action == task {
            updateUI()
        }
    }
    
    
    
    //
    //
    //
    //
    // MARK: - IBOutlets

    @IBOutlet weak var taskNameTextField: UITextField!
    @IBOutlet weak var completionStatusSwitch: UISwitch!
    @IBOutlet weak var invalidationStatusSwitch: UISwitch!
    @IBOutlet weak var deleteButton: UIButton!

    @IBOutlet weak var dueDateSettingInputView: UIView!
    @IBOutlet weak var dueDateSettingInputViewPicker: UIPickerView!
    @IBOutlet weak var dueDateSettingTextField: UITextField!
    @IBOutlet weak var dueDateValueTextField: UITextField!
    
    
    
    //
    //
    //
    //
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
    
    @IBAction func deleteButtonPressed(sender: AnyObject) {
        task?.trash()
    }
    
    @IBAction func dueDateSettingInputViewSelectButtonPressed() {
        let selectedRow = dueDateSettingInputViewPicker.selectedRowInComponent(0)
        
        task?.setDueDateSetting(dueDateSettingPromptOrdering[selectedRow])
        if let action = task {
            LocalParseManager.sharedManager.saveLocally(action)
        }
        dueDateSettingTextField.text = self.pickerView(dueDateSettingInputViewPicker,
            titleForRow: selectedRow, forComponent: 0)
        
        dueDateSettingTextField.resignFirstResponder()
    }
    
    
    //
    //
    //
    //
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dueDateSettingTextField.inputView = dueDateSettingInputView
//        dueDateSettingTextField.inputAccessoryView = pickerInputAccessoryView
        
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
    
    
    
    //
    //
    //
    //
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
    
    
    
    //
    //
    //
    //
    // MARK: - UIPickerViewDelegate, UIPickerViewDataSource
    
    let dueDateSettingPrompts: [Action.AttributeSettingMethod : String] = [
        .Inherit: "Inherit from parent action",
        .SetByUser: "Choose a date"
    ]
    let dueDateSettingPromptOrdering: [Action.AttributeSettingMethod] = [.Inherit, .SetByUser]
    
    // The number of columns of data
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dueDateSettingPromptOrdering.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dueDateSettingPrompts[dueDateSettingPromptOrdering[row]]
    }
    
    
    
    //
    //
    //
    //
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
