//
//  SettingWireframe.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 29/3/2022.
//

import SwiftUI
import PLKit

class SettingWireframe {
    var authWireframe: AuthWireframe!
    var familyWireframe: FamilyWireframe!

    func rootView() -> some View {
        SettingRootView(authWireframe: authWireframe, familyWireframe: familyWireframe)
    }
}
