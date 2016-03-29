//
//  PopoverTableViewController.swift
//  Seattle Trails
//
//  Created by David Wolgemuth on 3/28/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit

protocol PopoverViewDelegate
{
    func dismissPopover()
}

class PopoverViewController: UIViewController
{
    var trailsDataSource: TrailsDataSource?
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
            tableView!.trailsDataSource = trailsDataSource
        }
    }
}

class ParkCell: UITableViewCell
{
    @IBOutlet weak var parkNameLabel: UILabel!
}

class PopoverTableViewController:  UITableViewController
{
    var trailsDataSource: TrailsDataSource?
    var visibleTrails = [String]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        filterTrails("")
    }
    
    func filterTrails(params: String)
    {
        visibleTrails.removeAll()
        for trail in trailsDataSource!.trails.keys {
            if params == "" || trail.lowercaseString.rangeOfString(params.lowercaseString) != nil {
                visibleTrails.append(trail)
            }
        }
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return visibleTrails.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("ParkCell")! as! ParkCell
        cell.parkNameLabel.text = visibleTrails[indexPath.row]
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let trail = visibleTrails[indexPath.row]
        trailsDataSource?.performActionWithSelectedTrail(trail)
    }
}
