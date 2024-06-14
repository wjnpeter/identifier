//
//  ListPlantView.swift
//  identifier-ios
//
//  Created by Pete Li on 9/3/2022.
//

import SwiftUI
import WaterfallGrid
import PLKit

struct ListPlantView: View {
    let editWireFrame: EditWireframe
    @ObservedObject var vm: ListPlantViewModel
    @ObservedObject var themeVM = ThemeViewModel.shared

    private var displayPlants: [Plant] {
        vm.plants + vm.sharingPlants
    }

    var body: some View {
        // assume wrap within NavigationView
        ScrollView(showsIndicators: false) {
            WaterfallGrid(displayPlants, content: {
                ListPlantCard(editWireFrame: editWireFrame, plant: $0)
            })
            .gridStyle(columnsInPortrait: isPad ? 3 : 2,
                       columnsInLandscape: isPad ? 4 : 3)
            .padding(.horizontal)
        }
        .background(themeVM.backgroundColor)
        .onReceive(authVM.$isLoggedIn) { _ in
            Task {
                await vm.updatePlants()
            }
        }
    }
}

struct ListPlantView_Previews: PreviewProvider {
    static var previews: some View {
        ListPlantView(editWireFrame: EditWireframe(), vm: ListPlantViewModel())
            .previewDevice("iPhone 12")
    }
}
