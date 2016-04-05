//
//  AppExtensions.swift
//  Seattle Trails
//
//  Created by Eric Mentele on 4/4/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import Foundation
import UIKit

extension UIImagePickerController {
    func getPictureFor<VC: UIViewController where VC: UIImagePickerControllerDelegate>(purpose: String, sender: VC) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
        {
            
        }
        else
        {
            self.presentImagePickerWithSourceTypeForViewController(sender, sourceType: UIImagePickerControllerSourceType.PhotoLibrary)
        }
    }
    
    func presentImagePickerWithSourceTypeForViewController<VC: UIViewController where VC: UIImagePickerControllerDelegate>(sender: VC, sourceType: UIImagePickerControllerSourceType)
    {
        //sender.imagePicker.delegate = sender
        sender.imagePicker!.sourceType = sourceType
        dispatch_async(dispatch_get_main_queue()) {
            sender.presentViewController(sender.imagePicker!, animated: true, completion: nil)
        }
    }
}

extension UIImagePickerControllerDelegate {
    var imagePicker: UIImagePickerController?
    {
        guard let _ = self.imagePicker else {
            return nil
        }
        
        return UIImagePickerController()
    }
}