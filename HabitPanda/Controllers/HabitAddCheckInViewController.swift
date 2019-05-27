//
//  HabitAddCheckInViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/14/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class HabitAddCheckInViewController: UIViewController {
    @IBOutlet weak var checkInDayPicker: DateDayPicker!

    var delegateViewModel = HabitDetailsViewModel()
    var dateDayPicker: DateDayPicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        let today = Date().stripTime()
        var dateArray = [today]
        for i in 1...4 {
            let pastDay = Calendar.current.date(byAdding: .day, value: (-1 * i), to: today)!
            dateArray.append(pastDay)
        }

        dateDayPicker = DateDayPicker()
        dateDayPicker.pickerData = dateArray

        checkInDayPicker.delegate = dateDayPicker
        checkInDayPicker.dataSource = dateDayPicker

        checkInDayPicker.rotate90deg()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}
