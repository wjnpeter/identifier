//
//  ListPlantViewModel.swift
//  identifier-ios
//
//  Created by Pete Li on 9/3/2022.
//

import Combine
import PLKit

class ListPlantViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var sharingPlants: [Plant] = []

    private let interactor = ListPlantInteractor()

    func updatePlants() async {
        do {
            let plants = try await interactor.fetchPlants()

            onMain {
                self.plants = plants
            }

        } catch {
            onMain { self.plants = [] }
            E(error.localizedDescription)
        }
    }

    func updateSharingPlants(_ family: Family?) async {
        do {
            var sharingPlants: [Plant] = []

            let memberIds = family?.members
                .filter({ $0 != family!.me })
                .filter(\.hasAccepted)
                .compactMap(\.data.userId) ?? []

            for id in memberIds {
                sharingPlants += try await interactor.fetchPlants(for: id)
            }

            onMain {
                self.sharingPlants = sharingPlants
            }

        } catch {
            onMain { self.sharingPlants = [] }
            E(error.localizedDescription)
        }
    }
}

extension ListPlantViewModel: AddModuleDelegate {
    func addModuleDidCreatePlant(_ plant: Plant) {
        Task {
            await updatePlants()
        }
    }
}

extension ListPlantViewModel: EditModuleDelegate {
    func editModuleDidUpdatePlant(_ plant: Plant) {
        Task {
            await updatePlants()
        }
    }
}

extension ListPlantViewModel: FamilyModuleDelegate {
    func familyModuleDidUpdateFamily(_ family: Family?) {
        Task {
            await updateSharingPlants(family)
        }
    }
}
