//
//  TestTimer.swift
//  MapViewDemo-Swift
//
//  Created by Gagandeep Singh on 1/31/17.
//  Copyright © 2017 Esri. All rights reserved.
//

import UIKit
import ArcGIS

@objc protocol PointInterpolatorDelegate:class {
    
    @objc optional func pointInterpolator(_ pointInterpolator:PointInterpolator, didUpdatePoint point:AGSPoint)
    @objc optional func pointInterpolator(_ pointInterpolator:PointInterpolator, didStopAtPoint point:AGSPoint)
}

class PointInterpolator: NSObject {

    var fromPoint:AGSPoint
    var toPoint:AGSPoint
    var userInfo:[String:AnyObject]?

    private var timer:Timer!
    private var currentPoint:AGSPoint
    private var duration:Double
    private var currentIteration = 0
    private var distance:Double
    private var totalIterations:Int
    private var delta:Double
    private let fireInterval = 1 / 60.0
    
    
    weak var delegate:PointInterpolatorDelegate?
    
    init(fromPoint:AGSPoint, toPoint:AGSPoint, speed:Double) {
        
        self.fromPoint = fromPoint
        self.currentPoint = fromPoint
        self.toPoint = toPoint
        
        //distance between the points
        self.distance = AGSGeometryEngine.distanceBetweenGeometry1(fromPoint, geometry2: toPoint)
        
        //use the speed and distance to find out duration
        self.duration = self.distance / speed
        
        //use duration and fireInterval to find out total iterations
        self.totalIterations = Int(duration / fireInterval)
        
        //change every iteration
        self.delta = distance / Double(totalIterations)
        
        super.init()
    }
    
    func start() {
        
        //set the starting point
        self.currentPoint = self.fromPoint
        
        //reset current iteration to zero
        self.currentIteration = 0
        
        //schedule timer
        self.timer = Timer.scheduledTimer(timeInterval: self.fireInterval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
    
    func update() {
        //calculate new current value
        if self.currentIteration < self.totalIterations - 1 {  //not the last one
            let change = Double(self.currentIteration + 1) * self.delta
            let newX = (change * (toPoint.x - fromPoint.x) / self.distance) + fromPoint.x
            let newY = (change * (toPoint.y - fromPoint.y) / self.distance) + fromPoint.y
            let newZ = (change * (toPoint.z - fromPoint.z) / self.distance) + fromPoint.z
            
            self.currentPoint = AGSPoint(x: newX, y: newY, z: newZ, spatialReference: self.fromPoint.spatialReference)
            
            //notify delegate
            self.delegate?.pointInterpolator?(self, didUpdatePoint: self.currentPoint)
        }
        else {  //to make sure the last iteration ends up at the exact location
            
            self.currentPoint = toPoint
            
            //notify delegate about update
            self.delegate?.pointInterpolator?(self, didUpdatePoint: self.currentPoint)
            
            //invalidate timer as the animation is done
            self.timer.invalidate()
            
            //notify the delegate about the completion
            self.delegate?.pointInterpolator?(self, didStopAtPoint: self.currentPoint)
        }
        
        //increment iteration value
        self.currentIteration += 1
    }
    
    func stop() {
        
        //invalidate timer
        self.timer.invalidate()
        
        //notify delegate
        self.delegate?.pointInterpolator?(self, didStopAtPoint: self.currentPoint)
    }
}
