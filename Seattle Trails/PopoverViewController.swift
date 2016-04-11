//
//  PopoverTableViewController.swift
//  Seattle Trails
//
//  Created by David Wolgemuth on 3/28/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit

class PopoverViewController: UIViewController
{
    var parksDataSource: ParksDataSource?
    var tableView: PopoverTableViewController?
    var delegate: PopoverViewDelegate?
    
    // MARK: User Interaction
    @IBAction func doneButtonPressed(sender: UIButton)
    {
        delegate?.dismissPopover()
    }
    
    @IBAction func keyPressedInSearchTextField(sender: UITextField)
    {
        if let params = sender.text {
            tableView!.filterTrails(params)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbedTableView" {
            tableView = segue.destinationViewController as? PopoverTableViewController
            tableView!.parksDataSource = parksDataSource
        }
    }
}

class ParkCell: UITableViewCell
{
    @IBOutlet weak var parkNameLabel: UILabel!
}

class PopoverTableViewController:  UITableViewController
{
    var parksDataSource: ParksDataSource?
    var visibleParks = [String]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        filterTrails("")
    }
    
    func filterTrails(params: String)
    {
        visibleParks.removeAll()
        for park in parksDataSource!.parks.keys {
            if params == "" || park.lowercaseString.rangeOfString(params.lowercaseString) != nil {
                visibleParks.append(park)
            }
        }
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return visibleParks.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("ParkCell")! as! ParkCell
        cell.parkNameLabel.text = visibleParks[indexPath.row]
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let park = visibleParks[indexPath.row]
        parksDataSource?.performActionWithSelectedPark(park)
    }
}
