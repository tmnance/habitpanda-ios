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

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameInputField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        saveButton.isEnabled = false

        nameInputField.addTarget(
            self,
            action: #selector(self.validateInput),
            for: UIControl.Event.editingChanged
        )
    }




    // MARK: - Validation Methods

    @objc func validateInput() {
        saveButton.isEnabled = isValidInput()
    }

    func isValidInput() -> Bool {
        return nameInputField.text!.count > 0
    }


    // MARK: - Button Pressed Methods

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


    // MARK: - Add Data Methods

    func addHabit(_ text: String) {
        print("Wanting to add habit \(text)")

        let newHabit = Habit(context: context)
        newHabit.name = text
        newHabit.createdAt = Date()
        newHabit.uuid = UUID()

        do {
            try context.save()
        } catch {
            print("Error saving context, \(error)")
        }
    }

}
