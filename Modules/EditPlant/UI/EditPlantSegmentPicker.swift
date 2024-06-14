//
//  EditPlantSegmentPicker.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 12/3/2022.
//

import SwiftUI
import PLKit

struct EditPlantSegmentPicker: View {
    @Namespace var editPlantSegmentPicker

    @Binding var selection: EditPlantTabCategories
    let options: [EditPlantTabCategories]

    var body: some View {
        HStack(alignment: .top) {
            ForEach(options, id: \.rawValue) { op in
                vOption(op)
            }
        }
    }

    private func vOption(_ op: EditPlantTabCategories) -> some View {
        VStack(spacing: 0) {
            let isSelected = op == selection

            let style = PKButtonStyle(width: 322, height: 48, textStyle: .title3, fontWeight: .medium, foreground: isSelected ? themeVM.accentColor : themeVM.textColorOnBackground)
            PKButton(op.rawValue.capitalized, style: style) {
                withAnimation { selection = op }
            }

            if isSelected {
                let w = 10.0
                Circle()
                    .foregroundColor(themeVM.accentColor)
                    .frame(width: w, height: w)
                    .offset(y: -7)
                    .matchedGeometryEffect(id: 0, in: editPlantSegmentPicker)
            }

        }
    }
}

struct EditPlantSegments_Previews: PreviewProvider {
    static var previews: some View {
        EditPlantSegmentPicker(selection: .constant(.label), options: EditPlantTabCategories.allCases)
    }
}
