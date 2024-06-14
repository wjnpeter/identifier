import UIKit
import AVFoundation
import Vision
import PLKit

class AddPlantImagePickerViewController: LiveImagePickerController {
    var completion: CallbackOf<Result<UIImage, PKError>>?

    private var request: VNRecognizeTextRequest!

	override func viewDidLoad() {
		// Set up vision request before letting ViewController set up the camera
		// so that it exists when the first buffer is received.
		request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

		super.viewDidLoad()

        Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.shouldRun = true
        })
	}
	
	// MARK: - Text recognition
	
	// Vision recognition handler.

	func recognizeTextHandler(request: VNRequest, error: Error?) {
        var textBoxes = [TextBoxGroup]()

		guard let results = request.results as? [VNRecognizedTextObservation] else {
			return
		}
		
		let maximumCandidates = 1

		for visionResult in results {
			guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }

            textBoxes.append((candidate.string, visionResult.boundingBox))
		}

        show(textBoxes: textBoxes)

	}

    override func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            completion?(.failure(.general))
            return
        }

        guard let previewImage = UIImage(data: imageData) else {
            completion?(.failure(.general))
            return
        }

        completion?(.success(previewImage))
        dismiss(animated: true)
    }

    var shouldRun = false
	override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard shouldRun else { return }

        shouldRun = false

		if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {

			// Configure for running in real-time.
			request.recognitionLevel = .fast
			// Language correction won't help recognizing phone numbers. It also
			// makes recognition slower.
			request.usesLanguageCorrection = false
			// Only run on the region of interest for maximum speed.
			request.regionOfInterest = regionOfInterest
			
			let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])
			do {
				try requestHandler.perform([request])
			} catch {
				print(error)
			}
		}
	}
	
	// MARK: - Bounding box drawing

    private var textLayers = [CATextLayer]()

    typealias TextBoxGroup = (text: String, box: CGRect)

    private func draw(text: String, at rect: CGRect) {
        let layer = FitFontSizeTextLayer()
        layer.string = text
        layer.opacity = 0.5
        layer.frame = rect
        textLayers.append(layer)
        previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
    }

    private func removeTexts() {
        for layer in textLayers {
            layer.removeFromSuperlayer()
        }
        textLayers.removeAll()
    }

    private func show(textBoxes: [TextBoxGroup]) {
        DispatchQueue.main.async {
            self.removeTexts()

            let layer = self.previewView.videoPreviewLayer
            for textBox in textBoxes {
                let rect = layer.layerRectConverted(fromMetadataOutputRect: textBox.box.applying(self.visionToAVFTransform))
                self.draw(text: textBox.text, at: rect)

            }

            self.lblAimAt.isHidden = !textBoxes.isEmpty
        }
    }
	
	// Draw a box on screen. Must be called from main queue.
	var boxLayer = [CAShapeLayer]()
	private func draw(rect: CGRect, color: CGColor) {
		let layer = CAShapeLayer()
		layer.opacity = 0.5
		layer.borderColor = color
		layer.borderWidth = 1
		layer.frame = rect
		boxLayer.append(layer)
		previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
	}
	
	// Remove all drawn boxes. Must be called on main queue.
    private func removeBoxes() {
		for layer in boxLayer {
			layer.removeFromSuperlayer()
		}
		boxLayer.removeAll()
	}
}
