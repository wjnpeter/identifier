//
//  EditPlantView.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 11/3/2022.
//

import SwiftUI
import PLKit

enum EditPlantTabCategories: String, CaseIterable {
    case diary, label, reminder, search

    static var supporttedCases: [Self] {
        [.diary, .label]
    }

    var isSupportted: Bool {
        Self.supporttedCases.contains(self)
    }
}

extension EditPlantView {
    enum Status {
        case browsing, editing
    }
}

struct EditPlantView: View {
    @EnvironmentObject var sharedUI: PKUI

    @ObservedObject var vm: EditPlantViewModel
    let addWireframe: AddWireframe

    private var plant: Plant {
        vm.editingPlant.isNotNil ? Plant(data: vm.editingPlant!) : vm.plant
    }

    @State private var selectedCategory: EditPlantTabCategories = .diary
    @State private var textfieldAlert: PKTextfieldAlertItem?

    @State private var status: Status = .browsing
    private var isEditing: Bool {
        status == .editing
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                vHeader
                vTitle
            }
            .padding()

            EditPlantTabView(vm: vm, selectedCategory: $selectedCategory, isEditing: isEditing)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                btnTopRight
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .textFieldAlert(item: $textfieldAlert)

        .onDisappear {
            vm.done()
        }
    }

    @ViewBuilder
    private var btnTopRight: some View {
        switch selectedCategory {
        case .label:
            if plant.labelInfo.hasUploadedLabel {
                // can edit label
                PKButton(isEditing ? pkls("done") : pkls("edit_label"), icon: UIImage(systemName: isEditing ? "checkmark" : "square.and.pencil")) {
                    if status == .editing { // done
                        vm.done()
                    } else if status == .browsing {
                        vm.start()
                    }

                    withAnimation {
                        status = isEditing ? .browsing : .editing
                    }
                }
                .onChange(of: isEditing) { isEditing in
                    withAnimation {
                        SettingViewModel.shared.plantAddable = !isEditing
                    }
                }
            } else {
                PKButton(pkls("upload_label")) {
                    sharedUI.fullScreenCoverView = AnyView(
                        PHPickerVCWrapper { result in
                            if let image = result.value?.image {
                                PLKHUD.show(withMessage: pkls("processing"))
                                Task {
                                    await vm.updateLabel(image)
                                    PLKHUD.dismiss()
                                }
                            }
                        }
                    )
                }
            }

        case .reminder:
            EmptyView()

        case .diary:
            PKButton(pkls("add_diary"), icon: UIImage(systemName: "plus"), action: {
                sharedUI.fullScreenCoverView = EditPlantAddDiaryView(vm: vm).asAnyView
            })

        case .search:
            EmptyView()
        }
    }

    private var vTitle: some View {
        HStack {
            PKText(plant.displayName, .title1, weight: .semibold)
                .onTapGesture {
                    if isEditing {
                        textfieldAlert = PKTextfieldAlertItem(title: pkls("change_name"), onEndEditing: vm.setName)
                    }
                }

            if isEditing {
                Image(systemName: "pencil")
            }
        }
    }

    private var vHeader: some View {
        HStack {
            Spacer()
            PKText(plant.displayCreatedDate, .footnote)
        }
        .foregroundColor(.gray)
    }
}

struct EditPlantView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EditPlantView(vm: EditPlantViewModel(plant: FakeBackend.plants.first!), addWireframe: AddWireframe())
            EditPlantView(vm: EditPlantViewModel(plant: FakeBackend.plants.first!), addWireframe: AddWireframe())
                .previewDevice("iPhone 12")
        }
    }
}
