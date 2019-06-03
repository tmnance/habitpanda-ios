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
        fromStartDate startDate: Date? = nil,
        toEndDate endDate: Date? = nil,
        withLimit limit: Int? = nil
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

        if let startDate = startDate {
            predicates.append(NSPredicate(format: "checkInDate >= %@", startDate as NSDate))
        }
        if let endDate = endDate {
            predicates.append(NSPredicate(format: "checkInDate <= %@", endDate as NSDate))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(key: sortKey, ascending: true)
        ]

        if let limit = limit {
            request.fetchLimit = limit
        }

        do {
            checkIns = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return checkIns
    }
}
