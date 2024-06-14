//
//  PHPickerVCWrapper.swift
//  identifier-ios
//
//  Created by Pete Li on 10/3/2022.
//

import SwiftUI
import PhotosUI
import PLKit

struct PHPickerVCWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = PHPickerViewController

    @Environment(\.presentationMode) private var presentationMode

    var completion: CallbackOf<Result<UIImage, PKError>>?

    func makeUIViewController(context: Self.Context) -> Self.UIViewControllerType {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let imagePicker = PHPickerViewController(configuration: config)
        imagePicker.delegate = context.coordinator

        return imagePicker
    }

    func updateUIViewController(_ uiViewController: Self.UIViewControllerType, context: Self.Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PHPickerVCWrapper

        init(_ parent: PHPickerVCWrapper) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            defer { parent.presentationMode.wrappedValue.dismiss() }

            guard let imgProvider = results.first?.itemProvider else {
                parent.completion?(.failure(.canceled))
                return
            }

            guard imgProvider.canLoadObject(ofClass: UIImage.self) else {
                parent.completion?(.failure(.canceled))
                return
            }

            imgProvider.loadObject(ofClass: UIImage.self) { img, _ in
                if let selectedImage = img as? UIImage {
                    let normalisedImage = selectedImage.upOrientationImage()!
//                    PKUtils.saveImageToTmpDir(normalisedImage.cgImage!, "1")
                    self.parent.completion?(.success(normalisedImage))
                } else {
                    self.parent.completion?(.failure(.canceled))
                }
            }
        }

    }
}
