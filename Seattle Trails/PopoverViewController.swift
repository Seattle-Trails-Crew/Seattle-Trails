//
//  PopoverTableViewController.swift
//  Seattle Trails
//
//  Created by David Wolgemuth on 3/28/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit

class PopoverViewController: UITableView, UISearchControllerDelegate, UISearchResultsUpdating
{
    var parksDataSource: ParksDataSource?
    var visibleParks = [String]()
    
    func filterTrails(params: String)
    {
        visibleParks.removeAll()
        for park in parksDataSource!.parks.keys {
            if params == "" || park.lowercaseString.rangeOfString(params.lowercaseString) != nil {
                visibleParks.append(park)
            }
        }
        self.reloadData()
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        print("placeholder")
    }
}

class ParkCell: UITableViewCell
{
    @IBOutlet weak var parkNameLabel: UILabel!
}