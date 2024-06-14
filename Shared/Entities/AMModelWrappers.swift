//
//  AMModelWrappers.swift
//  identifier-ios
//
//  Created by Pete Li on 23/3/2022.
//

import UIKit
import PLKit

struct Asset: Identifiable {
    var id: String {
        data.s3key ?? UUID().uuidString
    }

    let data: AMAsset
    let downloadedData: Data

    var image: UIImage? { UIImage(data: downloadedData) }

    init(data: AMAsset, downloadedData: Data) {
        self.data = data
        self.downloadedData = downloadedData
    }
}

struct FamilyMember: Identifiable, Equatable {
    var id: String = UUID().uuidString

    let data: AMFamilyMember

    init(invitingEmail email: String) {
        self.data = AMFamilyMember(email: email)
    }

    init(data: AMFamilyMember) {
        self.data = data
    }

    var displayName: String {
        data.nickname ?? data.email ?? data.userId ?? pkls("unknown")
    }

    var hasAccepted: Bool {
        data.accept.isTrue
    }

    var displayAcceptStatus: String {
        if data.accept.isNil {
            return pkls("pending")
        } else if !data.accept! {
            return pkls("rejected")
        } else {
            return ""   // no need to show accepted
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data == rhs.data
    }
}
