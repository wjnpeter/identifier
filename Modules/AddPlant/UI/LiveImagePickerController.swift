import UIKit
import AVFoundation
import Vision

class LiveImagePickerController: UIViewController {
	// MARK: - UI objects
    lazy var previewView: PreviewView = {
        let preview = PreviewView()

        view.addSubview(preview)

        preview.translatesAutoresizingMaskIntoConstraints = false
        preview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        preview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        preview.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        preview.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        return preview
    }()

    private var cutoutMaskLayer = CAShapeLayer()
    lazy private var cutoutView: UIView = {
        let cutout = UIView()

        cutout.backgroundColor = UIColor.gray.withAlphaComponent(0.5)

        cutoutMaskLayer.backgroundColor = UIColor.clear.cgColor
        cutoutMaskLayer.fillRule = .evenOdd
        cutout.layer.mask = cutoutMaskLayer

        view.addSubview(cutout)

        cutout.translatesAutoresizingMaskIntoConstraints = false
        cutout.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        cutout.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        cutout.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        cutout.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        return cutout
    }()

    lazy private var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        button.tintColor = .white

        view.addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false
        // FixMe: use theme
        button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15).isActive = true
        button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15).isActive = true

        return button
    }()

    private var constrainsPortrait: [NSLayoutConstraint] = []
    private var constrainsLandscape: [NSLayoutConstraint] = []
    lazy private var takePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "circle.circle.fill"), for: .normal)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.addTarget(self, action: #selector(handleTakePhoto), for: .touchUpInside)

        view.addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 68).isActive = true
        button.heightAnchor.constraint(equalToConstant: 68).isActive = true

        constrainsPortrait.append(contentsOf: [
            button.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15)
        ])
        constrainsLandscape.append(contentsOf: [
            button.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15)
        ])

        return button
    }()

    private var aimAtBorderLayer = CAShapeLayer()
    lazy private(set) var lblAimAt: UILabel = {
        let lbl = UILabel()
        lbl.text = "Aim at label"
        lbl.font = .systemFont(ofSize: 22, weight: .bold)
        lbl.textColor = .white
        lbl.textAlignment = .center

        aimAtBorderLayer.strokeColor = UIColor.white.cgColor
        aimAtBorderLayer.lineWidth = 5
        aimAtBorderLayer.fillColor = UIColor.clear.cgColor

        lbl.layer.addSublayer(aimAtBorderLayer)

        view.addSubview(lbl)

        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        lbl.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true

        lbl.widthAnchor.constraint(equalToConstant: 200).isActive = true
        lbl.heightAnchor.constraint(equalToConstant: 200).isActive = true

        return lbl
    }()

	// MARK: - Capture related objects
	private let captureSession = AVCaptureSession()
    private let captureSessionQueue = DispatchQueue(label: "com.example.apple-samplecode.CaptureSessionQueue")
    
    private var captureDevice: AVCaptureDevice?

    private var photoOutput = AVCapturePhotoOutput()
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "com.example.apple-samplecode.VideoDataOutputQueue")
    
	// MARK: - Region of interest (ROI) and text orientation
	// Region of video data output buffer that recognition should be run on.
	// Gets recalculated once the bounds of the preview layer are known.
    private(set) var regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
	// Orientation of text to search for in the region of interest.
    private(set) var textOrientation = CGImagePropertyOrientation.up
	
	// MARK: - Coordinate transforms
    private var bufferAspectRatio: Double!
	// Transform from UI orientation to buffer orientation.
    private var uiRotationTransform = CGAffineTransform.identity
	// Transform bottom-left coordinates to top-left.
    private var bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
	// Transform coordinates in ROI to global coordinates (still normalized).
    private var roiToGlobalTransform = CGAffineTransform.identity
	
	// Vision -> AVF coordinate transform.
    private(set) var visionToAVFTransform = CGAffineTransform.identity
	
	// MARK: - View controller methods
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Set up preview view.
		previewView.session = captureSession
        let _ = cutoutView
        let _ = (backButton, takePhotoButton, lblAimAt)

        // Starting the capture session is a blocking call. Perform setup using
        // a dedicated serial dispatch queue to prevent blocking the main thread.
        captureSessionQueue.async {
            self.setupCamera()
            
            // Calculate region of interest now that the camera is setup.
            DispatchQueue.main.async {
                // Figure out initial ROI.
                self.calculateRegionOfInterest()

                
            }
        }
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)

		// Orientation changed: figure out new region of interest (ROI).
		calculateRegionOfInterest()

        view.setNeedsUpdateConstraints()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		updateCutout()
	}
	
	// MARK: - Setup
	
    private func calculateRegionOfInterest() {
		let size = UIDevice.current.orientation.isLandscape ? CGSize(width: 0.6, height: 1) : CGSize(width: 1, height: 0.6)

		// Make it centered.
		regionOfInterest.origin = CGPoint(x: (1 - size.width) / 2, y: (1 - size.height) / 2)
        regionOfInterest.size = size
		
		// ROI changed, update transform.
		setupOrientationAndTransform()
		
		// Update the cutout to match the new ROI.
		DispatchQueue.main.async {
			// Wait for the next run cycle before updating the cutout. This
			// ensures that the preview layer already has its new orientation.
			self.updateCutout()
		}
	}
	
    private func updateCutout() {
		// Figure out where the cutout ends up in layer coordinates.
		let roiRectTransform = bottomToTopTransform.concatenating(uiRotationTransform)
		let cutout = previewView.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: regionOfInterest.applying(roiRectTransform))

		// Create the mask.
		let path = UIBezierPath(rect: cutoutView.frame)
		path.append(UIBezierPath(rect: cutout))
		cutoutMaskLayer.path = path.cgPath

        aimAtBorderLayer.path = makeFourCornersPath(for: lblAimAt)

        // Handle device orientation in the preview layer.
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            if let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation) {
                videoPreviewLayerConnection.videoOrientation = newVideoOrientation
            }
        }

	}

    private func makeFourCornersPath(for v: UIView) -> CGPath {
        let cornerLengthToShow = v.bounds.size.height * 0.10
        let vBounds = v.bounds

        // Create Paths Using BeizerPath for all four corners
        let topLeftCorner = UIBezierPath()
        topLeftCorner.move(to: CGPoint(x: vBounds.minX, y: vBounds.minY + cornerLengthToShow))
        topLeftCorner.addQuadCurve(to: CGPoint(x: vBounds.minX + cornerLengthToShow, y: vBounds.minY), controlPoint: CGPoint(x: vBounds.minX, y: vBounds.minY))

        let topRightCorner = UIBezierPath()
        topRightCorner.move(to: CGPoint(x: vBounds.maxX - cornerLengthToShow, y: vBounds.minY))
        topRightCorner.addQuadCurve(to: CGPoint(x: vBounds.maxX, y: vBounds.minY + cornerLengthToShow), controlPoint: CGPoint(x: vBounds.maxX, y: vBounds.minY))

        let bottomRightCorner = UIBezierPath()
        bottomRightCorner.move(to: CGPoint(x: vBounds.maxX, y: vBounds.maxY - cornerLengthToShow))
        bottomRightCorner.addQuadCurve(to: CGPoint(x: vBounds.maxX - cornerLengthToShow, y: vBounds.maxY), controlPoint: CGPoint(x: vBounds.maxX, y: vBounds.maxY))

        let bottomLeftCorner = UIBezierPath()
        bottomLeftCorner.move(to: CGPoint(x: vBounds.minX, y: vBounds.maxY - cornerLengthToShow))
        bottomLeftCorner.addQuadCurve(to: CGPoint(x: vBounds.minX + cornerLengthToShow, y: vBounds.maxY), controlPoint: CGPoint(x: vBounds.minX, y: vBounds.maxY))

        let combinedPath = CGMutablePath()
        combinedPath.addPath(topLeftCorner.cgPath)
        combinedPath.addPath(topRightCorner.cgPath)
        combinedPath.addPath(bottomRightCorner.cgPath)
        combinedPath.addPath(bottomLeftCorner.cgPath)

        return combinedPath
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        if UIDevice.current.orientation.isLandscape {
            NSLayoutConstraint.deactivate(constrainsPortrait)
            NSLayoutConstraint.activate(constrainsLandscape)

        } else {
            NSLayoutConstraint.deactivate(constrainsLandscape)
            NSLayoutConstraint.activate(constrainsPortrait)
        }
    }
	
    private func setupOrientationAndTransform() {
		// Recalculate the affine transform between Vision coordinates and AVF coordinates.
		
		// Compensate for region of interest.
		let roi = regionOfInterest
		roiToGlobalTransform = CGAffineTransform(translationX: roi.origin.x, y: roi.origin.y).scaledBy(x: roi.width, y: roi.height)
		
		// Compensate for orientation (buffers always come in the same orientation).
		switch UIDevice.current.orientation {
		case .landscapeLeft:
			textOrientation = CGImagePropertyOrientation.up
			uiRotationTransform = CGAffineTransform.identity
		case .landscapeRight:
			textOrientation = CGImagePropertyOrientation.down
			uiRotationTransform = CGAffineTransform(translationX: 1, y: 1).rotated(by: CGFloat.pi)
		case .portraitUpsideDown:
			textOrientation = CGImagePropertyOrientation.left
			uiRotationTransform = CGAffineTransform(translationX: 1, y: 0).rotated(by: CGFloat.pi / 2)
		default: // We default everything else to .portraitUp
			textOrientation = CGImagePropertyOrientation.right
			uiRotationTransform = CGAffineTransform(translationX: 0, y: 1).rotated(by: -CGFloat.pi / 2)
		}
		
		// Full Vision ROI to AVF transform.
		visionToAVFTransform = roiToGlobalTransform.concatenating(bottomToTopTransform).concatenating(uiRotationTransform)
	}
	
	private func setupCamera() {
		guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else {
			print("Could not create capture device.")
			return
		}
		self.captureDevice = captureDevice
		
		// NOTE:
		// Requesting 4k buffers allows recognition of smaller text but will
		// consume more power. Use the smallest buffer size necessary to keep
		// down battery usage.
		if captureDevice.supportsSessionPreset(.hd4K3840x2160) {
			captureSession.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
			bufferAspectRatio = 3840.0 / 2160.0
		} else {
			captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
			bufferAspectRatio = 1920.0 / 1080.0
		}

		guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
			print("Could not create device input.")
			return
		}
		if captureSession.canAddInput(deviceInput) {
			captureSession.addInput(deviceInput)
		}
		
		// Configure video data output.
		videoDataOutput.alwaysDiscardsLateVideoFrames = true
		videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
		videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
		if captureSession.canAddOutput(videoDataOutput) {
			captureSession.addOutput(videoDataOutput)
			// NOTE:
			// There is a trade-off to be made here. Enabling stabilization will
			// give temporally more stable results and should help the recognizer
			// converge. But if it's enabled the VideoDataOutput buffers don't
			// match what's displayed on screen, which makes drawing bounding
			// boxes very hard. Disable it in this app to allow drawing detected
			// bounding boxes on screen.
			videoDataOutput.connection(with: AVMediaType.video)?.preferredVideoStabilizationMode = .off
		} else {
			print("Could not add VDO output")
			return
		}

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
		
		// Set zoom and autofocus to help focus on very small text.
		do {
			try captureDevice.lockForConfiguration()
			captureDevice.autoFocusRangeRestriction = .near
			captureDevice.unlockForConfiguration()
		} catch {
			print("Could not set zoom level due to error: \(error)")
			return
		}
		
		captureSession.startRunning()
	}

    @objc private func handleDismiss() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc private func handleTakePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
}

extension LiveImagePickerController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let previewImage = UIImage(data: imageData)

    }
}

extension LiveImagePickerController: AVCaptureVideoDataOutputSampleBufferDelegate {
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		// This is implemented in VisionViewController.
	}
}
