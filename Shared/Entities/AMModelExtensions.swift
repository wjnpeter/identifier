//
//  AMModelExtensions.swift
//  identifier-ios (iOS)
//
//  Created by Pete Li on 20/3/2022.
//

import CoreGraphics
import PLKit

extension AMInfoNumberObject {
    static func info(_ info: AmInfoNumber, _ value: String) -> Self {
        AMInfoNumberObject(infoNumber: info, value: value)
    }
}

extension AMInfoNumberObject: Equatable, Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(infoNumber)
    }

    public static func == (lhs: AMInfoNumberObject, rhs: AMInfoNumberObject) -> Bool {
        lhs.infoNumber == rhs.infoNumber && lhs.value == rhs.value
    }
}

extension AMAsset {
    init(s3key: String, size: CGSize?) {
        self.s3key = s3key
        self.width = size.isNil ? nil : size!.width // why not size?.width: xcode's bug
        self.height = size.isNil ? nil : size!.height
    }

    func downloadAndCache() async throws {
        guard let key = s3key, key.isNotEmpty else {
            throw PKError.invalidParam
        }

        guard cached().isNil else { return }

        let data = try await backend.download(key: key)
        let asset = Asset(data: self, downloadedData: data)

        Cache.the.cacheInMemory(asset, withKey: key, for: (30, .minute))
    }

    func cached() -> Asset? {
        guard let key = s3key else { return nil }

        return Cache.the.getIfNotExpired(key: key)?.value
    }
}

extension AMFamilyMember: Equatable {
    public static func == (lhs: AMFamilyMember, rhs: AMFamilyMember) -> Bool {
        // we don't compare nickname and accept, it's same member if they have same userId and email
        lhs.userId == rhs.userId && lhs.email == rhs.email
    }
}
