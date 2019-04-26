//
//  Habit.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/13/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import Foundation
import CoreData

@objc(Habit)
public class Habit: NSManagedObject {
    enum FrequencyOption: Int {
        case Daily = 0, Weekdays = 1, Custom = 2
        var description: String {
            var str: String
            switch self {
            case .Daily:
                str = "Daily"
            case .Weekdays:
                str = "Weekdays"
            case .Custom:
                str = "Custom"
            }
            return str
        }
    }
    enum FrequencyDay: Int {
        case Sun = 0, Mon = 1, Tue = 2, Wed = 3, Thu = 4, Fri = 5, Sat = 6
        var description: String {
            var str: String
            switch self {
            case .Sun:
                str = "Sun"
            case .Mon:
                str = "Mon"
            case .Tue:
                str = "Tue"
            case .Wed:
                str = "Wed"
            case .Thu:
                str = "Thu"
            case .Fri:
                str = "Fri"
            case .Sat:
                str = "Sat"
            }
            return str
        }
    }
}
