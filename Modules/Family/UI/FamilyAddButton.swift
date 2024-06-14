//
//  FamilyAddButton.swift
//  identifier-ios
//
//  Created by Pete Li on 23/7/2022.
//

import SwiftUI
import PLKit

struct FamilyAddButton: View {
    @EnvironmentObject var sharedUI: PKUI

    @ObservedObject var vm: FamilyViewModel

    @State private var textfieldAlert: PKTextfieldAlertItem?

    var body: some View {
        PKButton(icon: icon, action: {
            if vm.hasPendingInvite { // invited
                let inviteFrom = authVM.userEmail ?? authVM.userNickName
                let title = (inviteFrom.isNotEmpty ? "\(inviteFrom!) " : "") + pkls("invite_you_to_join_his_family")
                sharedUI.alert = PKAlertItem(title: title,
                                             primaryButton: .default(Text(pkls("accept")), action: {
                    Task {
                        await vm.acceptInvite(true)
                    }
                }),
                                             secondaryButton: .destructive(Text(pkls("reject")), action: {
                    Task {
                        await vm.acceptInvite(false)
                    }
                }))

            } else {    // in a family, or rejected an invite
                textfieldAlert = PKTextfieldAlertItem(title: pkls("invite_your_family_to_manage_plants_together"),
                                                      message: pkls("simply_enter_the_email_below"),
                                                      textDone: pkls("send_invite"),
                                                      onEndEditing: { enteredEmail in
                    Task {
                        if PKUtils.isValidEmail(enteredEmail) {
                            PLKHUD.show()
                            await vm.invite(email: enteredEmail)
                            PLKHUD.success()
                        }
                    }
                })
            }
            
        })
            .asCircle()
            .task {
                await self.vm.updateFamily()
            }
            .textFieldAlert(item: $textfieldAlert)
    }

    private var icon: UIImage? {
        vm.hasPendingInvite ? UIImage(systemName: "exclamationmark") : UIImage(systemName: "person.badge.plus")
    }
}

struct FamilyButton_Previews: PreviewProvider {
    static var previews: some View {
        FamilyAddButton(vm: FamilyViewModel())
    }
}
