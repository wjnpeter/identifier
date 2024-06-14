//
//  EditWireframe.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 11/3/2022.
//

import SwiftUI
import PLKit

class EditWireframe {
    var addWireframe: AddWireframe!

    // set this when you want to get notify for any changes from Edit module
    weak var delegate: EditModuleDelegate?

    func rootView(plant: Plant) -> some View {
        EditPlantView(vm: makePresenter(plant), addWireframe: addWireframe)
    }

    func plantSettingButton(plant: Plant) -> some View {
        EditPlantSettingButton(vm: makePresenter(plant))
    }

    private func makePresenter(_ plant: Plant) -> EditPlantViewModel {
        let presenter = EditPlantViewModel(plant: plant)
        presenter.delegate = delegate
        return presenter
    }
}
