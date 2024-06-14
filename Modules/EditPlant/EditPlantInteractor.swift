//
//  EditPlantInteractor.swift
//  identifier-ios
//
//  Created by Pete Li on 27/7/2022.
//

import UIKit
import PLKit

public class EditPlantInteractor {
    func share(_ plant: Plant) async throws {
        var amPlant = plant.data
        amPlant.privacy = .family

        try await amPlant.update()
    }

    func unshare(_ plant: Plant) async throws {
        var amPlant = plant.data
        amPlant.privacy = .private

        try await amPlant.update()
    }

    func removeAsset(_ asset: AMAsset) async {
        do {
            guard let s3Key = asset.s3key else { return }
            assert(s3Key.contains(K.S3Key.uploadBucket))
            try await backend.remove(key: s3Key)

        } catch {
            E(error.localizedDescription)
        }
    }
}

// TidyTODO: duplicate code with AddPlantInteractor
extension EditPlantInteractor {
    private func formatImage(_ image: UIImage) -> UIImage {
        PlatformImageSize.scaling(image, to: .large)
    }

    func uploadImage(_ image: UIImage) async -> AMAsset {
        PLKHUD.show(withMessage: pkls("uploading"), modal: true)

        let formattedImage = formatImage(image)

        let s3Key = "\(K.S3Key.uploadBucket)/\(Date().timeIntervalSince1970.int)"

        do {
            try await backend.upload(key: s3Key, uiImage: formattedImage)
        } catch {
            // FixMe: Let user know
            E(error.localizedDescription)
            PLKHUD.dismiss(withError: error.localizedDescription)
        }

        PLKHUD.success()
        return AMAsset(s3key: s3Key, size: formattedImage.size)
    }
}
