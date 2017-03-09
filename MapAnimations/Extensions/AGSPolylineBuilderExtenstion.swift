//
//  AGSPolylineExtenstion.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 2/28/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import ArcGIS

extension AGSPolylineBuilder {
    
    func arrowhead(size:Double) -> AGSPolygon? {
        
        let totalPoint = self.parts[0].pointCount
        let lastPoint = self.parts[0].point(at: totalPoint - 1)
        let secondLastPoint = self.parts[0].point(at: totalPoint - 2)
        
        // Calculate perpendicular offset
        let length = AGSGeometryEngine.distanceBetweenGeometry1(secondLastPoint, geometry2: lastPoint)
        if length <= 0 {
            return nil
        }
        let dx = secondLastPoint.x - lastPoint.x
        let dy = secondLastPoint.y - lastPoint.y
        
        let normX = dx / length
        let normY = dy / length
        
        let xPerp = size/2 * normX
        let yPerp = size/2 * normY
        
        // Create perpendicular points
        
        let x1 = lastPoint.x - yPerp
        let y1 = lastPoint.y + xPerp
        let x2 = lastPoint.x + yPerp
        let y2 = lastPoint.y - xPerp
        let point1 = AGSPoint(x: x1, y: y1, spatialReference: self.spatialReference)
        let point2 = AGSPoint(x: x2, y: y2, spatialReference: self.spatialReference)
        
        //create the third point
        let distance = (1.732 / 2) * size
        let newX = (distance * (lastPoint.x - secondLastPoint.x)/length) + lastPoint.x
        let newY = (distance * (lastPoint.y - secondLastPoint.y)/length) + lastPoint.y
        let point3 = AGSPoint(x: newX, y: newY, spatialReference: self.spatialReference)
        
        let polygon = AGSPolygon(points: [point1, point2, point3])
        
        return polygon
    }
    
    func subPolyline(inForwardDirection:Bool, length:Double) -> AGSPolyline? {
        if self.parts[0].pointCount > 1 {
            var startingPointIndex:Int!
            let subPolylineSoFar = AGSPolylineBuilder(spatialReference: self.spatialReference)
            
            if inForwardDirection {
                startingPointIndex = 0
            }
            else {
                startingPointIndex = self.parts[0].pointCount-1
            }
            
            let startingPoint = self.parts[0].point(at: startingPointIndex)
            subPolylineSoFar.add(startingPoint)
            return self.subPolyLine(fromPointIndex: startingPointIndex, inForwardDirection: inForwardDirection, subPolylineSoFar: subPolylineSoFar, lengthSoFar: 0, requiredLength: length)
        }
        return nil
    }
    
    private func subPolyLine(fromPointIndex:Int, inForwardDirection:Bool, subPolylineSoFar:AGSPolylineBuilder, lengthSoFar:Double, requiredLength:Double) -> AGSPolyline {
        //check if next point exists in specified direction
        var nextPointIndex:Int!
        if inForwardDirection {
            if fromPointIndex + 1 > self.parts[0].pointCount - 1 {
                return subPolylineSoFar.toGeometry()
            }
            else {
                nextPointIndex = fromPointIndex+1
            }
        }
        else {
            if fromPointIndex - 1 < 0 {
                return subPolylineSoFar.toGeometry()
            }
            else {
                nextPointIndex = fromPointIndex-1
            }
        }
        //get the points
        let fromPoint = self.parts[0].point(at: fromPointIndex)
        let nextPoint = self.parts[0].point(at: nextPointIndex)
        //find the distance between the points
        let length = AGSGeometryEngine.distanceBetweenGeometry1(fromPoint, geometry2: nextPoint)
        //TODO: check the units
        if length+lengthSoFar == requiredLength {
            subPolylineSoFar.add(nextPoint)
            return subPolylineSoFar.toGeometry()
        }
        else if length+lengthSoFar < requiredLength {
            subPolylineSoFar.add(nextPoint)
            return self.subPolyLine(fromPointIndex: nextPointIndex, inForwardDirection: inForwardDirection, subPolylineSoFar: subPolylineSoFar, lengthSoFar: length+lengthSoFar, requiredLength: requiredLength)
        }
        else {
            //calculate the point along the line, (requiredLength-lengthSoFar) units away from fromPoint
            let reducedLength = requiredLength - lengthSoFar
            let newX = (reducedLength * (nextPoint.x - fromPoint.x)/length) + fromPoint.x
            let newY = (reducedLength * (nextPoint.y - fromPoint.y)/length) + fromPoint.y
            let newPoint = AGSPoint(x: newX, y: newY, spatialReference: self.spatialReference)
            subPolylineSoFar.add(newPoint)
            return subPolylineSoFar.toGeometry()
        }
    }
}

