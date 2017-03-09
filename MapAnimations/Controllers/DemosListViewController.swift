//
//  DemosListViewController.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 3/3/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit

class DemosListViewController: UITableViewController {

    let demos = ["Animate along path", "Car route simulation", "Flights and paths", "Viewpoint animation", "Turn by turn directions", "Draw animation"]
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.demos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemosListCell", for: indexPath)

        cell.textLabel?.text = self.demos[indexPath.row]

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let storyboard = UIStoryboard(name: self.demos[indexPath.row], bundle: nil)
        let controller = storyboard.instantiateInitialViewController()!
        controller.title = self.demos[indexPath.row]
        
        let navController = UINavigationController(rootViewController: controller)
        
        //add the button on the left on the detail view controller
        if let splitViewController = self.view.window?.rootViewController as? UISplitViewController {
            controller.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
        }

        self.splitViewController?.showDetailViewController(navController, sender: self)
    }
}
