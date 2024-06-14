//
//  Tests_AddLabelParseLabelInfo.swift
//  Tests iOS
//
//  Created by Pete Li on 28/2/2022.
//

import XCTest
import PLKit

class TestAddModule: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSamples() throws {
        FakeBackend.samples.forEach { (imgName, expecting) in
            testSample(imgName, expecting: expecting)
        }
    }

    func testingSamples() throws {
        Self.testingSamples.forEach { (imgName, expecting) in
            testSample(imgName, expecting: expecting)
        }
    }
}

extension TestAddModule {
    private func testSample(_ imageName: String, expecting: AMLabelInfo) {
        print("Start: testSample: \(imageName)")
        extractTexts(fromImage: imageName) { label in
            XCTAssertNotNil(label)

            XCTAssert(label!.name == expecting.name)
            XCTAssert(Set(label!.positions!) == Set(expecting.positions!))
            XCTAssert(Set(label!.containers!) == Set(expecting.containers!))
            XCTAssert(Set(label!.infoNumbers!) == Set(expecting.infoNumbers!))

            XCTAssert(label!.paragraphs.count == expecting.paragraphs.count)
            expecting.paragraphs?.enumerated().forEach { _, paragraph in
                XCTAssert(label!.paragraphs!.contains(paragraph))
            }
        }
    }

    private func extractTexts(fromImage named: String, completion: @escaping CallbackOf<AMLabelInfo?>) {
        VisionWrapper().request(uiImage(named: named)) {
            if case let .success(results) = $0 {
                let labelInfo = AddPlantInteractor().parse(recognizedResult: results)
                completion(labelInfo)
            } else {
                completion(nil)
            }
        }

    }
}

// Utils
extension TestAddModule {
    private func uiImage(named: String) -> UIImage {
        UIImage(named: named, in: Bundle(for: TestAddModule.self), with: nil)!
    }
}

// expecting sample data
extension TestAddModule {

    private static let testingSamples: [String: AMLabelInfo] = [
        "sample1": AMLabelInfo(originImage: nil, name: "CINERARIA SILVERDUST",
                               positions: [.fullSun, .partShade],
                               containers: [.gardenBed, .pot],
                               paragraphs: ["Senecio maritima.",
                                            "The striking leaves of finely cut, silvery white, velvety foliage are superb for adding contrast and texture. Sometimes known as \'Dusty Miller, yellow daisy. like flowers are produced in summer. Pohlmans CINERARIA SILVERDUST iS ideal for-beds, borders, containers and cottage gardens. Once established will be drought tolerant and low maintenance.", "GROWING: Easy to grow, preferring a well drained soil or standard approved potting mix. Through the warmer months mulch around the plants root base to reduce water stress."],
                               infoNumbers: [.info(.height, "25-30CM"),
                                             .info(.flowering, "10-14 WEEKS")])
    ]
}
