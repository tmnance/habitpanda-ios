//
//  AddHabitViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/13/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class AddHabitViewController: UIViewController {

    enum FrequencyOption :Int {
        case Daily = 0, Weekdays = 1, Custom = 2
    }
    enum FrequencyDay :Int {
        case Sun = 0, Mon = 1, Tue = 2, Wed = 3, Thu = 4, Fri = 5, Sat = 6
    }

    @IBOutlet weak var parentScrollView: UIScrollView!
    @IBOutlet weak var frequencyOptionsView: UIStackView!
    @IBOutlet weak var frequencyDaysView: UIStackView!

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameInputField: UITextField!

    @IBOutlet weak var reminderTimesTableView: UITableView!
    @IBOutlet weak var reminderTableViewHeightLayout: NSLayoutConstraint!

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var reminderTimes:[ReminderTime] = []

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

        reminderTimesTableView.register(
            UINib(nibName: "EditableTimeCell", bundle: nil),
            forCellReuseIdentifier: "editableTimeCell"
        )

        updateReminderTimes()
    }


    // MARK: - Add Data Methods

    func addHabit(_ text: String) {
        print("Wanting to add habit \(text)")

        let newHabit = Habit(context: context)
        newHabit.name = text
        newHabit.createdAt = Date()
        newHabit.uuid = UUID()

        reminderTimes.forEach { (reminder) in
            reminder.habit = newHabit
        }

        do {
            try context.save()
        } catch {
            print("Error saving context, \(error)")
        }
    }


    // MARK: - Validation Methods

    @objc func validateInput() {
        saveButton.isEnabled = isValidInput()
    }

    func isValidInput() -> Bool {
        return nameInputField.text!.count > 0 && getSelectedFrequencyDays().count > 0
    }


    // MARK: - Top Nav Button Pressed Methods

    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        if !isValidInput() {
            return
        }
        addHabit(nameInputField.text!)
        dismiss(animated: true)
    }

    @IBAction func cancelPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }


    // MARK: - Frequency Button Pressed Methods

    @IBAction func frequencyOptionButtonPressed(_ sender: MultiSelectButton) {
        if sender.isSelected {
            // already selected, no need to do anything
            return
        }

        let selectedOption = FrequencyOption(rawValue: sender.tag) ?? FrequencyOption.Daily
        setSelectedFrequencyOption(to: selectedOption)

        updateSelectedFrequencyDays()

        validateInput()
    }

    @IBAction func frequencyDayButtonPressed(_ sender: MultiSelectButton) {
        sender.isSelected = !sender.isSelected

        updateSelectedFrequencyOption()

        validateInput()
    }


    // MARK: - Frequency Value Changed Methods

    func updateSelectedFrequencyOption() {
        let selectedDays = getSelectedFrequencyDays()
        var newOption:FrequencyOption = .Custom

        if selectedDays.count == 7 {
            newOption = .Daily
        } else if selectedDays.count == 5 && (selectedDays.filter { ![.Sat, .Sun].contains($0) }).count == 5 {
            // exactly 5 items selected and they are all weekdays
            newOption = .Weekdays
        }

        if newOption != getSelectedFrequencyOption() {
            setSelectedFrequencyOption(to: newOption)
        }
    }

    func updateSelectedFrequencyDays() {
        if let selectedOption = getSelectedFrequencyOption() {
            switch selectedOption {
            case .Daily:
                getFrequencyDayUIButtons().forEach { $0.isSelected = true }
                break
            case .Weekdays:
                // select non-weekend buttons
                getFrequencyDayUIButtons().forEach {
                    $0.isSelected = ![.Sat, .Sun].contains(FrequencyDay(rawValue: $0.tag)!)
                }
                break
            case .Custom:
                // clear all selected
                getFrequencyDayUIButtons().forEach { $0.isSelected = false }
                break
            }
        }
    }


    // MARK: - Frequency Selected Value Setter Methods

    func setSelectedFrequencyOption(to value: FrequencyOption) {
        // select new value and unselect the rest
        getFrequencyOptionUIButtons()
            .forEach { $0.isSelected = FrequencyOption(rawValue: $0.tag) == value }
    }


    // MARK: - Frequency UIButton Getter Methods

    func getFrequencyOptionUIButtons() -> [UIButton] {
        var buttons: [UIButton] = []
        for case let button as UIButton in frequencyOptionsView.subviews {
            if let _ = FrequencyOption(rawValue: button.tag) {
                buttons.append(button)
            }
        }
        return buttons
    }

    func getFrequencyDayUIButtons() -> [UIButton] {
        var buttons: [UIButton] = []
        for case let buttonRow as UIStackView in frequencyDaysView.subviews {
            for case let button as UIButton in buttonRow.subviews {
                if let _ = FrequencyDay(rawValue: button.tag) {
                    buttons.append(button)
                }
            }
        }
        return buttons
    }


    // MARK: - Frequency Selected Value Getter Methods

    func getSelectedFrequencyOption() -> FrequencyOption? {
        return getFrequencyOptionUIButtons()
            .filter { $0.isSelected }
            .compactMap { FrequencyOption(rawValue: $0.tag) }
            .first
    }

    func getSelectedFrequencyDays() -> [FrequencyDay] {
        return getFrequencyDayUIButtons()
            .filter { $0.isSelected }
            .compactMap { FrequencyDay(rawValue: $0.tag) }
    }


    // MARK: - Keyboard Dismissal Methods

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


    // MARK: - Add Reminder Time Button Pressed Methods

    @IBAction func addReminderButtonPressed(_ sender: UIButton) {
        showSelectReminderTimePopup() { (_ hour: Int, _ minute: Int) in
            if self.findReminderTimeIndex(withHour: hour, withMinute: minute) != nil {
                // a reminder already exists with this time, keep it and ignore this one
                return
            }
            let newReminder = ReminderTime(context: self.context)
            newReminder.hour = Int32(hour)
            newReminder.minute = Int32(minute)
            newReminder.habit = nil
            self.reminderTimes.append(newReminder)
            self.updateReminderTimes()
        }
    }

    func updateReminderTimes() {
        reminderTimes.sort {$0.hour < $1.hour || ($0.hour == $1.hour && $0.minute < $1.minute) }
        reminderTimesTableView.reloadData()

        reminderTableViewHeightLayout.constant = CGFloat(
            tableView(self.reminderTimesTableView, numberOfRowsInSection: 0) * 46
        )
    }

    func showSelectReminderTimePopup(
        hour: Int? = nil,
        minute: Int? = nil,
        completion: @escaping (_ hour: Int, _ minute: Int) -> ()
    ) {
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: 250, height: 300)

        let datePicker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: 250, height: 300))
        datePicker.datePickerMode = .time
        datePicker.minuteInterval = 5
        // set initial value if present
        if let editHour = hour, let editMinute = minute {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat =  "HH:mm"
            if let date = dateFormatter.date(from: "\(editHour):\(editMinute)") {
                datePicker.setDate(date, animated: false)
            }
        }
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

        if self.presentedViewController == nil {
            // only present if any no other alert is already shown
            self.present(alert, animated: true, completion: nil)
        }
    }


    func findReminderTimeIndex(withHour hour: Int, withMinute minute: Int) -> Int? {
        return reminderTimes.indices
            .filter { reminderTimes[$0].hour == hour && reminderTimes[$0].minute == minute }
            .first
    }

    func removeReminderTime(atIndex index: Int) {
        context.delete(self.reminderTimes[index])
        reminderTimes.remove(at: index)
    }
}


extension AddHabitViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminderTimes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "editableTimeCell",
            for: indexPath
        ) as! EditableTimeCell
        cell.hour = Int(reminderTimes[indexPath.row].hour)
        cell.minute = Int(reminderTimes[indexPath.row].minute)

        cell.onEditButtonPressed = {
            self.showSelectReminderTimePopup(
                hour: cell.hour,
                minute: cell.minute
            ) { (_ hour: Int, _ minute: Int) in
                let reminder = self.reminderTimes[indexPath.row]
                if hour == reminder.hour && minute == reminder.minute {
                    // nothing changed, do nothing
                    return
                } else if self.findReminderTimeIndex(withHour: hour, withMinute: minute) != nil {
                    // a reminder already exists with new time, keep it and discard this one
                    self.removeReminderTime(atIndex: indexPath.row)
                    self.updateReminderTimes()
                    return
                }

                reminder.hour = Int32(hour)
                reminder.minute = Int32(minute)
                self.updateReminderTimes()
            }
        }
        cell.onRemoveButtonPressed = {
            self.removeReminderTime(atIndex: indexPath.row)
            self.updateReminderTimes()
        }

        cell.updateTimeDisplay()

        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}
