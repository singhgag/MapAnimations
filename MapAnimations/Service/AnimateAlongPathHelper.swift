//
//  AnimateAlongPath.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 2/28/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

@objc protocol AnimateAlongPathHelperDelegate:class {
    
    @objc optional func animateAlongPathHelperDidFinish(_ animateAlongPathHelper:AnimateAlongPathHelper)
}

class AnimateAlongPathHelper: NSObject, PointInterpolatorDelegate {

    private var polyline:AGSPolyline
    private var speed:Double
    private var animatingGraphic:AGSGraphic
    private var currentAnimationIndex = 0
    private var pointInterpolator:PointInterpolator!
    
    weak var delegate:AnimateAlongPathHelperDelegate?
    
    init(polyline: AGSPolyline, animatingGraphic: AGSGraphic, speed: Double) {
        
        self.polyline = polyline
        self.animatingGraphic = animatingGraphic
        self.speed = speed
        
        super.init()
    }
    
    func startAnimation() {
        //reset animation index to start animation from beginning
        self.currentAnimationIndex = 0
        
        //start the animation
        self.startAnimation(forIndex: 0)
    }
    
    private func startAnimation(forIndex index:Int) {
        
        if index < self.polyline.parts[0].pointCount - 1 {
            self.currentAnimationIndex = index
            
            //points
            let point1 = self.polyline.parts[0].points[index]
            let point2 = self.polyline.parts[0].points[index + 1]
            
            //initialize point interpolator with these points and speed
            self.pointInterpolator = PointInterpolator(fromPoint: point1, toPoint: point2, speed: self.speed)
            
            //assign self as the delegate, we will need to know the progress
            self.pointInterpolator.delegate = self
            
            //start interpolation
            self.pointInterpolator.start()
            
            //update rotation of the animating graphic to face in the right direction
            if self.animatingGraphic.symbol is AGSMarkerSymbol {
                (self.animatingGraphic.symbol as! AGSMarkerSymbol).angle = Float(self.getAngle(point1, p2: point2))
            }
        }
    }
    
    //MARK: - PointInterpolatorDelegate
    
    func pointInterpolator(_ pointInterpolator: PointInterpolator, didUpdatePoint point: AGSPoint) {
        
        //update graphics geometry so it updates in graphics overlay
        self.animatingGraphic.geometry = point
    }
    
    func pointInterpolator(_ pointInterpolator: PointInterpolator, didStopAtPoint point: AGSPoint) {
        //start the next segment animation
        self.startAnimation(forIndex: self.currentAnimationIndex + 1)
        
        //if it was the last segment animation, notify delegate of the completion
        if self.currentAnimationIndex + 1 == self.polyline.parts[0].pointCount - 1 {
            self.delegate?.animateAlongPathHelperDidFinish?(self)
        }
    }
    
    func stopAnimation() {
        
        //stop animation
        self.pointInterpolator?.stop()
    }
    
    //get angle between line joining the points and north
    //points must be in web mercator sr
    private func getAngle(_ p1: AGSPoint, p2: AGSPoint) -> Double {
        
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        
        let angleXInDegrees = atan2(dy, dx) / M_PI * 180;
        
        var angleYInDegrees:Double!
        if dx <= 0 {
            if dy <= 0 {
                angleYInDegrees = 90 + abs(angleXInDegrees)
            }
            else {
                angleYInDegrees = 450 - angleXInDegrees
            }
        }
        else {
            if dy <= 0 {
                angleYInDegrees = 90 + abs(angleXInDegrees)
            }
            else {
                angleYInDegrees = 90 - angleXInDegrees
            }
        }
        
        return angleYInDegrees.truncatingRemainder(dividingBy: 360)
    }
}
