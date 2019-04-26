//
//  AddEditHabitViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/13/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class AddEditHabitViewController: UIViewController {
    typealias FrequencyOption = Habit.FrequencyOption
    typealias FrequencyDay = Habit.FrequencyDay

    @IBOutlet weak var parentScrollView: UIScrollView!
    @IBOutlet weak var frequencyOptionsView: UIStackView!
    @IBOutlet weak var frequencyDaysView: UIStackView!

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameInputField: UITextField!

    @IBOutlet weak var reminderTimesTableView: UITableView!
    @IBOutlet weak var reminderTableViewHeightLayout: NSLayoutConstraint!

    private var viewModel = HabitViewModel()

    lazy var frequencyOptionUIButtons: [UIButton] = {
        var buttons: [UIButton] = []
        for case let button as UIButton in frequencyOptionsView.subviews {
            if let _ = FrequencyOption(rawValue: button.tag) {
                buttons.append(button)
            }
        }
        return buttons
    }()
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

        saveButton.isEnabled = false

        nameInputField.addTarget(
            self,
            action: #selector(self.validateInput),
            for: UIControl.Event.editingChanged
        )

        setupKeyboardDismissalWhenTapOutside()

        reminderTimesTableView.delegate = self
        reminderTimesTableView.dataSource = self
        reminderTimesTableView.separatorStyle = .none

        viewModel.interactionMode.bind { [unowned self] (_) in
            self.updateInteractionMode()
        }

        reminderTimesTableView.register(
            UINib(nibName: "EditableTimeCell", bundle: nil),
            forCellReuseIdentifier: "editableTimeCell"
        )

        viewModel.name.bind { [unowned self] in
            self.nameInputField.text = $0
            self.validateInput()
        }

        viewModel.frequencyDays.bind { [unowned self] (_) in
            self.updateFrequencyDays()
            self.validateInput()
        }

        viewModel.reminderTimes.bind { [unowned self] (_) in
            self.updateReminderTimes()
        }
    }
}


// MARK: - Add/Edit Mode Context Methods
extension AddEditHabitViewController {
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
extension AddEditHabitViewController {
    // MARK: Top Nav Button Pressed Methods

    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        if !isValidInput() {
            return
        }
        viewModel.saveHabit(nameInputField.text!)
        dismiss(animated: true)
    }

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    // MARK: Validation Methods

    @objc func validateInput() {
        saveButton.isEnabled = isValidInput()
    }

    func isValidInput() -> Bool {
        return nameInputField.text!.count > 0 && viewModel.frequencyDays.value.count > 0
    }
}


// MARK: - Keyboard Dismissal Methods
extension AddEditHabitViewController {
    func setupKeyboardDismissalWhenTapOutside() {
        // keyboard stuff
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)

        parentScrollView.keyboardDismissMode = .onDrag // .interactive
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            parentScrollView.contentInset = .zero
        } else {
            parentScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        parentScrollView.scrollIndicatorInsets = parentScrollView.contentInset
    }
}


// MARK: - Frequency Methods
extension AddEditHabitViewController {
    // MARK: Frequency Button Pressed Methods

    @IBAction func frequencyOptionButtonPressed(_ sender: MultiSelectButton) {
        if sender.isSelected {
            // already selected, no need to do anything
            return
        }

        let option = FrequencyOption(rawValue: sender.tag)!
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
        frequencyOptionUIButtons
            .forEach {
                let option = FrequencyOption(rawValue: $0.tag)!
                $0.isSelected = option == correctOption
            }
    }
}


// MARK: - Reminder Methods
extension AddEditHabitViewController {
    func updateReminderTimes() {
        reminderTimesTableView.reloadData()
        reminderTableViewHeightLayout.constant = CGFloat(
            tableView(reminderTimesTableView, numberOfRowsInSection: 0) * 46
        )
    }

    @IBAction func addReminderButtonPressed(_ sender: UIButton) {
        showSelectReminderTimePopup() { (_ hour: Int, _ minute: Int) in
            self.viewModel.addReminderTime(hour: hour, minute: minute)
        }
    }

    func createReminderDatePicker(
        hour: Int? = nil,
        minute: Int? = nil
    ) -> UIDatePicker {
        let datePicker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: 250, height: 300))
        datePicker.datePickerMode = .time
        datePicker.minuteInterval = HabitViewModelConstants.timePickerMinuteInterval
        datePicker.setDate(
            Date().rounded(
                minutes: TimeInterval(HabitViewModelConstants.timePickerMinuteInterval),
                rounding: .floor
            ),
            animated: false
        )

        // set initial value if present
        if let editHour = hour, let editMinute = minute {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat =  "HH:mm"
            if let date = dateFormatter.date(from: "\(editHour):\(editMinute)") {
                datePicker.setDate(date, animated: false)
            }
        }

        return datePicker
    }

    func showSelectReminderTimePopup(
        hour: Int? = nil,
        minute: Int? = nil,
        completion: @escaping (_ hour: Int, _ minute: Int) -> ()
    ) {
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: 250, height: 300)

        let datePicker = createReminderDatePicker(hour: hour, minute: minute)
        vc.view.addSubview(datePicker)

        let alert = UIAlertController(
            title: "Choose a reminder time",
            message: "",
            preferredStyle: .alert
        )

        // TODO: This call is potentially problematic since it exploits an undocumented API and is
        // causing the following warning: "A constraint factory method was passed a nil layout
        // anchor. This is not allowed, and may cause confusing exceptions."
        alert.setValue(vc, forKey: "contentViewController")

        alert.addAction(UIAlertAction(title: "OK", style: .default) { (action) in
            let components = Calendar.current.dateComponents(
                [.hour, .minute],
                from: datePicker.date
            )
            completion(components.hour!, components.minute!)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if presentedViewController == nil {
            // only present if any no other alert is already shown
            present(alert, animated: true, completion: nil)
        }
    }
}


// MARK: - Tableview Datasource Methods
extension AddEditHabitViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.reminderTimes.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "editableTimeCell",
            for: indexPath
        ) as! EditableTimeCell
        let reminder = viewModel.reminderTimes.value[indexPath.row]
        cell.hour = Int(reminder.hour)
        cell.minute = Int(reminder.minute)

        cell.onEditButtonPressed = {
            self.showSelectReminderTimePopup(
                hour: cell.hour,
                minute: cell.minute
            ) { (_ hour: Int, _ minute: Int) in
                if hour == reminder.hour && minute == reminder.minute {
                    // nothing changed, do nothing
                    return
                }
                // simpler to just remove and re-add to prevent duplicates
                self.viewModel.removeReminderTime(atIndex: indexPath.row)
                self.viewModel.addReminderTime(hour: hour, minute: minute)
            }
        }
        cell.onRemoveButtonPressed = {
            self.viewModel.removeReminderTime(atIndex: indexPath.row)
        }

        cell.updateTimeDisplay()
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
