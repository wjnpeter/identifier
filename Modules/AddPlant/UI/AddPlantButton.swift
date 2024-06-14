//
//  AddPlantButton.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 16/2/2022.
//

import SwiftUI
import PhotosUI
import PLKit

extension AddPlantButton {
    enum DiaryType: Identifiable {
        case blank(Plant)

        var id: String { anyToString(self) }
    }
}

// from camera, library, link, icloud drive
struct AddPlantButton: View {
    @EnvironmentObject var sharedUI: PKUI

    let authWireframe: AuthWireframe
    let editWireframe: EditWireframe

    @ObservedObject var vm: AddPlantViewModel
    @ObservedObject var authVM = AuthViewModel.shared

//    @State private var showOptions = false
    @State private var diaryType: DiaryType?

    @State private var textfieldAlert: PKTextfieldAlertItem?

    var body: some View {
        PKButton(icon: UIImage(systemName: "plus"), action: {
            if authVM.isNotLoggedIn {
                sharedUI.fullScreenCoverView = AnyView(
                    authWireframe.rootView()
                        .modifier(WithTitleBar())
                )

            } else {
                textfieldAlert = PKTextfieldAlertItem(title: pkls("plant_name"), onEndEditing: { text in
                    guard text.isNotEmpty else { return }

                    PLKHUD.show(withMessage: pkls("processing"))
                    Task {
                        let plant = await vm.addLabel(fromName: text)
                        PLKHUD.dismiss()

                        plant.ifLet {
                            diaryType = .blank($0)
                        }
                    }
                })
            }
        })
        .asCircle()
//        .confirmationDialog(pkls("add_label"), isPresented: $showOptions) {
//            Button(pkls("normal_diary")) {
//                textfieldAlert = PKTextfieldAlertItem(title: pkls("plant_name"), onEndEditing: { text in
//                    guard text.isNotEmpty else { return }
//
//                    PLKHUD.show(withMessage: pkls("processing"))
//                    Task {
//                        let plant = await vm.addLabel(fromName: text)
//                        PLKHUD.dismiss()
//
//                        plant.ifLet {
//                            diaryType = .blank($0)
//                        }
//                    }
//                })
//            }
//
//            Button(pkls("cancel"), role: .cancel) { showOptions = false }
//        }
        .fullScreenCover(item: $diaryType, content: { diaryType in
            switch diaryType {
            case .blank(let plant):
                editWireframe.rootView(plant: plant)
                    .modifier(WithTitleBar())
            }
        })
        .textFieldAlert(item: $textfieldAlert)
    }
}

struct AddPlantButton_Previews: PreviewProvider {
    static var previews: some View {
        AddPlantButton(authWireframe: AuthWireframe(), editWireframe: EditWireframe(), vm: AddPlantViewModel())
    }
}
