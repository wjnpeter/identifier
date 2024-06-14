//
//  AddPlantImagePickerVCWrapper.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 15/8/2022.
//

import SwiftUI
import PLKit

struct AddPlantImagePickerVCWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = AddPlantImagePickerViewController

    @Environment(\.presentationMode) private var presentationMode

    private let completion: CallbackOf<Result<UIImage, PKError>>?

    init(completion: CallbackOf<Result<UIImage, PKError>>? = nil) {
        self.completion = completion
    }

    private let sourceType: UIImagePickerController.SourceType = .camera

    func makeUIViewController(context: Self.Context) -> Self.UIViewControllerType {
        let imagePicker = AddPlantImagePickerViewController()
        imagePicker.completion = completion

        return imagePicker
    }

    func updateUIViewController(_ uiViewController: Self.UIViewControllerType, context: Self.Context) {

    }
}
