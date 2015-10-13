//
//  HorizontalLineView.swift
//  Tensor
//
//  Created by Nathan Melehan on 10/11/15.
//  Copyright © 2015 Nathan Melehan. All rights reserved.
//

import UIKit

@IBDesignable
class HorizontalLineView: UIView {

    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        let linePath = UIBezierPath()
        
        //set the path's line width to the height of the stroke
        linePath.lineWidth = 1
        
        //move the initial point of the path
        //to the start of the horizontal stroke
        linePath.moveToPoint(bounds.origin)
        
        //add a point to the path at the end of the stroke
        linePath.addLineToPoint(CGPoint(
        x:bounds.origin.x + bounds.size.width,
        y:bounds.origin.y))
        
        //set the stroke color
        UIColor.blackColor().setStroke()
        
        //draw the stroke
        linePath.stroke()
    }
}
