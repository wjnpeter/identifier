//
//  FamilyListView.swift
//  identifier-ios
//
//  Created by Pete Li on 26/7/2022.
//

import SwiftUI
import PLKit

struct FamilyListView: View {
    @ObservedObject var vm: FamilyViewModel
    
    var body: some View {
        VStack {
            vMembers
        }
    }

    private var vMembers: some View {
        VStack(alignment: .leading) {
            PKText(pkls("my_family"), .largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)

            if let family = vm.family {
                List(family.members) {
                    rowMember($0)
                }

            } else {
                PKText("You are not belong to any families, tap the add button to invite your family member to manage plants together!", .title1)
            }

            Spacer()
        }
        .padding()
    }

    private func rowMember(_ member: FamilyMember) -> some View {
        HStack {
            PKText(member.displayName)

            if vm.isMe(member) {
                PKText("(\(pkls("you")))")
            } else if vm.isOwner(member) {
                PKText("(\(pkls("owner")))")
            }

            Spacer()

            PKText(member.displayAcceptStatus)

            if vm.isMe(member) && !vm.hasAccepted {
                // show accept/reject for pending/rejected invite

                // .buttonStyle:
                // https://stackoverflow.com/questions/56561064/swiftui-multiple-buttons-in-a-list-row
                HStack {
                    PKButton(systemIcon: "checkmark", action: {
                        Task {
                            await vm.acceptInvite(true)
                        }
                    })
                    .asCircle()
                    .buttonStyle(PlainButtonStyle())

                    PKButton(systemIcon: "xmark", action: {
                        Task {
                            await vm.acceptInvite(false)
                        }
                    })
                    .asCircle()
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct FamilyListView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyListView(vm: FamilyViewModel())
    }
}
