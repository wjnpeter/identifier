//
//  RootView.swift
//  identifier-ios
//
//  Created by Pete Li on 10/3/2022.
//

import SwiftUI
import PLKit

struct RootView: View {
    let listWireframe: ListWireframe
    let addWireframe: AddWireframe
    let authWireframe: AuthWireframe
    let settingWireframe: SettingWireframe

    @StateObject private var authPresenter = authVM
    @ObservedObject private var settings = SettingViewModel.shared

    var body: some View {
        NavigationStack {
            ZStack {
                if authVM.isNotLoggedIn {
                    vEmpty
                } else {
                    // Section - My Plant
                    listWireframe.rootView()
                }

                addWireframe.rootView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding([.bottom, .trailing])
            }
//            .navigationTitle("title")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if authVM.isLoggedIn {
                        NavigationLink {
                            settingWireframe.rootView()
                        } label: {
                            Label(pkls("me"), systemImage: "person")
                        }

                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            await authVM.tryLogIn()
        }
    }

    @ViewBuilder
    private var vEmpty: some View {
        VStack(spacing: themeVM.spacing.section) {
            PKText(pkls("add_your_first_plant"), .title3)

            HStack(alignment: .top, spacing: themeVM.spacing.section) {
                vNoPlantsStep(1, pkls("get_your_plants_label"))
                    .frame(minWidth: 150)

                vNoPlantSampleLabel
                    .frame(maxWidth: 450)
            }

            HStack(alignment: .top, spacing: themeVM.spacing.section) {
                PKImage(uiImage: UIImage(named: "person_capture"))
                    .frame(maxWidth: .infinity)

                vNoPlantsStep(2, pkls("capture_your_labels"))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(themeVM.spacing.section)
    }

    private func vNoPlantsStep(_ step: Int, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: themeVM.spacing.siblings) {
            PKText(pkls("step") + String(step))
                .foregroundColor(themeVM.secondaryColor)

            PKText(text)
        }
    }

    private var vNoPlantSampleLabel: some View {
        var sampleData = AMLabelInfo(name: "Monstera")
        sampleData.infoNumbers = [AMInfoNumberObject(infoNumber: .height, value: "30cm"),
                                  AMInfoNumberObject(infoNumber: .flowering, value: "15 days"),
                                  AMInfoNumberObject(infoNumber: .harvest, value: "4 weeks")]
        sampleData.paragraphs = ["Monstera is a substantial climbing evergreen tropical plant that naturally scales large trees..."]

        let sample = LabelInfo(data: sampleData)

        return ZStack {
            VStack(alignment: .leading) {
                PKText(sample.name.name, .headline)

                ForEach(LabelInfo.InfoNumber.allCases) { info in
                    if let infoNum = sample.infoNumbers[info] {
                        HStack {
                            Image(uiImage: info.icon)
                            PKText(infoNum, .subheadline)
                        }
                    }
                }

                PKText(sample.displayParagraph, .footnote)
                    .lineLimit(nil)
            }
            .modifier(WithinCard())

            PKImage(uiImage: UIImage(named: "monstera"))
                .frame(maxWidth: .infinity, maxHeight: 130, alignment: .topTrailing)
                .offset(x: 20, y: -60)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        let listWireframe = ListWireframe(editWireframe: EditWireframe())
        RootView(listWireframe: listWireframe, addWireframe: AddWireframe(), authWireframe: AuthWireframe(), settingWireframe: SettingWireframe())
            .previewDevice("iPhone 12")
    }
}
