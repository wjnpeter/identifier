//
//  EditPlantTabContentDiary.swift
//  identifier-ios
//
//  Created by Pete Li on 12/11/2023.
//

import SwiftUI
import PLKit

struct EditPlantTabContentDiary: View {
    @ObservedObject var vm: EditPlantViewModel

    private var plant: Plant {
        vm.editingPlant.isNotNil ? Plant(data: vm.editingPlant!) : vm.plant
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if plant.diaries.isEmpty {
                    PKText(pkls("no_diary"), .title3)
                        .padding(.bottom)
                }

                ForEach(plant.diaries) { diary in
                    vDiary(diary)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func vDiary(_ diary: Diary) -> some View {
        HStack(alignment: .top, spacing: themeVM.spacing.section) {
            // line
            VStack(spacing: 0) {
                Circle()
                    .frame(width: 17, height: 17)
                    .foregroundColor(themeVM.accentColor)
                    .shadow(color: themeVM.accentColor, radius: themeVM.shape.shadowRadius)

                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(themeVM.secondaryColor)

            }

            VStack(alignment: .leading) {
                if diary.assets.isNotEmpty {
                    vAttachments(diary.assets)
                        .padding(.bottom, themeVM.spacing.siblings / 2)
                }

                vTags(diary.data.tags?.map(\.title) ?? [])

                PKText(diary.data.title, .title3)
                    .padding(.bottom, themeVM.spacing.siblings / 2)

                HStack {
                    if let authName = authVM.userNickName {
                        PKText("\(authName),")
                    }
                    PKText(diary.displayDate)
                }
                .padding(.bottom, themeVM.spacing.siblings / 2)

                PKText(diary.displayContent)
                    .padding(.bottom, themeVM.spacing.siblings / 2)

            }
            .padding(.bottom)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func vAttachments(_ assets: [Asset]) -> some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(assets) {
                    PKImage(uiImage: $0.image)
                        .frame(maxHeight: 256)
                        .cornerRadius(themeVM.shape.cornerRadius)
                }
            }
        }
        .scrollDisabled(assets.count < 3)
    }

    @ViewBuilder
    private func vTags(_ tags: [String]) -> some View {
        SwiftUIFlowLayout(mode: .scrollable,
                          items: tags) { tag in
            PKText(tag)
                .padding(themeVM.spacing.siblings)
                .background(themeVM.secondaryColor)
                .foregroundColor(themeVM.textColorOnBackground)
                .cornerRadius(themeVM.shape.cornerRadiusPrimaryButton)
        }
    }
}

#Preview {
    EditPlantTabContentDiary(vm: EditPlantViewModel(plant: FakeBackend.plants.first!))
}
