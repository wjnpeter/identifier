//
//  ListPlantInteractor.swift
//  identifier-ios
//
//  Created by Pete Li on 9/3/2022.
//

import SwiftUI
import PLKit

class ListPlantInteractor {
    func fetchPlants(for userId: String? = nil) async throws -> [Plant] {
        guard let userId = userId ?? authVM.userId else { return [] }

        return try await backend.list(AMPlant.self, where: AMPlant.keys.userIds.contains(userId))
            .map { Plant(data: $0) }
    }
}
