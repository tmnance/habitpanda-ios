//
//  HabitAddEditViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/13/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class HabitAddEditViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var parentScrollView: UIScrollView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameInputField: UITextField!
    @IBOutlet weak var frequencySliderLabel: UILabel!
    @IBOutlet weak var frequencySlider: UISlider!
    @IBOutlet weak var frequencyOverflowInputField: UITextField!
    
    private var viewModel = HabitDetailsViewModel()
    let frequencySliderOverflowThreshold = 8
    let allowFrequencySliderOverflow = true

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
            for: .editingChanged
        )

        frequencySlider.addTarget(
            self,
            action: #selector(onSliderValChanged(slider:event:)),
            for: .valueChanged
        )

        frequencyOverflowInputField.delegate = self
        frequencyOverflowInputField.addTarget(
            self,
            action: #selector(self.updateFrequencyOverflow),
            for: .editingChanged
        )

        hideSliderOverflowField()

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
            if !isSliderOverflowActive() {
                self.frequencySlider.value = Float(
                    $0 > self.frequencySliderOverflowThreshold ? self.frequencySliderOverflowThreshold :
                        $0
                )
            }
            updateFrequencyDisplayText()
            validateInput()
        }
        
        viewModel.setOnDataLoad { [unowned self] in
            if (allowFrequencySliderOverflow &&
                viewModel.frequencyPerWeek.value >= frequencySliderOverflowThreshold
            ) {
                showSliderOverflowField()
                frequencyOverflowInputField.text = "\(viewModel.frequencyPerWeek.value)"
            } else {
                hideSliderOverflowField()
            }
        }
    }
}


// MARK: - Frequency Slider and Overflow Methods
extension HabitAddEditViewController {
    func updateFrequencyDisplayText() {
        self.frequencySliderLabel.text =
            viewModel.frequencyPerWeek.value >= frequencySliderOverflowThreshold ?
                self.viewModel.getFrequencyPerWeekDisplayText(
                    usingOverflowValue: frequencySliderOverflowThreshold
                ) :
                self.viewModel.getFrequencyPerWeekDisplayText()
    }

    func isSliderOverflowActive() -> Bool {
        return !frequencyOverflowInputField.isHidden
    }

    func showSliderOverflowField(andDoFocusInputField doFocusInputField: Bool = false) {
        guard allowFrequencySliderOverflow else {
            hideSliderOverflowField()
            return
        }
        guard !isSliderOverflowActive() else {
            return
        }
        frequencyOverflowInputField.isHidden = false
        if doFocusInputField {
            frequencyOverflowInputField.becomeFirstResponder()
        }
        updateFrequencyDisplayText()
        validateInput()
    }

    func hideSliderOverflowField() {
        frequencyOverflowInputField.isHidden = true
        frequencySlider.maximumValue = Float(
            allowFrequencySliderOverflow ? frequencySliderOverflowThreshold : frequencySliderOverflowThreshold - 1
        )
        frequencyOverflowInputField.text = ""
        self.view.endEditing(true)
        validateInput()
    }

    func textField(
        _ textField: UITextField,
       shouldChangeCharactersIn range: NSRange,
       replacementString string: String
    ) -> Bool {
        guard textField == frequencyOverflowInputField else {
            return true
        }
        if (textField.text!.count >= 2 && !string.isEmpty) {
            return false
        }
        let invalidCharacters = CharacterSet(charactersIn: "0123456789").inverted
        return (string.rangeOfCharacter(from: invalidCharacters) == nil)
    }

    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .ended:
                var value = Int(slider.value.rounded())
                if allowFrequencySliderOverflow {
                    if !isSliderOverflowActive() && value >= frequencySliderOverflowThreshold {
                        value = frequencySliderOverflowThreshold
                        showSliderOverflowField(andDoFocusInputField: true)
                    } else if isSliderOverflowActive() && value < frequencySliderOverflowThreshold {
                        hideSliderOverflowField()
                    }
                }
                if !isSliderOverflowActive() {
                    viewModel.frequencyPerWeek.value = value
                }
            default:
                break
            }
        }
    }

    @objc private func updateFrequencyOverflow(_ textField: UITextField) {
        guard textField == frequencyOverflowInputField else {
            return
        }
        if let num = Int(textField.text!) {
            textField.text = "\(num)"
            if num > 0 {
                viewModel.frequencyPerWeek.value = num
            }
        } else {
            textField.text = ""
        }
        self.validateInput()
    }

    @IBAction func frequencySliderChanged(_ sender: UISlider) {
        let value = Int(sender.value.rounded())
        // reassigning the value here causes the slider to snap to descrete integer values
        sender.value = Float(value)
        viewModel.frequencyPerWeek.value = value
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
        return viewModel.name.value.count > 0 && (!isSliderOverflowActive() || Int(frequencyOverflowInputField.text ?? "") ?? 0 > 0
        )
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
