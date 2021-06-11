//
//  CardScan_QuickReadTest.swift
//  CardScanExampleTests
//
//  Created by Jaime Park on 6/11/21.
//

import XCTest
@testable import CardScan

class CardScan_QuickReadTest: XCTestCase {
    // MARK: Linear
    let linearNumbers = [
        // chunk 0
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0,
            YMin: 0,
            XMax: 1,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 1,
            YMin: 0,
            XMax: 2,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 2,
            YMin: 0,
            XMax: 3,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 3,
            YMin: 0,
            XMax: 4,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        // chunk 1
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 4,
            YMin: 0,
            XMax: 5,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 5,
            YMin: 0,
            XMax: 6,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 6,
            YMin: 0,
            XMax: 7,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 7,
            YMin: 0,
            XMax: 8,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        // chunk 2
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 8,
            YMin: 0,
            XMax: 9,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 9,
            YMin: 0,
            XMax: 10,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 10,
            YMin: 0,
            XMax: 11,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 11,
            YMin: 0,
            XMax: 12,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        // chunk 3
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 12,
            YMin: 0,
            XMax: 13,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 13,
            YMin: 0,
            XMax: 14,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 14,
            YMin: 0,
            XMax: 15,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 15,
            YMin: 0,
            XMax: 16,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        )
    ]
    
    // MARK: QR
    let visaQuickReadNumbers = [
        // chunk 0
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0,
            YMin: 0,
            XMax: 1,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 1,
            YMin: 0,
            XMax: 2,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 2,
            YMin: 0,
            XMax: 3,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 3,
            YMin: 0,
            XMax: 4,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        // chunk 1
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0,
            YMin: 1,
            XMax: 1,
            YMax: 2,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 1,
            YMin: 1,
            XMax: 2,
            YMax: 2,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 2,
            YMin: 1,
            XMax: 3,
            YMax: 2,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 3,
            YMin: 1,
            XMax: 4,
            YMax: 2,
            imageSize: CGSize(width: 40, height: 40)
        ),
        // chunk 2
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0,
            YMin: 2,
            XMax: 1,
            YMax: 3,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 1,
            YMin: 2,
            XMax: 2,
            YMax: 3,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 2,
            YMin: 2,
            XMax: 3,
            YMax: 3,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 3,
            YMin: 2,
            XMax: 4,
            YMax: 3,
            imageSize: CGSize(width: 40, height: 40)
        ),
        // chunk 3
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0,
            YMin: 3,
            XMax: 1,
            YMax: 4,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 1,
            YMin: 3,
            XMax: 2,
            YMax: 4,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 2,
            YMin: 3,
            XMax: 3,
            YMax: 4,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 3,
            YMin: 3,
            XMax: 4,
            YMax: 4,
            imageSize: CGSize(width: 40, height: 40)
        )
    ]

    // MARK: Linear TLBR
    let linearNumbers_TopLeftBottomRight = [
        // chunk 0
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.0,
            YMin: 0.0,
            XMax: 0.0,
            YMax: 0.4,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.01,
            YMin: 0.04,
            XMax: 0.01,
            YMax: 0.44,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.02,
            YMin: 0.08,
            XMax: 0.02,
            YMax: 0.48,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.03,
            YMin: 0.12,
            XMax: 0.03,
            YMax: 0.52,
            imageSize: CGSize(width: 40, height: 40)
        ),
        // chunk 1
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.04,
            YMin: 0.16,
            XMax: 0.04,
            YMax: 0.56,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.05,
            YMin: 0.2,
            XMax: 0.05,
            YMax: 0.6,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.06,
            YMin: 0.24,
            XMax: 0.06,
            YMax: 0.64,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.07,
            YMin: 0.28,
            XMax: 0.07,
            YMax: 0.68,
            imageSize: CGSize(width: 40, height: 40)
        ),
        // chunk 2
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.08,
            YMin: 0.32,
            XMax: 0.08,
            YMax: 0.72,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.09,
            YMin: 0.36,
            XMax: 0.09,
            YMax: 0.76,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.1,
            YMin: 0.4,
            XMax: 0.1,
            YMax: 0.8,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.11,
            YMin: 0.44,
            XMax: 0.11,
            YMax: 0.84,
            imageSize: CGSize(width: 40, height: 40)
        ),
        // chunk 3
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.12,
            YMin: 0.48,
            XMax: 0.12,
            YMax: 0.88,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.13,
            YMin: 0.52,
            XMax: 0.13,
            YMax: 0.92,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.14,
            YMin: 0.56,
            XMax: 0.14,
            YMax: 0.96,
            imageSize:
                CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.15,
            YMin: 0.6,
            XMax: 0.15,
            YMax: 1.0,
            imageSize: CGSize(width: 40, height: 40)
        )
    ]
    
    // MARK: Linear BLTR
    let linearNumbers_BottomLeftTopRight = [
        // chunk 0
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0,
            YMin: 0.6,
            XMax: 0,
            YMax: 1,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.01,
            YMin: 0.56,
            XMax: 0.01,
            YMax: 0.96,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.02,
            YMin: 0.52,
            XMax: 0.02,
            YMax: 0.92,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.03,
            YMin: 0.48,
            XMax: 0.03,
            YMax: 0.88,
            imageSize: CGSize(width: 40, height: 40)
        ),
        // chunk 1
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.04,
            YMin: 0.44,
            XMax: 0.04,
            YMax: 0.84,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.05,
            YMin: 0.4,
            XMax: 0.05,
            YMax: 0.8,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.06,
            YMin: 0.36,
            XMax: 0.06,
            YMax: 0.76,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.07,
            YMin: 0.32,
            XMax: 0.07,
            YMax: 0.72,
            imageSize: CGSize(width: 40, height: 40)
        ),
        // chunk 2
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.08,
            YMin: 0.28,
            XMax: 0.08,
            YMax: 0.68,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.09,
            YMin: 0.24,
            XMax: 0.09,
            YMax: 0.64,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.1,
            YMin: 0.2,
            XMax: 0.1,
            YMax: 0.6,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.11,
            YMin: 0.16,
            XMax: 0.11,
            YMax: 0.56,
            imageSize: CGSize(width: 40, height: 40)
        ),
        // chunk 3
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.12,
            YMin: 0.12,
            XMax: 0.12,
            YMax: 0.52,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.13,
            YMin: 0.08,
            XMax: 0.13,
            YMax: 0.48,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 4,
            conf: 1,
            XMin: 0.14,
            YMin: 0.04,
            XMax: 0.14,
            YMax: 0.44,
            imageSize: CGSize(width: 40, height: 40)
        ),
        DetectedSSDOcrBox(
            category: 2,
            conf: 1,
            XMin: 0.15,
            YMin: 0,
            XMax: 0.15,
            YMax: 0.4,
            imageSize: CGSize(width: 40, height: 40)
        )
    ]
    
    func testOCRBoxes_LinearNumber() {
        var boxes = DetectedAllOcrBoxes()
        boxes.allBoxes = linearNumbers
        
        guard let number = OcrDDUtils.sortAndRemoveFalsePositives(allBoxes: boxes) else {
            XCTFail("testOCRBoxes_LinearNumber: Failed to produce card number")
            return
        }
        
        XCTAssertFalse(OcrDDUtils.isQuickRead(allBoxes: boxes))
        XCTAssert(number == "4242424242424242")
    }
    
    func testOCRBoxes_VisaQuickReadNumber() {
        var boxes = DetectedAllOcrBoxes()
        boxes.allBoxes = visaQuickReadNumbers
        
        guard let number = OcrDDUtils.processQuickRead(allBoxes: boxes) else {
            XCTFail("testOCRBoxes_VisaQuickReadNumber: Failed to produce card number")
            return
        }
        
        XCTAssertTrue(OcrDDUtils.isQuickRead(allBoxes: boxes))
        XCTAssert(number == "4242424242424242")
    }
    
    func testOCRBoxes_LinearNumberTopLeftBottomRight() {
        var boxes = DetectedAllOcrBoxes()
        boxes.allBoxes = linearNumbers_TopLeftBottomRight
        
        guard let number = OcrDDUtils.sortAndRemoveFalsePositives(allBoxes: boxes) else {
            XCTFail("testOCRBoxes_LinearNumberTopLeftBottomRight: Failed to produce card number")
            return
        }
        
        XCTAssertFalse(OcrDDUtils.isQuickRead(allBoxes: boxes))
        XCTAssert(number == "4242424242424242")
    }
    
    func testOCRBoxes_LinearNumberBottomLeftTopRight() {
        var boxes = DetectedAllOcrBoxes()
        boxes.allBoxes = linearNumbers_BottomLeftTopRight
        
        guard let number = OcrDDUtils.sortAndRemoveFalsePositives(allBoxes: boxes) else {
            XCTFail("testOCRBoxes_LinearNumber: Failed to produce card number")
            return
        }
        
        XCTAssertFalse(OcrDDUtils.isQuickRead(allBoxes: boxes))
        XCTAssert(number == "4242424242424242")
    }
}
