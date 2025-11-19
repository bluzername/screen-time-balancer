// DeviceRepository.swift
// Screen Time Child
//
// Device registration and management

import Foundation
import Supabase
import UIKit

protocol DeviceRepositoryProtocol {
    func registerDevice(_ request: RegisterDeviceRequest) async throws -> Device
    func updateDeviceLastSync(deviceId: UUID) async throws
    func getDeviceInfo(deviceId: UUID) async throws -> Device
}

class DeviceRepository: DeviceRepositoryProtocol {
    private let client = SupabaseClientManager.shared.client

    func registerDevice(_ request: RegisterDeviceRequest) async throws -> Device {
        return try await client.database
            .from("devices")
            .insert(request)
            .select()
            .single()
            .execute()
            .value
    }

    func updateDeviceLastSync(deviceId: UUID) async throws {
        try await client.database
            .from("devices")
            .update(["last_sync": Date().iso8601String])
            .eq("id", value: deviceId.uuidString)
            .execute()
    }

    func getDeviceInfo(deviceId: UUID) async throws -> Device {
        return try await client.database
            .from("devices")
            .select()
            .eq("id", value: deviceId.uuidString)
            .single()
            .execute()
            .value
    }
}

// MARK: - Device Model

struct Device: Codable, Identifiable {
    let id: UUID
    let childId: UUID
    let familyId: UUID
    let deviceName: String
    let deviceIdentifier: String
    let platform: DevicePlatform
    let osVersion: String?
    let appVersion: String?
    let lastSync: Date?
    let isActive: Bool
    let registeredAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case childId = "child_id"
        case familyId = "family_id"
        case deviceName = "device_name"
        case deviceIdentifier = "device_identifier"
        case platform
        case osVersion = "os_version"
        case appVersion = "app_version"
        case lastSync = "last_sync"
        case isActive = "is_active"
        case registeredAt = "registered_at"
    }
}

enum DevicePlatform: String, Codable {
    case ios = "ios"
    case ipados = "ipados"
    case android = "android"
}

// MARK: - Register Device Request

struct RegisterDeviceRequest: Codable {
    let childId: UUID
    let familyId: UUID
    let deviceName: String
    let deviceIdentifier: String
    let platform: DevicePlatform
    let osVersion: String
    let appVersion: String

    enum CodingKeys: String, CodingKey {
        case childId = "child_id"
        case familyId = "family_id"
        case deviceName = "device_name"
        case deviceIdentifier = "device_identifier"
        case platform
        case osVersion = "os_version"
        case appVersion = "app_version"
    }
}

// MARK: - Device Info Helper

extension DeviceRepository {
    static func getCurrentDeviceInfo(childId: UUID, familyId: UUID) -> RegisterDeviceRequest {
        let device = UIDevice.current

        return RegisterDeviceRequest(
            childId: childId,
            familyId: familyId,
            deviceName: device.name,
            deviceIdentifier: device.identifierForVendor?.uuidString ?? UUID().uuidString,
            platform: device.userInterfaceIdiom == .pad ? .ipados : .ios,
            osVersion: device.systemVersion,
            appVersion: Config.appVersion
        )
    }
}
