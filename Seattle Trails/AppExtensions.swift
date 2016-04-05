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
            self.presentImageSourceSelectionView(sender: sender)
        }
        else
        {
            self.presentImagePickerWithSourceTypeForViewController(sender, sourceType: UIImagePickerControllerSourceType.PhotoLibrary)
        }
    }
    
    func presentImageSourceSelectionView<VC: UIViewController where VC: UIImagePickerControllerDelegate> (sender sender: VC) {
        // Present image picker options.
        let actionSheet = UIAlertController(title: "Image Source", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default)
        { (action) in
            dispatch_async(dispatch_get_main_queue())
            {
                self.presentImagePickerWithSourceTypeForViewController(sender, sourceType: UIImagePickerControllerSourceType.Camera)
            }
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.Default)
        { (action) in
            dispatch_async(dispatch_get_main_queue())
            {
                self.presentImagePickerWithSourceTypeForViewController(sender, sourceType: UIImagePickerControllerSourceType.PhotoLibrary)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(cancelAction)
        
        dispatch_async(dispatch_get_main_queue())
        {
            sender.presentViewController(actionSheet, animated: true, completion: nil)
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
    var imagePicker: UIImagePickerController!
    {
        return UIImagePickerController()
    }
}