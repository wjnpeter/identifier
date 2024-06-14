//
//  EditPlantAddDiaryView.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 4/4/2022.
//

import SwiftUI
import PLKit
import MobileCoreServices

struct EditPlantAddDiaryView: View {
    @EnvironmentObject var sharedUI: PKUI
    @Environment(\.dismiss) var dismiss

    @ObservedObject var vm: EditPlantViewModel

    @State private var enteringTitle: String = ""
    @State private var enteringContent: String = ""
    @State private var enteringDate = Date()
    @State private var attachments: [any AttachmentPreviewable] = []
    @State private var tags: [String] = []

    @State private var confirmationDialogPresented = false
    @State private var fullScreenCoverView: AnyView?
    @State private var textfieldAlert: PKTextfieldAlertItem?

    // testing
//    @State private var attachments: [any AttachmentPreviewable] = [MediaAttachmentPreview(id: "0", image: UIImage(named: "monstera")!)]
//    @State private var tags: [String] = ["in pot"]

    // TODO: remove
    @State private var enteringImages: [UIImage] = [Self.emptyImage]
    static private let emptyImage = UIImage(systemName: "plus")!

    // (idx, camera or library)
    @State private var changingImage: (idx: Int, source: Source)?

    private var displayNow: String {
        let dtFmt = DateFormatter()
        dtFmt.dateFormat = "dd/MMM/yyy"
        return dtFmt.string(from: Date())
    }

    var body: some View {
        ZStack {
            VStack {
                vTitle

                vDescription
                    .padding(.bottom)

                vTags
                    .padding(.bottom)
                vPresetTags
                    .padding(.bottom)

                vAttachments
                    .padding(.bottom)

                Spacer()
            }

            btnAdd
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding([.bottom, .trailing])

        }
        .padding()
        .modifier(WithTitleBar(pkls("create_diary"), trailingItem: {
            Button(action: onSave, label: {
                Text(pkls("save"))
            })
        }))
        .fullScreenCover(isPresented: Binding(get: { fullScreenCoverView.isNotNil },
                                              set: { if !$0 { fullScreenCoverView = nil }
        }), content: { fullScreenCoverView })
    }

    @ViewBuilder
    private var btnAdd: some View {
        PKButton(icon: UIImage(systemName: "plus")) { confirmationDialogPresented = true }
            .asCircle()
            .textFieldAlert(item: $textfieldAlert)
            .confirmationDialog(pkls("add"), isPresented: $confirmationDialogPresented) {
                Button(pkls("photos")) {
                    fullScreenCoverView = AnyView(
                        PHPickerVCWrapper { result in
                            if let pickerResult = result.value {
                                self.attachments.append(MediaAttachmentPreview(id: pickerResult.identifier, image: pickerResult.image))
                            }
                        }
                    )
                }

                Button(pkls("tag")) {
                    textfieldAlert = PKTextfieldAlertItem(title: pkls("new_tag"), onEndEditing: { tags.append($0) })
                }

                Button(pkls("cancel"), role: .cancel) { confirmationDialogPresented = false }
            }
    }

    @ViewBuilder
    private var vTitle: some View {
        HStack {
            TextField("", text: $enteringTitle, prompt: Text("Title").foregroundColor(.gray))
                .padding(themeVM.spacing.siblings)
                .overlay(
                    RoundedRectangle(cornerRadius: themeVM.shape.cornerRadius)
                        .stroke(themeVM.accentColor)
                )

            DatePicker("", selection: $enteringDate, displayedComponents: .date)
                .labelsHidden()
        }

    }

    @ViewBuilder
    private var vDescription: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $enteringContent)
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: themeVM.shape.cornerRadius)
                        .stroke(themeVM.accentColor)
                )

            if enteringContent.isEmpty {
                Text("What would you like to record...")
                    .offset(x: themeVM.spacing.siblings, y: themeVM.spacing.siblings)
                    .font(Font(themeVM.regularFont(.body)))
                    .foregroundColor(.gray)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var vPresetTags: some View {
        let presetTags = (LabelInfo.Container.allKeywords + LabelInfo.Position.allKeywords)
            .filter { tags.contains($0) == false }
        SwiftUIFlowLayout(mode: .scrollable,
                          items: presetTags) { tag in
            Label(title: { Text(tag) }, icon: {
                Button(action: {
                    tags.append(tag)
                }, label: {
                    Image(systemName: "plus.circle.fill").foregroundColor(themeVM.secondaryColor)
                })
            })
            .padding(themeVM.spacing.siblings)
            .foregroundColor(themeVM.textColorOnBackground)
            .overlay(
                RoundedRectangle(cornerRadius: themeVM.shape.cornerRadiusPrimaryButton)
                    .stroke(themeVM.brightBackgroundColor, lineWidth: themeVM.shape.borderWidth)
            )
        }
    }

    @ViewBuilder
    private var vTags: some View {
        SwiftUIFlowLayout(mode: .scrollable,
                          items: tags) { tag in
            Label(title: { Text(tag) }, icon: {
                Button(action: {
                    tags.removeAll(tag)
                }, label: {
                    Image(systemName: "multiply.circle.fill").foregroundColor(themeVM.secondaryColor)
                })
            })
            .padding(themeVM.spacing.siblings)
            .background(themeVM.brightBackgroundColor)
            .foregroundColor(themeVM.textColorOnBrightBackground)
            .cornerRadius(themeVM.shape.cornerRadiusPrimaryButton)
        }
                          .padding()
                          .overlay(
                            RoundedRectangle(cornerRadius: themeVM.shape.cornerRadius)
                                .stroke(themeVM.accentColor)
                          )
    }

    @ViewBuilder
    private var vAttachments: some View {
        SwiftUIFlowLayout(mode: .scrollable,
                          items: attachments) { attachment in
            if let mediaAttachment = attachment as? MediaAttachmentPreview {
                mediaAttachmentPreview(mediaAttachment)
            }
        }
    }

    @ViewBuilder
    private func mediaAttachmentPreview(_ attachment: MediaAttachmentPreview) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: attachment.image)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .cornerRadius(themeVM.shape.cornerRadius)

