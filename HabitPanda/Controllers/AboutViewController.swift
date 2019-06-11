//
//  AboutViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 6/11/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    struct AboutLink {
        let name: String
        let url: URL?
        let segueIdentifier: String?

        init(name: String, url: URL? = nil, segueIdentifier: String? = nil) {
            self.name = name
            self.url = url
            self.segueIdentifier = segueIdentifier
        }
    }

    @IBOutlet weak var linksTableView: UITableView!
    @IBOutlet weak var linksTableViewHeightLayout: NSLayoutConstraint!

    let cellHeight: CGFloat = 46.0
    var links = [
        AboutLink(
            name: "Website",
            url: URL(string: "https://habitpanda.app")
        ),
        AboutLink(
            name: "Privacy Policy",
            url: URL(string: "https://habitpanda.app/privacy")
        ),
        AboutLink(
            name: "Contact Us",
            url: URL(string: "https://habitpanda.app")
        ),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStylesAndBindings()
    }
}


// MARK: - Setup Methods
extension AboutViewController {
    func setupStylesAndBindings() {
        #if DEBUG
            links.append(AboutLink(
                name: "Admin",
                segueIdentifier: "goToAdmin"
            ))
        #endif

        linksTableView.delegate = self
        linksTableView.dataSource = self
        linksTableView.isScrollEnabled = false

        linksTableViewHeightLayout.constant =
            CGFloat(tableView(linksTableView, numberOfRowsInSection: 0)) * cellHeight
    }
}


// MARK: - Tableview Datasource Methods
extension AboutViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return links.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "LinkCell",
            for: indexPath
        )
        let link = links[indexPath.row]

        cell.textLabel?.text = link.name

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let link = links[indexPath.row]

        linksTableView.deselectRow(at: indexPath, animated: true)

        if let segueIdentifier = link.segueIdentifier {
            performSegue(withIdentifier: segueIdentifier, sender: self)
        } else if let url = link.url {
            UIApplication.shared.open(url)
        }
    }
}
