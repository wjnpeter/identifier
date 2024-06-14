//
//  EditPlantViewModel.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 11/3/2022.
//

import Combine
import PLKit
import UIKit
import Amplify

class EditPlantViewModel: ObservableObject {
    @Published var plant: Plant

    @Published private(set) var editingPlant: AMPlant?

    weak var delegate: EditModuleDelegate?

    private let interactor = EditPlantInteractor()

    init() {
        self.plant = Plant()
    }

    init(plant: Plant) {
        self.plant = plant
    }

    func updateLabel(_ image: UIImage) async {
        start()

        Task {
            let amasset = await interactor.uploadImage(image)
            editingPlant?.labelInfo.originImage = amasset

            onMain {
                self.end()
            }
        }
    }

    func start() {
        if editingPlant.isNil {
            onMain {
                self.editingPlant = self.plant.data
            }
        }
    }

    private func end(completion: Callback? = nil) {
        guard editingPlant.isNotNil else { return }

        // EditPlantInteractor?
        Task {
            do {
                try await editingPlant?.update()

                onMain {
                    self.plant = Plant(data: self.editingPlant!)
                    self.editingPlant = nil

                    self.delegate?.editModuleDidUpdatePlant(self.plant)
                    completion?()
                }

            } catch {
                // FixMe: Let user know
                E(error.localizedDescription)
                PLKHUD.dismiss(withError: error.localizedDescription)
            }
        }
    }

    func delete() {
        Task {
            do {
                // 1. remove db
                try await plant.data.delete()

                // 2.remomve s3 image
                for amAsset in plant.allAmAssets {
                    await interactor.removeAsset(amAsset)
                }

                self.delegate?.editModuleDidUpdatePlant(self.plant)

            } catch {
                // FixMe: Let user know
                E(error.localizedDescription)
            }
        }

    }
}

// MARK: Edit
extension EditPlantViewModel {
    func setName(_ name: String) {
        guard name.isNotEmpty, name != plant.labelInfo.name.name else { return }

        start()
        editingPlant?.labelInfo.name = name
    }

    // nil to remove
    func setPositions(_ newPositions: [AmPosition]?) {
        start()
        editingPlant?.labelInfo.positions = newPositions
    }

    func setContainers(_ newContainers: [AmContainer]?) {
        start()
        editingPlant?.labelInfo.containers = newContainers
    }

    func addInfoNumber(_ infoNum: AMInfoNumberObject) {
        start()
        editingPlant?.labelInfo.infoNumbers?.append(infoNum)
    }

    func removeInfoNumber(_ infoNum: AmInfoNumber) {
        start()
        if let idx = editingPlant?.labelInfo.infoNumbers?.firstIndex(where: { $0.infoNumber == infoNum }) {
            editingPlant?.labelInfo.infoNumbers?.remove(at: idx)
        }
    }

    func setParagraph(_ displayParagraph: String) {
        start()
        let paragraphs = displayParagraph.components(separatedBy: LabelInfo.displayParagraphSeparator)
        editingPlant?.labelInfo.paragraphs = paragraphs
    }

    func changeCoverImage(_ uiImage: UIImage) {
        start()

        Task {
            let amasset = await interactor.uploadImage(uiImage)
            onMain { self.editingPlant?.coverImage = amasset }
        }
    }

    func done() {
        end()
    }

}

// MARK: Diary
extension EditPlantViewModel {
    func addDiary(_ date: Date, _ title: String, _ content: String, _ tags: [String], _ images: [UIImage], completion: Callback? = nil) {
        start()

        Task {
            var amAssets: [AMAsset] = []
            for img in images {
                amAssets.append(await interactor.uploadImage(img))
            }

            let amTags = tags.map { AMTag(title: $0) }

            let newDiary = AMDiary(date: Temporal.DateTime(date), title: title, content: content, assets: amAssets, tags: amTags)

            onMain {
                self.editingPlant?.diaries?.append(newDiary)
                self.end(completion: completion)
            }
        }
    }
}

// MARK: Family
extension EditPlantViewModel {
    var canModify: Bool { plant.isCreatedByCurrentUser }

    func toggleSharing() {
        assert(canModify)

        start()

        // FixMe: shouldn't need onMain here, but start() create onMain in onMain, so not created without
        onMain {
            self.editingPlant?.privacy = self.plant.isSharingWithFamily ? .private : .family

            self.end()
        }
    }
}
