//
//  NMSUtil.swift
//  CardScan
//
//  Created by Zain on 8/6/19.
//

import Foundation
struct NMSUtils{
    static func IOUOf(currentBox: [Float], nextBox: [Float]) -> Float{
        
        /** Return intersection-over-union (Jaccard index) of boxes.
         * Args:
         * boxes0 (N, 4): ground truth boxes.
         *        boxes1 (N or 1, 4): predicted boxes.
         * eps: a small number to avoid 0 as denominator.
         * Returns: iou (N): IOU values
         */
        
        let eps: Float = 0.00001
        var overlapArea: Float
        var area0: Float
        var area1: Float
        var area0Left = [Float](repeating: 0.0, count: 2)
        var area1Left = [Float](repeating: 0.0, count: 2)
        var area0Right = [Float](repeating: 0.0, count: 2)
        var area1Right = [Float](repeating: 0.0, count: 2)
        
        var overlapLeftTop = [Float](repeating: 0.0, count: 2)
        var overlapRightBottom = [Float](repeating: 0.0, count: 2)
        
        overlapLeftTop[0] = max(nextBox[0],currentBox[0]);
        overlapLeftTop[1] = max(nextBox[1],currentBox[1]);
        
        overlapRightBottom[0] = min(nextBox[2],currentBox[2]);
        overlapRightBottom[1] = min(nextBox[3],currentBox[3]);
        
        overlapArea = NMSUtils.AreaOf(leftTop: overlapLeftTop, rightBottom: overlapRightBottom)
        
        
        area0Left[0] = nextBox[0]; area0Left[1] = nextBox[1];
        area0Right[0] = nextBox[2]; area0Right[1] = nextBox[3];
        
        area1Left[0] = currentBox[0]; area1Left[1] = currentBox[1];
        area1Right[0] = currentBox[2]; area1Right[1] = currentBox[3];
        
        area0 = NMSUtils.AreaOf(leftTop: area0Left, rightBottom: area0Right)
        area1 = NMSUtils.AreaOf(leftTop: area1Left, rightBottom: area1Right)
        
        return (overlapArea / (area0 + area1 - overlapArea + eps))
    }
    
    static func AreaOf(leftTop: [Float], rightBottom: [Float]) -> Float{
        
        /** Compute the areas of rectangles given two corners.
         * Args:
         * left_top (N, 2): left top corner.
         *        right_bottom (N, 2): right bottom corner.
         *        Returns:
         * area (N): return the area. */
        
        var left = rightBottom[0] - leftTop[0]
        left = PriorsGen.clamp(value: left, minimum: 0.0, maximum: 1000.0)
        var right = rightBottom[1] - leftTop[1]
        right = PriorsGen.clamp(value: right, minimum: 0.0, maximum: 1000.0)
        
        return left * right
        
        
    }
}
