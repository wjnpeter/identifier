//
//  AddWireframe.swift
//  identifier-ios
//
//  Created by Pete Li on 10/3/2022.
//

import SwiftUI
import PLKit

class AddWireframe {
    var authWireframe: AuthWireframe!
    var editWireframe: EditWireframe!

    weak var delegate: AddModuleDelegate?

    init() {

    }

    func rootView() -> some View {
        AddPlantButton(authWireframe: authWireframe, editWireframe: editWireframe, vm: makePresenter())
    }

    func uploadLabelButton() -> some View {
        AddPlantUploadLabelButton(vm: makePresenter())
    }

    private func makePresenter() -> AddPlantViewModel {
        let presenter = AddPlantViewModel()
        presenter.delegate = delegate
        return presenter
    }
}
