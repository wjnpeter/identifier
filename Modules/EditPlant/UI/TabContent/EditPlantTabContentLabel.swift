//
//  EditPlantTabContentLabel.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 14/4/2022.
//

import SwiftUI
import PLKit

struct EditPlantTabContentLabel: View {
    @EnvironmentObject var sharedUI: PKUI

    @ObservedObject var vm: EditPlantViewModel
    let isEditing: Bool

    private var plant: Plant {
        vm.editingPlant.isNotNil ? Plant(data: vm.editingPlant!) : vm.plant
    }

    @FocusState private var isLabelFocused: Bool
    @State private var addingInfoNum: AMInfoNumberObject?
    @State private var textfieldAlert: PKTextfieldAlertItem?
    @State private var uploadingCover: UIImage?

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                vContentLabelInfos

                vContentLabelCover
            }

            Divider()

            // TODO: Edit in a full screen textview
            // elegant way but has bug https://github.com/siteline/SwiftUI-Introspect/issues/142
            if isEditing {
                TextEditor(text: Binding(get: {
                    plant.labelInfo.displayParagraph
                }, set: { newParagraph in
                    vm.setParagraph(newParagraph)
                }))
                    .onAppear {
                        UITextView.appearance().backgroundColor = .clear
                    }
                    .focused($isLabelFocused)
            } else {
                ScrollView(showsIndicators: false) {
                    PKText(plant.labelInfo.displayParagraph)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .textFieldAlert(item: $textfieldAlert)
    }

    private var vContentLabelCover: some View {
        PKImage(uiImage: uploadingCover ?? plant.coverImage)
            .cornerRadius(themeVM.shape.cornerRadius)
            .overlay(
                themeVM.backgroundColor
                    .opacity(0.4)
                    .overlay(
                        PKText(pkls("change_cover"), .title1)
                            .foregroundColor(themeVM.textColorOnBackground)
                    )
                    .onTapGesture {
                        sharedUI.fullScreenCoverView = AnyView(
                            PHPickerVCWrapper { result in
                                if let image = result.value?.image {
                                    onMain {
                                        withAnimation {
                                            self.uploadingCover = image
                                        }
                                    }

                                    vm.changeCoverImage(image)
                                }
                            }
                        )
                    }
                    .isHidden(!isEditing)
            )

    }

    private var vContentLabelInfos: some View {
        VStack(alignment: .leading) {
            let labelInfo = plant.labelInfo

            let positions = labelInfo.positions
            if positions.isNotEmpty {
                let displayPositions = positions.map(\.display).joined(separator: "/")
                vInfo(positions.first!.icon, pkls("position"), displayPositions, onRemove: {
                    vm.setPositions(nil)
                })
            }

            let containers = labelInfo.containers
            if containers.isNotEmpty {
                let displayContainers = containers.map(\.display).joined(separator: "/")
                vInfo(UIImage(systemName: "leaf.fill")!, pkls("container"), displayContainers, onRemove: {
                    vm.setContainers(nil)
                })
            }

            ForEach(LabelInfo.InfoNumber.allCases) { info in
                if let infoNum = labelInfo.infoNumbers[info] {
                    vInfo(info.icon, info.display, infoNum, onRemove: {
                        vm.removeInfoNumber(info.data)
                    })
                }
            }

            if isEditing {
                if addingInfoNum.isNotNil {
                    vAddingInfoNum
                } else {
                    PKButton("Add", icon: UIImage(systemName: "plus"), action: {
                        withAnimation {
                            addingInfoNum = AMInfoNumberObject(infoNumber: .harvest, value: "30 days to harvest")
                        }
                    })
                    .asSecondary()
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func vInfo(_ icon: UIImage, _ title: String, _ info: String, onRemove: Callback?) -> some View {
        HStack {
            Image(uiImage: icon.withRenderingMode(.alwaysTemplate))
                .foregroundColor(themeVM.accentColor)

            VStack(alignment: .leading) {
                if title.isNotEmpty {
                    PKText(title, .caption1)
                        .foregroundColor(themeVM.secondaryColor)
                }

                PKText(info)
            }

            Spacer()

            if isEditing {
                PKButton(icon: UIImage(systemName: "minus.circle"), action: {
                    sharedUI.alert = PKAlertItem(title: pkls("do_you_want_to_delete?"), primaryButton: .destructive(Text(pkls("delete"))) {
                        onRemove?()
                    }, secondaryButton: .cancel())
                })
                    .frame(width: 32, height: 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var vAddingInfoNum: some View {
        HStack {
            let infoNum = LabelInfo.InfoNumber(data: addingInfoNum!.infoNumber)

            Image(uiImage: infoNum.icon)
                .foregroundColor(themeVM.accentColor)

            VStack(alignment: .leading) {
                Menu(infoNum.display) {
                    ForEach(LabelInfo.InfoNumber.allCases) { aInfoNumber in
                        PKButton(aInfoNumber.display) {
                            withAnimation {
                                addingInfoNum?.infoNumber = aInfoNumber.data
                            }
                        }
                    }
                }

                PKText(addingInfoNum!.value)
                    .onTapGesture {
                        assert(isEditing)
                        textfieldAlert = PKTextfieldAlertItem(title: pkls("enter_a_description"), onEndEditing: {
                            if $0.isNotEmpty {
                                addingInfoNum?.value = $0
                            }
                        })
                    }
            }

            Spacer()

            HStack(spacing: 0) {
                PKButton(icon: UIImage(systemName: "checkmark.circle"), action: {
                    vm.addInfoNumber(addingInfoNum!)
                    withAnimation {
                        addingInfoNum = nil
                    }
                })
                    .frame(width: 32, height: 32)
                    .padding()

                PKButton(icon: UIImage(systemName: "multiply.circle"), action: {
                    withAnimation {
                        addingInfoNum = nil
                    }
                })
                    .frame(width: 32, height: 32)
                    .padding()
            }
        }
        .padding(.vertical)
    }
}

struct EditPlantAddReminderView_Previews: PreviewProvider {
    static var previews: some View {
        EditPlantTabContentLabel(vm: EditPlantViewModel(plant: FakeBackend.plants.first!), isEditing: false)
    }
}
