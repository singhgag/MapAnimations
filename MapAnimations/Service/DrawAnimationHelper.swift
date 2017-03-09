//
//  DrawAnimationHelper.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 3/7/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class DrawAnimationHelper: NSObject, PointInterpolatorDelegate {

    var partialAnimation = false
    var partialPercentage = 0.2
    
    private var polyline:AGSPolyline
    private var animatingGraphic:AGSGraphic
    private var speed:Double
    private var points:[AGSPoint]
    private var pointInterpolator:PointInterpolator!
    private var currentAnimationIndex: Int = 0
    private var polylineLength:Double
    
    init(polyline: AGSPolyline, animatingGraphic: AGSGraphic, speed: Double) {
        
        self.polyline = polyline
        self.animatingGraphic = animatingGraphic
        self.speed = speed
        
        self.polylineLength = AGSGeometryEngine.length(of: polyline)
        
        //only supporting the first part right now
        self.points = polyline.parts[0].points.array()
        
        super.init()
    }
    
    //MARK: - Start animation
    
    func startAnimation() {
        self.startAnimation(index: 0)
    }
    
    private func startAnimation(index: Int) {
        if index < self.points.count - 1 {
            self.currentAnimationIndex = index
            
            //points for animation
            let point1 = self.points[index]
            let point2 = self.points[index + 1]
            
            //initialize point interpolator
            self.pointInterpolator = PointInterpolator(fromPoint: point1, toPoint: point2, speed: self.speed)
            
            //assign self as the delegate, to know of the progress
            self.pointInterpolator.delegate = self
            
            //start interpolation
            self.pointInterpolator.start()
        }
    }
    
    //MARK: - PointInterpolatorDelegate
    
    func pointInterpolator(_ pointInterpolator: PointInterpolator, didUpdatePoint point: AGSPoint) {
        
        //first add the points already covered
        let polylineBuilder = AGSPolylineBuilder(spatialReference: self.polyline.spatialReference)
        
        for index in 0...self.currentAnimationIndex {
            polylineBuilder.add(self.points[index])
        }
        
        //then add the new point
        polylineBuilder.add(point)
        
        if self.partialAnimation {
            let newPolyline = polylineBuilder.subPolyline(inForwardDirection: false, length: self.partialPercentage * self.polylineLength)
            
            //assign the geometry to the polyline graphic
            self.animatingGraphic.geometry = newPolyline
        }
        else {
            //assign the geometry to the polyline graphic
            self.animatingGraphic.geometry = polylineBuilder.toGeometry()
        }
    }
    
    func pointInterpolator(_ pointInterpolator: PointInterpolator, didStopAtPoint point: AGSPoint) {
        
        //start the next animation
        self.startAnimation(index: (self.currentAnimationIndex + 1))
    }
    
    func stopAnimation() {
        self.pointInterpolator?.stop()
    }
}
