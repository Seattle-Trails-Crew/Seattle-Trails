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
	var canopy:String?
	var condition:String?
	var gradeType:String?
	var surfaceType:String?
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
let timeoutPeriod:Double = 3600

//info cache
var localCacheInner:[Trail]?

class socrataService
{
//	class func filterBy
	
	class func getNearestTrail(nearestTo:CGPoint, returnClosure:((Trail?)->()))
	{
		getAllTrails()
		{ (trails) in
			if let trails = trails
			{
				if trails.count == 0
				{
					returnClosure(nil)
				}
				else
				{
					var closest = trails[0]
					for trail in trails
					{
						let center = trail.center
						let xDif = center.x - nearestTo.x
						let yDif = center.y - nearestTo.y
						let distance = xDif*xDif + yDif*yDif
						
						let oldCenter = closest.center
						let oldXDif = oldCenter.x - nearestTo.x
						let oldYDif = oldCenter.y - nearestTo.y
						let oldDistance = oldXDif*oldXDif + oldYDif*oldYDif
						
						if distance < oldDistance
						{
							closest = trail
						}
					}
					returnClosure(closest)
				}
			}
			else
			{
				returnClosure(nil)
			}
		}
	}
	
	class func getTrailsInArea(area:CGRect, returnClosure:(([Trail]?)->()))
	{
		getAllTrails()
		{ (trails) in
			if let trails = trails
			{
				var validTrails = [Trail]()
				for trail in trails
				{
					for point in trail.points
					{
						if area.contains(point)
						{
							validTrails.append(trail)
							break
						}
					}
				}
				returnClosure(validTrails)
			}
			else
			{
				returnClosure(nil)
			}
		}
	}
	
	class func getAllTrails(returnClosure:(([Trail]?)->()))
	{
		var tryToReplace = false
		if let date = NSUserDefaults.standardUserDefaults().objectForKey("storedDate") as? NSDate
		{
			let currentDate = NSDate()
			let difference = currentDate.timeIntervalSinceDate(date)
			if difference > timeoutPeriod
			{
				tryToReplace = true
			}
		}
		
		
		if (localCache != nil && !tryToReplace)
		{
			//return the local cache
			returnClosure(localCache);
		}
		else
		{
			//do network calls
			doRequest()
			{ (trails, json) in
				if let trails = trails, let json = json
				{
					//cache it
					localCacheInner = trails
					returnClosure(trails)
					
					//store it in user defaults too
					NSUserDefaults.standardUserDefaults().setObject(json, forKey: "storedJSON")
					NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "storedDate")
					
					//save the JSON
					returnClosure(trails)
				}
				else
				{
					//it failed to load, so return the cache whether or not it's nil
					returnClosure(localCache)
				}
			}
		}
	}
	
	
	
	private class func serializeInner(json:[[String : AnyObject]]) -> [Trail]
	{
		var trails = [Trail]()
		for dict in json
		{
			//TODO: parse this JSON dictionary
			//into a trail
			let canopy = dict["canopy"] as? String
			let condition = dict["condition"] as? String
			let gradeType = dict["grade_type"] as? String
			let surfaceType = dict["surface_ty"] as? String
			if let name = dict["pma_name"] as? String, let length = dict["gis_length"] as? String, let geom = dict["the_geom"] as? [String:AnyObject]
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
	private class func serialize(data:NSData) -> ([Trail]?, [[String : AnyObject]]?)
	{
		do
		{
			if let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [[String : AnyObject]]
			{
				return (serializeInner(json), json)
			}
		}
		catch let error
		{
		}
		NSLog("ERROR: failed to load trails!");
		return (nil, nil)
	}
	
	private class func doRequest(completion:([Trail]?, [[String : AnyObject]]?)->())
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
					
					let result = serialize(data)
					NSOperationQueue.mainQueue().addOperationWithBlock()
					{
						completion(result.0, result.1)
					}
				}
			}).resume()
		}
	}
	
	private class var localCache:[Trail]?
	{
		if localCacheInner == nil, let json = NSUserDefaults.standardUserDefaults().objectForKey("storedJSON") as? [[String : AnyObject]]
		{
			localCacheInner = socrataService.serializeInner(json)
		}
		return localCacheInner
	}
}