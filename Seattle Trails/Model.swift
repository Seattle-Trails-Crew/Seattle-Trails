//
//  Model.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 3/18/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit
import Foundation

class Trail
{
	var points = [CGPoint]();
	var name:String = ""
	var canopy:String = ""
	var condition:String = ""
	var gradeType:String = ""
	var surfaceType:String = ""
	var length:Float = 0
	
	//utility functions
	var center:CGPoint
		{
			var c = CGPoint(x: 0, y: 0)
			for point in points
			{
				c.x += point.x
				c.y += point.y
			}
			c.x /= CGFloat(points.count)
			c.y /= CGFloat(points.count)
			return c
	}
}


let appToken = "o9zqUXd72sDpc0BWNR45Fc1TH"

class socrataService
{
	class func getNearestTrail(nearestTo:CGPoint, returnClosure:((Trail?)->()))
	{
		//TODO: whatever
//		getAllTrails(
//			{ (all:[Trail]) -> () in
//				returnClosure(all[0])
//		})
	}
	
	class func getTrailsInArea(area:CGRect, returnClosure:(([Trail]?)->()))
	{
		//TODO: whatever
//		getAllTrails(returnClosure)
	}
	
	class func getAllTrails(returnClosure:(([Trail]?)->()))
	{
		//do network calls
		doRequest(returnClosure)
	}
	
	private class func serialize(data:NSData) -> [Trail]?
	{
		do
		{
			if let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [[String : AnyObject]]
			{
				var trails = [Trail]()
				for dict in json
				{
					//TODO: parse this JSON dictionary
					//into a trail
					if let canopy = dict["canopy"] as? String, let condition = dict["condition"] as? String, let gradeType = dict["grade_type"] as? String, let surfaceType = dict["surface_ty"] as? String, let name = dict["pma_name"] as? String, let length = dict["gis_length"] as? String, let geom = dict["the_geom"] as? [String:AnyObject]
					{
						let trail = Trail()
						trail.canopy = canopy
						trail.condition = condition
						trail.gradeType = gradeType
						trail.surfaceType = surfaceType
						trail.name = name
						trail.length = (length as NSString).floatValue
						
						if let points = geom["coordinates"] as? [[Int]]
						{
							for point in points
							{
								trail.points.append(CGPoint(x: point[0], y: point[1]))
							}
							trails.append(trail)
						}
						else
						{
							NSLog("ERROR: failed to load points on trail " + name + "!");
						}
						
					}
					else
					{
						NSLog("ERROR: failed to load trail!");
					}
				}
				
				return trails
			}
		}
		catch let error
		{
		}
		NSLog("ERROR: failed to load trails!");
		return nil
	}
	
	private class func doRequest(completion:([Trail]?)->())
	{
		let urlString = "https://data.seattle.gov/resource/vwtx-gvpm.json?$$app_token=" + appToken
		if let url = NSURL(string: urlString)
		{
			let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
			let request = NSMutableURLRequest(URL: url)
			request.HTTPMethod = "GET"
			
			session.dataTaskWithRequest(request, completionHandler:
			{ (data, response, error) in
				if let error = error
				{
					NSOperationQueue.mainQueue().addOperationWithBlock()
					{
						NSLog("ERROR: " + error.description)
					}
				}
				else if let data = data
				{
					//TODO: note there still might be a problem (ie check to see if there's a "error" argument!)
					
					if let serialized = serialize(data)
					{
						NSOperationQueue.mainQueue().addOperationWithBlock()
						{
							completion(serialized)
						}
					}
				}
			}).resume()
		}
	}
}