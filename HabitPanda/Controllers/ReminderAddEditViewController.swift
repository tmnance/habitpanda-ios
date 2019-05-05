//
//  ReminderAddEditViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/4/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class ReminderAddEditViewController: UIViewController {
    typealias FrequencyOption = DayOfWeek.WeekSubsetType
    typealias FrequencyDay = DayOfWeek.Day

    @IBOutlet weak var parentScrollView: UIScrollView!
    @IBOutlet weak var frequencyOptionsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var frequencyDaysView: UIStackView!

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var timePicker: UIDatePicker!

    var parentHabit: Habit? {
        didSet {
            self.viewModel.parentHabit = parentHabit
        }
    }

    private var viewModel = ReminderDetailsViewModel()

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
    }
}


// MARK: - Field Setup Methods
extension ReminderAddEditViewController {
    func setupFieldStylesAndBindings() {
        saveButton.isEnabled = false

        timePicker.datePickerMode = .time
        timePicker.minuteInterval = Constants.TimePicker.minuteInterval

        frequencyOptionsSegmentedControl.setTitleTextAttributes(
            [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15)],
            for: .normal
        )

        viewModel.interactionMode.bind { [unowned self] (_) in
            self.updateInteractionMode()
        }

        viewModel.time.bind { [unowned self] (value) in
            let hour = value.hour
            let minute = value.minute
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat =  "HH:mm"
            if let date = dateFormatter.date(from: "\(hour):\(minute)") {
                self.timePicker.setDate(date, animated: false)
            }
        }

        viewModel.frequencyDays.bind { [unowned self] (_) in
            self.updateFrequencyDays()
            self.validateInput()
        }
    }
}


// MARK: - Add/Edit Mode Context Methods
extension ReminderAddEditViewController {
    func setParentHabit(_ habit: Habit) {
        viewModel.parentHabit = habit
    }

    func setSelectedReminder(_ reminder: Reminder) {
        viewModel.selectedReminder = reminder
    }

    func updateInteractionMode() {
        switch viewModel.interactionMode.value {
        case .Add:
            title = "Add a New Reminder"
            break
        case .Edit:
            title = "Edit Reminder"
            break
        default:
            break
        }
    }
}


// MARK: - Top Nav Bar Methods
extension ReminderAddEditViewController {
    // MARK: Top Nav Button Pressed Methods

    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        if !isValidInput() {
            return
        }
        viewModel.saveReminder()
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
        return viewModel.frequencyDays.value.count > 0
    }
}


// MARK: - Time Methods
extension ReminderAddEditViewController {
    @IBAction func timePickerChanged(_ sender: UIDatePicker) {
        let components = Calendar.current.dateComponents(
            [.hour, .minute],
            from: sender.date
        )
        viewModel.time.value = TimeOfDay(hour: components.hour!, minute: components.minute!)
    }
}


// MARK: - Frequency Methods
extension ReminderAddEditViewController {
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
