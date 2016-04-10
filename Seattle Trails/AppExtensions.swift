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
    func getPictureFor<VC: UIViewController where VC: UIImagePickerControllerDelegate, VC: GetsImageToShare>(sender sender: VC) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
        {
            self.presentImageSourceSelectionView(sender: sender)
        }
        else
        {
            self.presentImagePickerWithSourceTypeForViewController(sender, sourceType: UIImagePickerControllerSourceType.PhotoLibrary)
        }
    }
    
    func presentImagePurposeSelectionView<VC: UIViewController where VC: UIImagePickerControllerDelegate, VC: GetsImageToShare>(sender sender: VC, inPark: String?)
    {
        let alert = UIAlertController(title: "Park Actions", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let sharePhoto = UIAlertAction(title: "Share Photo", style: .Default)
        { (action) in
            sender.performSegueWithIdentifier("showSocial", sender: self)
        }
        
        alert.addAction(sharePhoto)
        
        if UIImagePickerController.isSourceTypeAvailable(.Camera), let _ = inPark
        {
            let report = UIAlertAction(title: "Report Issue", style: .Default)
            { (action) in
                self.presentImagePickerWithSourceTypeForViewController(sender, sourceType: .Camera)
            }
            
            alert.addAction(report)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(cancel)
        
        sender.presentViewController(alert, animated: true, completion: nil)
    }
    
    /**
     An alert controller allowing the user to pick their photo library or the camera as an image source.
     
     - parameter sender: A view controller that conforms to UIImagePickerControllerDelegate and GetsImageToShare protocols.
     */
    private func presentImageSourceSelectionView<VC: UIViewController where VC: UIImagePickerControllerDelegate, VC: GetsImageToShare> (sender sender: VC) {
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
    
    func presentImagePickerWithSourceTypeForViewController<VC: UIViewController where VC: UIImagePickerControllerDelegate, VC: GetsImageToShare>(sender: VC, sourceType: UIImagePickerControllerSourceType)
    {
        sender.imagePicker.sourceType = sourceType
        dispatch_async(dispatch_get_main_queue()) {
            sender.presentViewController(sender.imagePicker, animated: true, completion: nil)
        }
    }
}