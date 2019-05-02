//
//  HabitAddEditViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/13/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class HabitAddEditViewController: UIViewController {
    typealias FrequencyOption = Habit.FrequencyOption
    typealias FrequencyDay = Habit.FrequencyDay

    @IBOutlet weak var parentScrollView: UIScrollView!
    @IBOutlet weak var frequencyOptionsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var frequencyDaysView: UIStackView!

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameInputField: UITextField!

    private var viewModel = HabitViewModel()

    lazy var frequencyDayUIButtons: [UIButton] = {
        var buttons: [UIButton] = []
        for case let buttonRow as UIStackView in frequencyDaysView.subviews {
            for case let button as UIButton in buttonRow.subviews {
                if let _ = FrequencyDay(rawValue: button.tag) {
                    buttons.append(button)
                }
            }
        }
        return buttons
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupFieldStylesAndBindings()
        setupKeyboardDismissalWhenTapOutside()
    }
}


// MARK: - Field Setup Methods
extension HabitAddEditViewController {
    func setupFieldStylesAndBindings() {
        saveButton.isEnabled = false

        nameInputField.addTarget(
            self,
            action: #selector(self.updateName),
            for: UIControl.Event.editingChanged
        )

        frequencyOptionsSegmentedControl.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15)],
            for: .normal
        )

        viewModel.interactionMode.bind { [unowned self] (_) in
            self.updateInteractionMode()
        }

        viewModel.name.bind { [unowned self] in
            self.nameInputField.text = $0
            self.validateInput()
        }

        viewModel.frequencyDays.bind { [unowned self] (_) in
            self.updateFrequencyDays()
            self.validateInput()
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
        case .Add:
            title = "Create a New Habit"
            break
        case .Edit:
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
        viewModel.saveHabit()
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
        return viewModel.name.value.count > 0 && viewModel.frequencyDays.value.count > 0
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
    // MARK: Frequency Button Pressed Methods

    @IBAction func frequencyOptionsSegmentedControlIndexChanged(_ sender: UISegmentedControl) {
        let option = FrequencyOption(
            rawValue: sender.selectedSegmentIndex
        )!
        viewModel.updateFrequencyDays(forOption: option)
    }

    @IBAction func frequencyDayButtonPressed(_ sender: MultiSelectButton) {
        let day = FrequencyDay(rawValue: sender.tag)!
        viewModel.toggleFrequencyDay(day)
    }

    func updateFrequencyDays() {
        frequencyDayUIButtons
            .forEach {
                let day = FrequencyDay(rawValue: $0.tag)!
                $0.isSelected = self.viewModel.frequencyDays.value.contains(day)
            }

        let correctOption = viewModel.getFrequencyOption()
        frequencyOptionsSegmentedControl.selectedSegmentIndex = correctOption.rawValue
    }
}
