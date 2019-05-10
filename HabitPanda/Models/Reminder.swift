//
//  Reminder.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/19/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import Foundation
import CoreData

@objc(ReminderTime)
public class Reminder: NSManagedObject {
    public func getTimeOfDay() -> TimeOfDay {
        return TimeOfDay(hour: Int(hour), minute: Int(minute))
    }

    public func getTimeInMinutes() -> Int {
        return Int(hour * 60) + Int(minute)
    }
}
