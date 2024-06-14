//
//  FamilyViewModel.swift
//  identifier-ios
//
//  Created by Pete Li on 23/7/2022.
//

import Foundation
import PLKit

class FamilyViewModel: ObservableObject {
    @Published var family: Family?

    weak var delegate: FamilyModuleDelegate?

    private let interactor = FamilyInteractor()

    var hasAccepted: Bool {
        family?.me?.hasAccepted ?? false
    }
    
    var hasPendingInvite: Bool {
        family?.me?.data.accept.isNil ?? false
    }

    func isOwner(_ member: FamilyMember) -> Bool {
        family?.members.firstIndex(of: member) == 0
    }

    func isMe(_ member: FamilyMember) -> Bool {
        family?.me == member
    }

    func updateFamily() async {
        do {
            let family = try await interactor.fetchFamily()
            
            onMain {
                self.family = family

                self.delegate?.familyModuleDidUpdateFamily(family)
            }

        } catch {
            onMain {
                self.family = nil
            }
            E(error.localizedDescription)
        }
    }

    func invite(email: String) async {
        do {
            let invitingMember = FamilyMember(invitingEmail: email)
            if family.isNil {
                // create a family with 1 member, myself
                try await interactor.createFamily(membersExcludeMe: [invitingMember])

                await updateFamily()

            } else {
                // add a new member with inviting email
                try await interactor.addMember(invitingMember, to: family!)
            }

        } catch {
            E(error.localizedDescription)
        }
    }

    func acceptInvite(_ accepted: Bool) async {
        assert(hasPendingInvite)
        do {
            try await interactor.setAcceptStatus(accepted, for: family!.me!, in: family!)

            await updateFamily()
        } catch {
            E(error.localizedDescription)
        }
    }
}
