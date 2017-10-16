//
//  AppProtocols.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 4/4/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import Foundation
import UIKit

protocol ParksDataSource
{
    var parks: [String: Park] { get }
    func performActionWithSelectedPark(_ park: String)
}

protocol PopoverViewDelegate
{
    func dismissPopover()
}

protocol GetsImageToShare {
    var imagePicker: UIImagePickerController {get}
}
