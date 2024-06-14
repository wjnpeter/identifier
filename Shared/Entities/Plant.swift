//
//  Plant.swift
//  identifier-ios
//
//  Created by Pete Li on 10/3/2022.
//

import UIKit
import PLKit

class Plant: ObservableObject, Identifiable {
    var data: AMPlant

    @Published var labelInfo: LabelInfo
    @Published var diaries: [Diary] = []
    // cached assets that belongs to Plant, different from assets in Dairy
    @Published var assets: [Asset] = []
    var amAssets: [AMAsset] {
        [data.coverImage, data.labelInfo.originImage].compactMap({ $0 })
    }

    var allAmAssets: [AMAsset] {
        amAssets + diaries.flatMap(\.amAssets)
    }

    init() {
        let labelInfoData = AMLabelInfo(name: "New Plant")
        let userIds = authVM.userId.isNotEmpty ? [authVM.userId!] : []
        self.data = AMPlant(userIds: userIds, labelInfo: labelInfoData)
        self.labelInfo = LabelInfo(data: labelInfoData)
    }

    init(data: AMPlant, assets: [Asset] = []) {
        self.data = data
        self.labelInfo = LabelInfo(data: data.labelInfo)
        self.diaries = data.diaries?
            .sorted(by: { $0.date > $1.date })
            .map { Diary(data: $0) } ?? []
        self.assets = assets

        if assets.isEmpty {
            Task {
                await prepare()
            }
        }
    }

    var id: String { data.id }

    var hasBackendCreated: Bool { data.createdAt.isNotNil }
    var isCreatedByCurrentUser: Bool { data.userIds.first == authVM.userId }
    var isSharingWithFamily: Bool { data.privacy == .family }

    var coverImage: UIImage? {
        data.coverImage?.cached()?.image ?? assets.first?.image
    }

    private func prepare() async {
        try? await data.coverImage?.downloadAndCache()
        try? await labelInfo.data.originImage?.downloadAndCache()

        onMain {
            self.assets = []
            if let coverAsset = self.data.coverImage?.cached() {
                self.assets.append(coverAsset)
            }

            if let originAsset = self.labelInfo.data.originImage?.cached() {
                self.assets.append(originAsset)
            }
        }
    }
}

extension Plant {
    var displayName: String {
        labelInfo.name.display.capitalized
    }

    var displayCreatedDate: String {
        let dtFmt = DateFormatter()
        dtFmt.calendar = Calendar.current
        dtFmt.timeZone = TimeZone.current
        dtFmt.dateFormat = "dd/MMM/yyyy"

//        if dtFmt.calendar.isDateInToday(createdAt) {
//            return "Today"
//        }
        return dtFmt.string(from: data.createdAt?.foundationDate ?? Date())
    }
}
