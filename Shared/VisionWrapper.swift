//
//  VisionWrapper.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 10/1/2022.
//

import UIKit
import Vision
import PLKit

typealias VisionWrapperOutput = CallbackOfResult<[VNRecognizedTextObservation], Error>

public final class VisionWrapper {
    private var completion: VisionWrapperOutput?

    func request(_ image: UIImage, completion: @escaping VisionWrapperOutput) {
        guard let cgImage = image.cgImage else { return }

        do {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage)
            let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
            self.completion = completion

            try requestHandler.perform([request])

        } catch {
            self.completion = nil
            completion(.failure(error))
        }
    }

    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        if error.isNotNil {
            completion?(.failure(error!))
            return
        }

        let observations = request.results as? [VNRecognizedTextObservation]
        completion?(.success(observations ?? []))
    }
}

// flatten image
// let documentDetectionRequest = VNDetectDocumentSegmentationRequest()
// try? requestHandler.perform([documentDetectionRequest])
//        let width = Int(cgImage.width)
//        let height = Int(cgImage.height)
//        let filter = CIFilter(name:"CIPerspectiveCorrection")!
//
//        filter.setValue(CIImage(image: image), forKey: "inputImage")
//        filter.setValue(CIVector(cgPoint: VNImagePointForNormalizedPoint(rets!.first!.topLeft, width, height)), forKey: "inputTopLeft")
//        filter.setValue(CIVector(cgPoint: VNImagePointForNormalizedPoint(rets!.first!.topRight, width, height)), forKey: "inputTopRight")
//        filter.setValue(CIVector(cgPoint: VNImagePointForNormalizedPoint(rets!.first!.bottomLeft, width, height)), forKey: "inputBottomLeft")
//        filter.setValue(CIVector(cgPoint: VNImagePointForNormalizedPoint(rets!.first!.bottomRight, width, height)), forKey: "inputBottomRight")
//
//        let outputCIImage = filter.outputImage
//        let outputCGImage = CIContext(options: nil).createCGImage(outputCIImage!, from: outputCIImage!.extent)
//
//        PLKit.saveImageToTmpDir(outputCGImage!, "1")
