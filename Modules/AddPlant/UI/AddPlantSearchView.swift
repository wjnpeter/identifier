//
//  AddPlantSearchView.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 17/8/2022.
//

import SwiftUI
import PLKit

struct AddPlantSearchView: View {
    var body: some View {
        VStack {
            vNav

            WKWebViewWrapper(string: "https://www.google.com/?tbm=isch")
        }
    }

    private var vNav: some View {
        Color.green
            .frame(height: 100)
            .onDrop(of: [.image, .png, .jpeg], delegate: self)
    }
}

extension AddPlantSearchView: DropDelegate {
    func performDrop(info: DropInfo) -> Bool {
        print(info)
        return false
    }


}

struct AddPlantSearchView_Previews: PreviewProvider {
    static var previews: some View {
        AddPlantSearchView()
    }
}

