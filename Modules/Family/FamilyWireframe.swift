//
//  FamilyWireframe.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 22/7/2022.
//

import SwiftUI
import PLKit

class FamilyWireframe {
    weak var delegate: FamilyModuleDelegate?

    init() {

    }

    func addButton() -> some View {
        FamilyAddButton(vm: makePresenter())
    }

    func listView() -> some View {
        FamilyListView(vm: makePresenter())
            .modifier(WithTitleBar(trailingItem: {
                addButton()
            }))
    }

    func makePresenter() -> FamilyViewModel {
        let presenter = FamilyViewModel()
        presenter.delegate = delegate
        return presenter
    }
}
