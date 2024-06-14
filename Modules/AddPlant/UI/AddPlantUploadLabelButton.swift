//
//  AddPlantUploadLabelButton.swift
//  identifier-ios
//
//  Created by Pete Li on 12/11/2023.
//

import SwiftUI
import PLKit

struct AddPlantUploadLabelButton: View {
    @EnvironmentObject var sharedUI: PKUI

    @ObservedObject var vm: AddPlantViewModel

    var body: some View {
        PKButton(pkls("upload_label")) {
            sharedUI.fullScreenCoverView = AnyView(
                PHPickerVCWrapper { result in
                    if let image = result.value?.image {
                        PLKHUD.show(withMessage: pkls("processing"))
                        Task {
                            await vm.addLabel(fromImage: image)
                            PLKHUD.dismiss()
                        }
                    }
                }
            )
        }
    }
}

#Preview {
    AddPlantUploadLabelButton(vm: AddPlantViewModel())
}
