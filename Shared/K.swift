//
//  K.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 20/3/2022.
//

import Foundation
import PLKit

struct K {
    static let feedbackEMail = "appstudio.pc@gmail.com"

    struct S3Key {
        private static let base = "identifier"
        static let plants = "\(base)/plants"

        static var uploadBucket: String { "\(plants)/\(authVM.userId!)" }
    }

    struct IAP {
        static let donate   = "com.pcappstudio.identifier.donate.1"
    }
}
