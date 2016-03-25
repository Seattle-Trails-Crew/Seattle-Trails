//
//  SocrataService.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 3/22/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import UIKit
import Foundation
import MapKit


let appToken = "o9zqUXd72sDpc0BWNR45Fc1TH"
class SocrataService
{
	//MARK: debug info checking
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
	class func getSurfaceTypes(trails:[Trail]) -> [String]
	{
		var levels = Set<String>()
		for trail in trails
		{
			if let surfaceType = trail.surfaceType
			{
				levels.insert(surfaceType)
			}
		}
		return Array(levels)
	}
	class func getGradeTypes(trails:[Trail]) -> [String]
	{
		var levels = Set<String>()
		for trail in trails
		{
			if let gradeType = trail.gradeType
			{
				levels.insert(gradeType)
			}
		}
		return Array(levels)
	}
	
	
	//MARK: public network queries
	class func getTrailsInArea(upperLeft:CLLocationCoordinate2D, lowerRight:CLLocationCoordinate2D, returnClosure:(([Trail]?)->()))
	{
		doRequest("$where=within_box(the_geom, \(upperLeft.latitude), \(upperLeft.longitude), \(lowerRight.latitude), \(lowerRight.longitude))", completion: returnClosure)
	}
	
	class func getAllTrails(returnClosure:(([Trail]?)->()))
	{
		//do network calls
		doRequest(nil, completion: returnClosure)
	}
	
	
	//MARK: JSON serialization
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
						let location = CLLocationCoordinate2D(latitude: point[1], longitude: point[0])
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
		
		
		return trails
	}
	private class func serialize(data:NSData) -> [Trail]?
	{
		do
		{
			if let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [[String : AnyObject]]
			{
				return serializeInner(json)
			}
		}
		catch _
		{
		}
		NSLog("ERROR: failed to load trails!");
		return nil
	}
	
	
	//MARK: inner network requests
	private class func doRequest(arguments:String?, completion:([Trail]?)->())
	{
		//prepare the URL string
		let urlString = "https://data.seattle.gov/resource/vwtx-gvpm.json?$limit=999999999&$$app_token=\(appToken)\(arguments != nil ? "&\(arguments!)" : "")&$where=trail_clas!=0"
		
		if let url = NSURL(string: urlString)
		{
			//prepare the session
			let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
			let request = NSMutableURLRequest(URL: url)
			request.HTTPMethod = "GET"
			
			session.dataTaskWithRequest(request, completionHandler:
				{ (data, response, error) in
					if let error = error
					{
						//you didn't get the data, so output an error
						NSOperationQueue.mainQueue().addOperationWithBlock()
							{
								NSLog("ERROR: " + error.description)
								completion(nil)
						}
					}
					else if let data = data
					{
						//you got the data, serialize and return it
						let result = serialize(data)
						NSOperationQueue.mainQueue().addOperationWithBlock()
							{
								completion(result)
						}
					}
					else
					{
						NSOperationQueue.mainQueue().addOperationWithBlock()
							{
								print("UNKNOWN ERROR")
								completion(nil)
						}
					}
			}).resume()
		}
	}
}