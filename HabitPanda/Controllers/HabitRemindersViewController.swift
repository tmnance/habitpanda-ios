//
//  HabitRemindersViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/30/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class HabitRemindersViewController: UIViewController {
    @IBOutlet weak var remindersTableView: UITableView!
    @IBOutlet weak var remindersTableViewHeightLayout: NSLayoutConstraint!

    var delegateViewModel = HabitViewModel() {
        didSet {
            viewModel.selectedHabit = delegateViewModel.selectedHabit
        }
    }
    private var viewModel = ReminderViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFieldStylesAndBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateReminders()
    }

    override func viewDidLayoutSubviews() {
        let targetSize = CGSize(
            width: view.bounds.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        preferredContentSize = view.systemLayoutSizeFitting(targetSize)
    }
}


// MARK: - Field Setup Methods
extension HabitRemindersViewController {
    func setupFieldStylesAndBindings() {
        remindersTableView.delegate = self
        remindersTableView.dataSource = self
        remindersTableView.separatorStyle = .none

        remindersTableView.register(
            UINib(nibName: "EditableTimeCell", bundle: nil),
            forCellReuseIdentifier: "editableTimeCell"
        )

        viewModel.reminders.bind { [unowned self] (_) in
            self.updateReminders()
        }
    }
}


// MARK: - Reminder Methods
extension HabitRemindersViewController {
    func updateReminders() {
        remindersTableView.reloadData()
        remindersTableViewHeightLayout.constant = CGFloat(
            tableView(remindersTableView, numberOfRowsInSection: 0) * 46
        )
    }

    @IBAction func addReminderButtonPressed(_ sender: UIButton) {
        showSelectReminderPopup() { (_ hour: Int, _ minute: Int) in
            self.viewModel.addReminder(hour: hour, minute: minute)
            self.viewModel.saveReminders()
        }
    }

    func createReminderDatePicker(
        hour: Int? = nil,
        minute: Int? = nil
        ) -> UIDatePicker {
        let datePicker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: 250, height: 300))
        datePicker.datePickerMode = .time
        datePicker.minuteInterval = Constants.TimePicker.minuteInterval
        datePicker.setDate(
            Date().rounded(
                minutes: TimeInterval(Constants.TimePicker.minuteInterval),
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

    func showSelectReminderPopup(
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
extension HabitRemindersViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.reminders.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "editableTimeCell",
            for: indexPath
            ) as! EditableTimeCell
        let reminder = viewModel.reminders.value[indexPath.row]
        cell.hour = Int(reminder.hour)
        cell.minute = Int(reminder.minute)

        cell.onEditButtonPressed = {
            self.showSelectReminderPopup(
                hour: cell.hour,
                minute: cell.minute
            ) { (_ hour: Int, _ minute: Int) in
                if hour == reminder.hour && minute == reminder.minute {
                    // nothing changed, do nothing
                    return
                }
                // simpler to just remove and re-add to prevent duplicates
                self.viewModel.removeReminder(atIndex: indexPath.row)
                self.viewModel.addReminder(hour: hour, minute: minute)
                self.viewModel.saveReminders()
            }
        }
        cell.onRemoveButtonPressed = {
            self.viewModel.removeReminder(atIndex: indexPath.row)
            self.viewModel.saveReminders()
        }

        cell.updateTimeDisplay()
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
