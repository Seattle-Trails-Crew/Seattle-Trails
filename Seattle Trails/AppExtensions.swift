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
    /**
    This will present the photo library if there is no camera available. If the camera is available the user will be presented with an
     option view that provides a choice between using the camera or the photo library.
     
     - parameter sender: A view controller that conforms to UIImagePickerControllerDelegate and GetsImageToShare protocols.
     */
    func presentCameraOrImageSourceSelectionView<VC: UIViewController>(sender: VC) where VC: UIImagePickerControllerDelegate, VC: GetsImageToShare {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
        {
            self.presentImageSourceSelectionView(sender: sender)
        }
        else
        {
            self.presentImagePickerWithSourceTypeForViewController(sender, sourceType: UIImagePickerControllerSourceType.photoLibrary, forIssue: false)
        }
    }
    
    /**
     An alert controller allowing the user to pick their photo library or the camera as an image source.
     
     - parameter sender: A view controller that conforms to UIImagePickerControllerDelegate and GetsImageToShare protocols.
     */
	fileprivate func presentImageSourceSelectionView<VC: UIViewController> (sender: VC) where VC: UIImagePickerControllerDelegate, VC: GetsImageToShare {
		
		//if they don't have a camera, just present the photo library without asking the user
		if (!UIImagePickerController.isSourceTypeAvailable(.camera))
		{
            self.presentImagePickerWithSourceTypeForViewController(sender, sourceType: .photoLibrary, forIssue: false)
			return;
		}
		
		
        // Present image picker options.
        let actionSheet = UIAlertController(title: "Share Image", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
		
        let cameraAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.default)
        { (action) in
            DispatchQueue.main.async
            {
                self.presentImagePickerWithSourceTypeForViewController(sender, sourceType: UIImagePickerControllerSourceType.camera, forIssue: false)

            }
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.default)
        { (action) in
            DispatchQueue.main.async
            {
                self.presentImagePickerWithSourceTypeForViewController(sender, sourceType: UIImagePickerControllerSourceType.photoLibrary, forIssue: false)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(cancelAction)
        
        DispatchQueue.main.async
        {
            sender.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    func presentImagePickerWithSourceTypeForViewController<VC: UIViewController>(_ sender: VC, sourceType: UIImagePickerControllerSourceType, forIssue: Bool) where VC: UIImagePickerControllerDelegate, VC: GetsImageToShare
    {
        sender.imagePicker.sourceType = sourceType
        
        DispatchQueue.main.async
        {
            sender.present(sender.imagePicker, animated: true, completion: nil)
            if forIssue
            {
                AlertViews.presentReportAlert(sender: self)
            }
        }
    }
}
