//
//  EditPlantSettingButton.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 27/7/2022.
//

import SwiftUI
import PLKit

struct EditPlantSettingButton: View {
    @EnvironmentObject var sharedUI: PKUI

    @ObservedObject var vm: EditPlantViewModel

    var body: some View {
        Menu(content: {
            if vm.canModify {
                optionFamily
                optionDelete
            }

        }, label: {
            Image(systemName: "ellipsis")
                .padding()
        })
    }

    @ViewBuilder
    private var optionDelete: some View {
        PKButton(pkls("delete_plant"), systemIcon: "trash.fill", action: {
            sharedUI.alert = PKAlertItem(title: pkls("are_you_sure"), primaryButton: .destructive(Text(pkls("delete")), action: {
                vm.delete()
            }), secondaryButton: .cancel())
        })
    }

    @ViewBuilder
    private var optionFamily: some View {
        let text = vm.plant.isSharingWithFamily ? pkls("remove_sharing") : pkls("share_with_my_family")
        let icon = vm.plant.isSharingWithFamily ? "person.fill" : "person.2.fill"
        PKButton(text.capitalized, systemIcon: icon, action: {
            vm.toggleSharing()
        })
    }
}

struct EditPlantSettingButton_Previews: PreviewProvider {
    static var previews: some View {
        EditPlantSettingButton(vm: EditPlantViewModel(plant: FakeBackend.plants.first!))
    }
}
