//
//  ListPlantCard.swift
//  identifier-ios
//
//  Created by Pete Li on 11/3/2022.
//

import SwiftUI
import PLKit

struct ListPlantCard: View {
    let editWireFrame: EditWireframe
    @ObservedObject var plant: Plant
    @ObservedObject var themeVM = ThemeViewModel.shared

    @State private var isDetailPresented = false

    var body: some View {
        VStack {
            ZStack {
                PKImage(uiImage: plant.coverImage)

                if plant.isSharingWithFamily {
                    vPrivacy
                }
            }
            .onTapGesture {
                isDetailPresented = true
            }

            HStack {
                VStack(alignment: .leading) {
                    PKText(plant.displayName, .headline)
                        .foregroundColor(themeVM.textColorOnBrightBackground)

                    PKText(plant.labelInfo.positions.map(\.display).joined(separator: ", "), .subheadline)
                        .foregroundColor(.gray)
                }
                .onTapGesture {
                    isDetailPresented = true
                }

                Spacer()


                editWireFrame.plantSettingButton(plant: plant)
            }
        }
        .navigationDestination(isPresented: $isDetailPresented, destination: { editWireFrame.rootView(plant: plant) })
        .padding(.horizontal, themeVM.spacing.siblings)
        .padding(.vertical)
        .background(themeVM.brightBackgroundColor)
        .cornerRadius(themeVM.shape.cornerRadius)
        .fixedSize(horizontal: false, vertical: true)   // bug from WaterfallGrid: https://github.com/paololeonardi/WaterfallGrid/issues/53
    }

    @ViewBuilder
    private var vPrivacy: some View {
        VStack {
            HStack {
                GeometryReader { geo in
                    let w: CGFloat = geo.width / 4
                    let h: CGFloat = w * 9 / 16
                    RoundedRectangle(cornerRadius: themeVM.shape.cornerRadius)
                        .fill(themeVM.backgroundColor.opacity(0.8))
                        .overlay(
                            PKText(pkls("family"), .callout)
                                .foregroundColor(themeVM.textColorOnBackground)
                                .minimumScaleFactor(0.5)
                        )
                        .frame(width: w, height: h)
                }

                Spacer()
            }

            Spacer()
        }
        .padding(4)
    }
}

struct ListPlantCard_Previews: PreviewProvider {
    static var previews: some View {
        ListPlantCard(editWireFrame: EditWireframe(), plant: FakeBackend.plants.first!)
            .previewDevice("iPhone 12")
    }
}
