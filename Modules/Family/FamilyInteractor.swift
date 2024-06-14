//
//  FamilyInteractor.swift
//  identifier-ios
//
//  Created by Pete Li on 23/7/2022.
//

import Foundation
import PLKit

public class FamilyInteractor {
    func fetchFamily() async throws -> Family? {
        guard let userId = authVM.userId else { return nil }

        await authVM.updateUserAttributes()

        // Filtering nested object not support yet
        // https://github.com/aws-amplify/amplify-category-api/issues/381
        // So have to filter on App end now
        let families =  try await backend.list(AMFamily.self)
            .filter { family in
                family.members.contains(where: {
                    // An account can be in other family but rejected
                    let isInvitedNNotRejected = $0.email.isNotNil && $0.email == authVM.userEmail && $0.accept != false
                    return $0.userId == userId || isInvitedNNotRejected
                })
            }

        assert(families.count <= 1, "Each account should be in 1 family")
        guard let data = families.first else { return nil }

        return Family(data: data)
    }

    func createFamily(membersExcludeMe: [FamilyMember] = []) async throws {
        // add me as the 1st member
        var namePrefix = "My"
        if let userName = authVM.userName {
            namePrefix = "\(userName)'s"
        }
        var newFamily = AMFamily(name: "\(namePrefix) Family")
        newFamily.members.append(AMFamilyMember(userId: authVM.userId, email: authVM.userEmail, nickname: authVM.userName, accept: true))

        // add specify members
        let initialMembers = membersExcludeMe.map(\.data)
        newFamily.members.append(contentsOf: initialMembers)

        try await newFamily.create()
    }

    func addMember(_ member: FamilyMember, to family: Family) async throws {
        var amFamily = family.data

        // remove if existed
        amFamily.members.removeAll(member.data)

        amFamily.members.append(member.data)

        try await amFamily.update()
    }

    func setAcceptStatus(_ status: Bool?, for member: FamilyMember, in family: Family) async throws {
        var amFamily = family.data
        guard let idxMember = amFamily.members.firstIndex(where: { $0 == member.data }) else {
            return
        }

        assert(amFamily.members[idxMember].email == authVM.userEmail)
        
        amFamily.members[idxMember].accept = status

        // fill profile
        amFamily.members[idxMember].userId = authVM.userId
        amFamily.members[idxMember].nickname = authVM.userNickName

        try await amFamily.update()
    }
}
