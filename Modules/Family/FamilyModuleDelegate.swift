//
//  FamilyModuleDelegate.swift
//  identifier-ios
//
//  Created by Pete Li on 28/7/2022.
//

import Foundation

protocol FamilyModuleDelegate: AnyObject {
    func familyModuleDidUpdateFamily(_ family: Family?)
}
