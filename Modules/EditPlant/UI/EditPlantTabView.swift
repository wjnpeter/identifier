//
//  EditPlantTabView.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 12/3/2022.
//

import SwiftUI
import PLKit
import Introspect

struct EditPlantTabView: View {
    @EnvironmentObject var sharedUI: PKUI

    @ObservedObject var vm: EditPlantViewModel
    @Binding var selectedCategory: EditPlantTabCategories
    let isEditing: Bool

    @FocusState private var isLabelFocused: Bool

    @State private var addingInfoNum: AMInfoNumberObject?
    @State private var textfieldAlert: PKTextfieldAlertItem?
    @State private var uploadingCover: UIImage?

    private var plant: Plant {
        vm.editingPlant.isNotNil ? Plant(data: vm.editingPlant!) : vm.plant
    }

    var body: some View {
        VStack {
            let tabs = isEditing ? [EditPlantTabCategories.label] : EditPlantTabCategories.supporttedCases
            EditPlantSegmentPicker(selection: $selectedCategory, options: tabs)

            Group {
                switch selectedCategory {
                case .diary:
                    EditPlantTabContentDiary(vm: vm)
                case .label:
                    EditPlantTabContentLabel(vm: vm, isEditing: isEditing)
                default:
                    EmptyView()
                }
            }
            .padding()
            .padding(.horizontal, themeVM.spacing.section * 2)
        }
        .background(themeVM.brightBackgroundColor)
        .cornerRadius(themeVM.shape.cornerRadius, corners: [.topLeft, .topRight])
        .frame(maxHeight: .infinity)
    }


}

struct EditPlantTabView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EditPlantTabView(vm: EditPlantViewModel(plant: FakeBackend.plants.first!), selectedCategory: .constant(.label), isEditing: false)
            EditPlantTabView(vm: EditPlantViewModel(plant: FakeBackend.plants.first!), selectedCategory: .constant(.label), isEditing: false)
                .previewDevice("iPhone 12")
        }
    }
}