//            if attachmentPreview.fileType == String(kUTTypeMovie) {
//                Image(uiImage: Asset.Posts.videoAttachment.image)
//            }

            Button(action: {
                attachments.removeAll(where: { $0.id == attachment.id })

            }, label: { Image(systemName: "multiply.circle.fill") })

        }
    }

    @ViewBuilder
    private var vPhotos: some View {
        VStack {
            PKText(pkls("upload_photos"))
                .frame(maxWidth: .infinity, alignment: .leading)

                let columns = Array(repeating: GridItem(.flexible(), spacing: themeVM.spacing.section), count: isPhonePortrait ? 1 : 2)
                LazyVGrid(columns: columns, alignment: .center, spacing: themeVM.spacing.section * 2) {
                    ForEach(Array(enteringImages.enumerated()), id: \.offset) { (idx, image) in
                        HStack(spacing: themeVM.spacing.superview) {
                            RoundedRectangle(cornerRadius: themeVM.shape.cornerRadius)
                                .stroke(themeVM.secondaryColor, lineWidth: 1)
                                .overlay {
                                    if idx == 0 {
                                        Image(uiImage: image)
                                            .imageScale(.small)
                                    } else {
                                        PKImage(uiImage: image)
                                            .padding()
                                    }
                                }
                                .clipped()

                            vPhotoActions(for: idx)
                        }
                    }
                }
            }

    }

    private func vPhotoActions(for idx: Int) -> some View {
        VStack(spacing: themeVM.spacing.section) {
            PKButton(icon: UIImage(systemName: "photo.on.rectangle.angled")) {
                changingImage = (idx, .photos)
            }
            .asCircle()

            PKButton(icon: UIImage(systemName: "camera")) {
                changingImage = (idx, .camera)
            }
            .asCircle()

            PKButton(icon: UIImage(systemName: "trash")) {
                withAnimation {
                    _ = enteringImages.remove(at: idx)
                }
            }
            .asCircle()
            .isHidden(idx == 0)
        }
        .fullScreenCover(isPresented: .constant(changingImage.isNotNil), content: {
            switch changingImage!.source {
            case .photos:
                PHPickerVCWrapper(completion: { result in
                    if let image = result.value?.image {
                        onChangedImage(image)
                    }
                })
            case .camera:
                UIImagePickerControllerWrapper(completion: { result in
                    if let image = result.value {
                        onChangedImage(image)
                    }
                })
            }
        })
    }

    private func onChangedImage(_ image: UIImage) {
        assert(changingImage.isNotNil)

        withAnimation {
            if changingImage!.idx == 0 {    // adding new
                enteringImages.insert(image, at: 1)
            } else {
                enteringImages[changingImage!.idx] = image
            }
        }

        withAnimation {
            changingImage = nil
        }
    }

    private func onSave() {
        let uiImages = attachments
            .compactMap { $0 as? MediaAttachmentPreview }
            .map(\.image)
        vm.addDiary(enteringDate, enteringTitle, enteringContent, tags, uiImages) {
            dismiss()
        }
    }
}

protocol AttachmentPreviewable: Identifiable {
    var id: String { get }
}

struct MediaAttachmentPreview: AttachmentPreviewable {
    var id: String
    var image: UIImage
//        var isVideo = false
}

extension EditPlantAddDiaryView {
    enum Source {
        case photos, camera
    }
}

struct EditPlantAddDiaryView_Previews: PreviewProvider {
    static var previews: some View {
        EditPlantAddDiaryView(vm: EditPlantViewModel())
            .previewDevice("iPhone 12")
    }
}
