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
    
    func filterTrails(_ params: String)
    {
        visibleParks.removeAll()
        for park in parksDataSource!.parks.keys {
            if params == "" || park.lowercased().range(of: params.lowercased()) != nil {
                visibleParks.append(park)
            }
        }
        self.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        print("placeholder")
    }
}
