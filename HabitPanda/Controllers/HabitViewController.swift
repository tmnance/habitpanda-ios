//
//  HabitListViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/12/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class HabitListViewController: UITableViewController {

    var habitList = [Habit]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
//        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadData()
    }


    // Mark: - TableView Dataousrce Methods

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath)
        let habit = habitList[indexPath.row]

        cell.textLabel?.text = habit.name

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return habitList.count
    }


    // Mark: - TableView Delegate Methods

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let habit = habitList[indexPath.row]
        print("Clicked on habit \(habit.name!)")

//        performSegue(withIdentifier: "goToItems", sender: self)
    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let destinationVC = segue.destination as! TodoListViewController
//        if let indexPath = tableView.indexPathForSelectedRow {
//            destinationVC.selectedCategory = categoryList[indexPath.row]
//        }
//    }


    // MARK: - Load Data Methods

    func loadData() {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        do {
            habitList = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }
        print(habitList)

        tableView.reloadData()
    }
}

