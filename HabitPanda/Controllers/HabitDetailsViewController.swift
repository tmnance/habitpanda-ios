//
//  HabitDetailsViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/25/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData
import PopupDialog

class HabitDetailsViewController: UIViewController {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var contentTabsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var tabContentContainerView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tabContentContainerHeightConstraint: NSLayoutConstraint!

    var currentTabVC: UIViewController?
    lazy var summaryTabVC: HabitSummaryViewController? = {
        let vc = self.storyboard?.instantiateViewController(
            withIdentifier: "HabitSummaryViewController"
        ) as? HabitSummaryViewController
        vc?.delegateViewModel = self.viewModel
        return vc
    }()
    lazy var checkInsTabVC: HabitCheckInsViewController? = {
        let vc = self.storyboard?.instantiateViewController(
            withIdentifier: "HabitCheckInsViewController"
            ) as? HabitCheckInsViewController
        vc?.delegateViewModel = self.viewModel
        return vc
    }()
    lazy var remindersTabVC: HabitRemindersViewController? = {
        let vc = self.storyboard?.instantiateViewController(
            withIdentifier: "HabitRemindersViewController"
            ) as? HabitRemindersViewController
        vc?.delegateViewModel = self.viewModel
        return vc
    }()

    private var viewModel = HabitDetailsViewModel()

    var selectedHabit: Habit? {
        didSet {
            viewModel.selectedHabit = selectedHabit
            updateUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSegmentedControl()
        displayCurrentTab(0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO: feel this isn't the best way to handle this
        viewModel.reloadHabitData()

        updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let vc = currentTabVC {
            vc.viewWillDisappear(animated)
        }
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        tabContentContainerHeightConstraint.constant = container.preferredContentSize.height
        tabContentContainerView.updateConstraints()
    }
}


// MARK: - UI Update Methods
extension HabitDetailsViewController {
    func updateUI() {
        nameLabel?.text = viewModel.name.value
    }
}


// MARK: - Segmented Control / Tab Methods
extension HabitDetailsViewController {
    func setupSegmentedControl() {
        contentTabsSegmentedControl.setTitleTextAttributes(
            [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)],
            for: .normal
        )

        contentTabsSegmentedControl.tintColor = Constants.Colors.tintColor
        contentTabsSegmentedControl.backgroundColor = UIColor.clear
        contentTabsSegmentedControl.removeBorders()
        contentTabsSegmentedControl.superview?.setBorders(
            toEdges: [.top, .bottom],
            withColor: Constants.Colors.tintColor,
            andThickness: 1
        )
    }

    // MARK: Switching Tabs Functions
    @IBAction func contentTabIndexChanged(_ sender: UISegmentedControl) {
        self.currentTabVC!.view.removeFromSuperview()
        self.currentTabVC!.removeFromParent()

        displayCurrentTab(sender.selectedSegmentIndex)
    }

    func displayCurrentTab(_ tabIndex: Int) {
        if let vc = getSelectedSegmentVC(tabIndex) {
            self.addChild(vc)
            vc.didMove(toParent: self)

            vc.view.frame = tabContentContainerView.bounds
            tabContentContainerView.addSubview(vc.view)
            currentTabVC = vc
            preferredContentSizeDidChange(forChildContentContainer: vc)
        }
    }

    func getSelectedSegmentVC(_ index: Int) -> UIViewController? {
        var vc: UIViewController?
        switch index {
        case 0:
            vc = summaryTabVC
        case 1:
            vc = checkInsTabVC
        case 2:
            vc = remindersTabVC
        default:
            return nil
        }

        return vc
    }
}


// MARK: - Top Nav Bar Methods
extension HabitDetailsViewController {
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToEditHabit", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToHabitCheckIn" {
            return
        }
        let destinationNavigationVC = segue.destination as! UINavigationController
        let destinationVC = destinationNavigationVC.topViewController as! HabitAddEditViewController
        destinationVC.setSelectedHabit(selectedHabit!)
    }
}


// MARK: - Check In Button Methods
extension HabitDetailsViewController {
    @IBAction func checkInButtonPressed(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(
            withIdentifier: "HabitCheckInViewController"
        ) as! HabitAddCheckInViewController
        vc.delegateViewModel = self.viewModel

        let popup = PopupDialog(viewController: vc)

        let cancelButton = CancelButton(title: "CANCEL", action: nil)
        let confirmButton = DefaultButton(title: "CONFIRM") {
            if let selectedDate = vc.checkInDayPicker.getSelectedDate() {
                self.viewModel.addCheckIn(forDate: selectedDate)

                ToastHelper.makeToast("Check-in added", state: .entityCreated)

                if self.currentTabVC == self.summaryTabVC {
                    self.summaryTabVC?.updateChartData()
                } else if self.currentTabVC == self.checkInsTabVC {
                    self.checkInsTabVC?.reloadData()
                }
            }
        }

        popup.addButtons([confirmButton, cancelButton])

        self.present(popup, animated: true, completion: nil)
    }
}
