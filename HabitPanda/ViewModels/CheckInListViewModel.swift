//
//  CheckInListViewModel.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/17/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class CheckInListViewModel {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var checkIns: Box<[CheckIn]> = Box([])
    var selectedHabit: Habit? {
        didSet {
            if selectedHabit != nil {
                loadData()
            }
        }
    }
}


// MARK: - Save Data Methods
extension CheckInListViewModel {
    func removeCheckIn(atIndex index: Int) {
        context.delete(checkIns.value[index])
        checkIns.value.remove(at: index)

        do {
            try context.save()
            ReminderNotificationService.refreshNotificationsForAllReminders()
        } catch {
            print("Error saving context, \(error)")
        }
    }
}


// MARK: - Load Data Methods
extension CheckInListViewModel {
    func reloadData() {
        loadData()
    }

    private func loadData() {
        if let habit = selectedHabit {
            let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
            let predicates = [NSPredicate(format: "habit = %@", habit)]
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(key: "checkInDate", ascending: false)
            ]

            do {
                checkIns.value = try context.fetch(request)
            } catch {
                print("Error fetching data from context, \(error)")
            }
        } else {
            checkIns.value = []
        }
    }
}
