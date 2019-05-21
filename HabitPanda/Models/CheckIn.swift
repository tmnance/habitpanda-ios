//
//  CheckIn.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/13/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import Foundation
import CoreData

@objc(CheckIn)
public class CheckIn: NSManagedObject {
    func getCheckInDisplayDate() -> String {
        let date = checkInDate!
        let df = DateFormatter()

        df.dateFormat = "EEE, MMMM d"
        let displayDate = df.string(from: date)

        df.dateFormat = "h:mm a"
        let displayTime = df.string(from: date)
        return "\(displayDate) at \(displayTime)"
    }
}
