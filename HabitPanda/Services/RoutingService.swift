//
//  RoutingService.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/22/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

struct RoutingService {
    private static func getRootViewController() -> UINavigationController {
        return (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController as! UINavigationController
    }

    // used for testing
    public static func navigateToFirstHabit() {
        if let habit = Habit.getAll().first {
            RoutingService.navigateToHabit(habit)
        }
    }

    public static func navigateToHabit(_ habit: Habit, andEdit isEdit: Bool = false) {
        clearAllViews() {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let habitDetailsViewController =
                mainStoryboard.instantiateViewController(
                    withIdentifier: "HabitDetailsViewController"
                    ) as! HabitDetailsViewController
            habitDetailsViewController.selectedHabit = habit

            getRootViewController().pushViewController(habitDetailsViewController, animated: false)

            if isEdit {
                habitDetailsViewController.performSegue(
                    withIdentifier: "goToEditHabit",
                    sender: habitDetailsViewController
                )
            }
        }
    }

    private static func clearAllViews(completion allClearedCompletion: (() -> Void)? = nil) {
        let rootViewController = getRootViewController()
        let allDismissedCompletion = {
            rootViewController.popToRootViewController(animated: false)
           allClearedCompletion?()
        }

        if rootViewController.presentedViewController != nil {
            // dismiss all view controllers above root
            rootViewController.dismiss(animated: false, completion: allDismissedCompletion)
        } else {
            allDismissedCompletion()
        }
    }
}
