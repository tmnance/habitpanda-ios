//
//  ToastHelper.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/27/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import Foundation
import Toast_Swift

struct ToastHelper {
    enum State: String {
        case entityCreated
        case entityUpdated
        case entityDeleted
        case info
    }

    static func makeToast(_ message: String, state: State) {
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let view = appDelegate.window!

        view.hideAllToasts()
        view.makeToast(
            message,
            duration: 2.0,
            position: .bottom,
            style: getStyle(forState: state)
        )
    }

    private static func getStyle(forState state: State) -> ToastStyle {
        var style = ToastStyle()

        switch state {
        case .entityCreated:
            style.backgroundColor = Constants.Colors.toastInfoBg
        case .entityUpdated:
            style.backgroundColor = Constants.Colors.toastInfoBg
        case .entityDeleted:
            style.backgroundColor = Constants.Colors.toastInfoBg
        case .info:
            style.backgroundColor = Constants.Colors.toastInfoBg
        }

        return style
    }
}
