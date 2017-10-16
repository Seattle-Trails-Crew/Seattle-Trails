//
//  ParkPinView.swift
//  Seattle Trails
//
//  Created by Theodore Abshire on 5/1/16.
//  Copyright © 2016 seatrails. All rights reserved.
//

import MapKit

class ParkPinView: MKPinAnnotationView {
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		//Because we didn't change the frame, the hit-test is backwards
		for view in self.subviews
		{
			if let theirHitView = view.hitTest(self.convert(point, to: view), with: event)
			{
				return theirHitView
			}
		}
		
		let hitView = super.hitTest(point, with: event)
		if let _ = hitView, let peers = self.superview?.subviews
		{
			//remove the callouts from all other pins
			for maybePin in peers
			{
				if let pin = maybePin as? MKPinAnnotationView
				{
					if !(pin === self)
					{
						for subview in pin.subviews
						{
							subview.removeFromSuperview()
						}
					}
				}
			}
		}
		
		return hitView
	}
}
