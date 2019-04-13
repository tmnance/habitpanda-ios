//
//  HabitViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/12/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class HabitViewController: UITableViewController {

    var habitArray = [Habit]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        loadData()
    }




    // Mark: - TableView Dataousrce Methods

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath)
        let habit = habitArray[indexPath.row]

        cell.textLabel?.text = habit.name

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return habitArray.count
    }


    // Mark: - TableView Delegate Methods

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let habit = habitArray[indexPath.row]
        print("Clicked on habit \(habit.name!)")

//        performSegue(withIdentifier: "goToItems", sender: self)
    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let destinationVC = segue.destination as! TodoListViewController
//        if let indexPath = tableView.indexPathForSelectedRow {
//            destinationVC.selectedCategory = categoryList[indexPath.row]
//        }
//    }






    // MARK: - Add Data Methods

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: "Add New Habit",
            message: "",
            preferredStyle: .alert
        )
        var addTextField = UITextField()

        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Add a new category"
            addTextField = alertTextField
        }
        alert.addAction(UIAlertAction(title: "Add", style: .default) { (action) in
            self.addHabit(addTextField.text!)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    func addHabit(_ text: String) {
        if text == "" {
            return
        }
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

        loadData()
    }


    // MARK: - Load Data Methods

    func loadData() {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        do {
            habitArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }
        print(habitArray)

        tableView.reloadData()
    }
}

