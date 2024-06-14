//
//  ListWireframe.swift
//  identifier-ios
//
//  Created by Pete Li on 9/3/2022.
//

import SwiftUI

class ListWireframe {
    var editWireframe: EditWireframe!
    let presenter = ListPlantViewModel()

    init() {
        self.editWireframe = nil    // should inject later
    }

    init(editWireframe: EditWireframe) {
        self.editWireframe = editWireframe
    }

    func rootView() -> some View {
        ListPlantView(editWireFrame: editWireframe, vm: presenter)
    }
}
