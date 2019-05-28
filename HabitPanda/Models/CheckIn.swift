//
//  CheckIn.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/13/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

@objc(CheckIn)
public class CheckIn: NSManagedObject {
    func getCreatedDateString(withFormat format: DateHelper.DateFormat) -> String {
        return DateHelper.getDateString(forDate: createdAt!, withFormat: format)
    }

    func getCheckInDateString(withFormat format: DateHelper.DateFormat) -> String {
        return DateHelper.getDateString(forDate: checkInDate!, withFormat: format)
    }

    func wasAddedForPriorDate() -> Bool {
        return getAddedVsCheckInDateDayOffset() > 0
    }
    func getAddedVsCheckInDateDayOffset() -> Int {
        return Calendar.current.dateComponents(
            [.day],
            from: checkInDate!,
            to: createdAt!
        ).day ?? 0
    }

    public static func getAll(
        sortedBy sortKey: String = "checkInDate",
        forHabitUUIDs habitUUIDs: [UUID]? = nil,
        afterDate: Date? = nil,
        beforeDate: Date? = nil
    ) -> [CheckIn] {
        let context = (UIApplication.shared.delegate as! AppDelegate)
            .persistentContainer.viewContext
        var checkIns: [CheckIn] = []

        let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
        var predicates: [NSPredicate] = []

        if let habitUUIDs = habitUUIDs {
            let uuidArgs = habitUUIDs.map { $0.uuidString as CVarArg }
            predicates.append(NSPredicate(format: "habit.uuid IN %@", uuidArgs))
        }

        if let afterDate = afterDate {
            predicates.append(NSPredicate(format: "checkInDate >= %@", afterDate as NSDate))
        }
        if let beforeDate = beforeDate {
            predicates.append(NSPredicate(format: "checkInDate <= %@", beforeDate as NSDate))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(key: sortKey, ascending: true)
        ]

        do {
            checkIns = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return checkIns
    }
}
