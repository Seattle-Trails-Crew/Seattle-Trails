//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

let string = NSMutableAttributedString(string: "Gravel, Asphalt, Soil")
string.addAttributes([NSForegroundColorAttributeName : UIColor.whiteColor()], range: NSRange(location: 0, length: 6))
string.addAttributes([NSForegroundColorAttributeName : UIColor.blackColor()], range: NSRange(location: 8, length: 7))
string.addAttributes([NSForegroundColorAttributeName : UIColor.greenColor()], range: NSRange(location: 17, length: 4))
