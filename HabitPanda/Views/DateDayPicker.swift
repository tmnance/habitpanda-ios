//
//  DateDayPicker.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/14/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class DateDayPicker: UIPickerView {
    var pickerData: [Date] = []
    let customWidth: CGFloat = 100
    let customHeight: CGFloat = 100
    var rotationDegrees: CGFloat = 0
}


extension DateDayPicker {
    func rotate90deg() {
        guard
            let containerView = self.superview,
            let dayDatePickerDelegate = self.delegate as? DateDayPicker
            else {
                return
        }

        dayDatePickerDelegate.rotationDegrees = 90

        let pickerWidth = self.frame.width
        let pickerHeight = self.frame.height
        let newPickerWidth = min(
            pickerWidth + (pickerWidth - pickerHeight),
            containerView.frame.width
        )
        let newX = (newPickerWidth - pickerWidth) / -2
        let y = self.frame.origin.y

        self.transform = CGAffineTransform(
            rotationAngle: dayDatePickerDelegate.rotationDegrees * (.pi / 180)
        )

        self.frame = CGRect(
            x: newX,
            y: y,
            width: newPickerWidth,
            height: pickerHeight
        )
    }

    func getSelectedDate() -> Date? {
        guard let dayDatePickerDelegate = self.delegate as? DateDayPicker else {
            return nil
        }
        return dayDatePickerDelegate.pickerData[self.selectedRow(inComponent: 0)]
    }
}


extension DateDayPicker: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
}

extension DateDayPicker: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return customHeight
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: customWidth, height: customHeight))

        let calendar = Calendar.current
        let date = pickerData[row]
        let df = DateFormatter()

        df.dateFormat = "MMMM"
        let monthName = df.string(from: date)
        let topLabel = UILabel(frame: CGRect(x: 0, y: 10, width: customWidth, height: 15))
        topLabel.text = monthName
        topLabel.textColor = .black
        topLabel.textAlignment = .center
        topLabel.font = UIFont.systemFont(ofSize: 14, weight: .thin)
        view.addSubview(topLabel)

        df.dateFormat = "d"
        let dayNumber = df.string(from: date)
        let middleLabel = UILabel(
            frame: CGRect(x: 0, y: 0, width: customWidth, height: customHeight)
        )
        middleLabel.text = dayNumber
        middleLabel.textColor = .black
        middleLabel.textAlignment = .center
        middleLabel.font = UIFont.systemFont(ofSize: 42, weight: .thin)
        view.addSubview(middleLabel)

        df.dateFormat = "EEEE"
        var dayName = df.string(from: date)
        if calendar.isDateInToday(date) {
            dayName = "Today"
        } else if calendar.isDateInYesterday(date) {
            dayName = "Yesterday"
        }
        let bottomLabel = UILabel(frame: CGRect(x: 0, y: 75, width: customWidth, height: 15))
        bottomLabel.text = dayName
        bottomLabel.textColor = .black
        bottomLabel.textAlignment = .center
        bottomLabel.font = UIFont.systemFont(ofSize: 14, weight: .thin)
        view.addSubview(bottomLabel)

        if rotationDegrees != 0 {
            view.transform = CGAffineTransform(rotationAngle: (rotationDegrees * (.pi / -180)))
        }

        return view
    }
}
