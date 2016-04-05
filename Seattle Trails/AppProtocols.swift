//
//  AppProtocols.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 4/4/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import Foundation

protocol ParksDataSource
{
    var parks: [String: Park] { get }
    func performActionWithSelectedPark(park: String)
}
