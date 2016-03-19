//
//  Model.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 3/18/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit
import Foundation
import MapKit

class Trail
{
	var points = [CLLocationCoordinate2D]();
	var startPoint = CLLocationCoordinate2D(latitude: 0, longitude: 0)
	var name:String = ""
	var canopy:String?
	var condition:String?
	var gradeType:String?
	var surfaceType:String?
	var length:Float = 0
	var trailNum:Int = 0
	var pmaid:Int = 0
	
	//utility functions
	var center:CLLocationCoordinate2D
	{
		var c = CLLocationCoordinate2D(latitude: 0, longitude: 0)
		for point in points
		{
			c.latitude += point.latitude
			c.longitude += point.longitude
		}
		c.latitude /= Double(points.count)
		c.longitude /= Double(points.count)
		return c
	}
}


let appToken = "o9zqUXd72sDpc0BWNR45Fc1TH"
let timeoutPeriod:Double = 3600

//info cache
var localCacheInner:[Trail]?

class socrataService
{
	class func getCanopyLevels(trails:[Trail]) -> [String]
	{
		var levels = Set<String>()
		for trail in trails
		{
			if let canopy = trail.canopy
			{
				levels.insert(canopy)
			}
		}
		return Array(levels)
	}
	class func filterByCanopy(trails:[Trail], desiredCanopy:String) -> [Trail]
	{
		return trails.filter() { $0.canopy == desiredCanopy }
	}
	
	class func getNearestTrail(nearestTo:CLLocationCoordinate2D, returnClosure:((Trail?)->()))
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
						let xDif = center.latitude - nearestTo.latitude
						let yDif = center.longitude - nearestTo.longitude
						let distance = xDif*xDif + yDif*yDif
						
						let oldCenter = closest.center
						let oldXDif = oldCenter.latitude - nearestTo.latitude
						let oldYDif = oldCenter.longitude - nearestTo.longitude
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

//	class func getTrailsInArea(area:CGRect, returnClosure:(([Trail]?)->()))
//	{
//		getAllTrails()
//		{ (trails) in
//			if let trails = trails
//			{
//				var validTrails = [Trail]()
//				for trail in trails
//				{
//					for point in trail.points
//					{
//						if area.contains(point)
//						{
//							validTrails.append(trail)
//							break
//						}
//					}
//				}
//				returnClosure(validTrails)
//			}
//			else
//			{
//				returnClosure(nil)
//			}
//		}
//	}
	
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
			//parse this JSON dictionary into a trail
			let canopy = dict["canopy"] as? String
			let condition = dict["condition"] as? String
			let gradeType = dict["grade_type"] as? String
			let surfaceType = dict["surface_ty"] as? String
			if let pmaid = dict["pmaid"] as? String, let trailNum = dict["trail_num"] as? String, let name = dict["pma_name"] as? String, let length = dict["gis_length"] as? String, let geom = dict["the_geom"] as? [String:AnyObject]
			{
				let trail = Trail()
				trail.canopy = canopy
				trail.condition = condition
				trail.gradeType = gradeType
				trail.surfaceType = surfaceType
				trail.name = name
				trail.length = (length as NSString).floatValue
				trail.trailNum = (trailNum as NSString).integerValue
				trail.pmaid = (pmaid as NSString).integerValue
				
				
				if let points = geom["coordinates"] as? [[Double]]
				{
					for point in points
					{
						let location = CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
						trail.points.append(location)
					}
					
					trail.startPoint = trail.points[0]
					
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
		
		
		//connect continuous trails
		for trail in trails
		{
			for trail2 in trails
			{
				if trail2.pmaid == trail.pmaid && trail2.trailNum == trail.trailNum - 1
				{
					trail.points.insert(trail2.points.last!, atIndex: 0)
				}
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
		catch _
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