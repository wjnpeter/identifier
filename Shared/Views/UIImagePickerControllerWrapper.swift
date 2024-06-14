//
//  UIImagePickerControllerWrapper.swift
//  identifier-ios
//
//  Created by Pete Li on 10/3/2022.
//

import SwiftUI
import PLKit

struct UIImagePickerControllerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIImagePickerController

    @Environment(\.presentationMode) private var presentationMode

    var completion: CallbackOf<Result<UIImage, PKError>>?

    private let sourceType: UIImagePickerController.SourceType = .camera

    func makeUIViewController(context: Self.Context) -> Self.UIViewControllerType {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator

        return imagePicker
    }

    func updateUIViewController(_ uiViewController: Self.UIViewControllerType, context: Self.Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        var parent: UIImagePickerControllerWrapper

        init(_ parent: UIImagePickerControllerWrapper) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.completion?(.success(image))
            } else {
                parent.completion?(.failure(.canceled))
            }

            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion?(.failure(.canceled))

            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
