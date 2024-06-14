//
//  Family.swift
//  identifier-ios
//
//  Created by Pete Li on 22/7/2022.
//

import Foundation
import PLKit

public class Family: ObservableObject {
    private(set) var data: AMFamily
    var members: [FamilyMember] {
        data.members.map { FamilyMember(data: $0) }
    }

    var me: FamilyMember? {
        members.first(where: {
            $0.data.userId == authVM.userId || $0.data.email == authVM.userEmail
        })
    }

    init(data: AMFamily) {
        self.data = data
    }
}
