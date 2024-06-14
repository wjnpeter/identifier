//
//  AppDependencies.swift
//  identifier-ios
//
//  Created by Pete Li on 9/3/2022.
//

import SwiftUI
import PLKit

class AppDependencies {
    private var listWireframe: ListWireframe!
    private var addWireframe: AddWireframe!
    private var authWireframe: AuthWireframe!
    private var settingWireframe: SettingWireframe!
    private var editWireframe: EditWireframe!
    private var familyWireframe: FamilyWireframe!

    init() {

    }

    func rootView() -> some View {
        initialze()
        return RootView(listWireframe: listWireframe, addWireframe: addWireframe, authWireframe: authWireframe, settingWireframe: settingWireframe)
            .task {
                await self.prepare()
            }
    }

    private func initialze() {
        if listWireframe.isNil {
            listWireframe = ListWireframe()
        }
        if addWireframe.isNil {
            addWireframe = AddWireframe()
        }
        if authWireframe.isNil {
            authWireframe = AuthWireframe()
        }
        if settingWireframe.isNil {
            settingWireframe = SettingWireframe()
        }
        if editWireframe.isNil {
            editWireframe = EditWireframe()
        }
        if familyWireframe.isNil {
            familyWireframe = FamilyWireframe()
        }

        configureDependencies()
    }

    private func configureDependencies() {
        // TODO: make wireframe singleton
        listWireframe.editWireframe = editWireframe

        settingWireframe.authWireframe = authWireframe
        settingWireframe.familyWireframe = familyWireframe

        addWireframe.authWireframe = authWireframe
        addWireframe.editWireframe = editWireframe

        editWireframe.addWireframe = addWireframe

        editWireframe.delegate = listWireframe.presenter
        addWireframe.delegate = listWireframe.presenter
        familyWireframe.delegate = listWireframe.presenter
    }

    private func prepare() async {
        await familyWireframe.makePresenter().updateFamily()
    }
}
