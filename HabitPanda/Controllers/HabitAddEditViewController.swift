//
//  HabitAddEditViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/13/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class HabitAddEditViewController: UIViewController {
    @IBOutlet weak var parentScrollView: UIScrollView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameInputField: UITextField!
    @IBOutlet weak var frequencySliderLabel: UILabel!
    @IBOutlet weak var frequencySlider: UISlider!

    private var viewModel = HabitDetailsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupStylesAndBindings()
        setupKeyboardDismissalWhenTapOutside()
    }
}


// MARK: - Setup Methods
extension HabitAddEditViewController {
    func setupStylesAndBindings() {
        saveButton.isEnabled = false

        nameInputField.addTarget(
            self,
            action: #selector(self.updateName),
            for: UIControl.Event.editingChanged
        )

        viewModel.interactionMode.bind { [unowned self] (_) in
            self.updateInteractionMode()
        }

        viewModel.name.bind { [unowned self] in
            // don't want to reset cursor position while editing
            if self.nameInputField.text != $0 {
                self.nameInputField.text = $0
            }
            self.validateInput()
        }

        viewModel.frequencyPerWeek.bind { [unowned self] in
            self.frequencySlider.value = Float($0)
            self.frequencySliderLabel.text = self.viewModel.getFrequencyPerWeekDisplayText()
        }
    }
}


// MARK: - Add/Edit Mode Context Methods
extension HabitAddEditViewController {
    func setSelectedHabit(_ habit: Habit) {
        viewModel.selectedHabit = habit
    }

    func updateInteractionMode() {
        switch viewModel.interactionMode.value {
        case .add:
            title = "Create a New Habit"
            break
        case .edit:
            title = "Edit Habit"
            break
        default:
            break
        }
    }
}


// MARK: - Top Nav Bar Methods
extension HabitAddEditViewController {
    // MARK: Top Nav Button Pressed Methods

    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        if !isValidInput() {
            return
        }
        let isNew = viewModel.interactionMode.value == .add

        viewModel.saveHabit()
        if isNew {
            ToastHelper.makeToast("Habit added", state: .entityCreated)
        } else {
            ToastHelper.makeToast("Habit updated", state: .entityUpdated)
        }

        dismiss(animated: true)
    }

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    // MARK: Validation Methods

    func validateInput() {
        saveButton.isEnabled = isValidInput()
    }

    func isValidInput() -> Bool {
        return viewModel.name.value.count > 0
    }
}


// MARK: - Keyboard Dismissal Methods
extension HabitAddEditViewController {
    func setupKeyboardDismissalWhenTapOutside() {
        // keyboard stuff
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        let tap = UITapGestureRecognizer(
            target: self.view,
            action: #selector(UIView.endEditing(_:))
        )
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)

        parentScrollView.keyboardDismissMode = .onDrag // .interactive
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue =
            notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                return
            }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            parentScrollView.contentInset = .zero
        } else {
            parentScrollView.contentInset = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom,
                right: 0
            )
        }

        parentScrollView.scrollIndicatorInsets = parentScrollView.contentInset
    }
}


// MARK: - Name Methods
extension HabitAddEditViewController {
    @objc func updateName() {
        viewModel.name.value = nameInputField.text!
    }
}


// MARK: - Frequency Methods
extension HabitAddEditViewController {
    @IBAction func frequencySliderChanged(_ sender: UISlider) {
        let value = Int(sender.value)
        // reassigning the value here causes the slider to snap to descrete integer values
        sender.value = Float(value)
        viewModel.frequencyPerWeek.value = value
    }
}
