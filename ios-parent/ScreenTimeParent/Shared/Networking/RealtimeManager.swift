// RealtimeManager.swift
// Screen Time Parent
//
// Manages Supabase Realtime subscriptions for live updates

import Foundation
import Supabase
import Combine

@MainActor
class RealtimeManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var lastUpdate: Date?

    // MARK: - Dependencies

    private let client = SupabaseClientManager.shared.client
    private var channels: [String: RealtimeChannelV2] = [:]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Callbacks

    var onUsageSessionUpdate: ((UsageSession) -> Void)?
    var onEarnedTimeUpdate: ((EarnedTime) -> Void)?
    var onRuleUpdate: ((ScreenTimeRule) -> Void)?
    var onDeviceStatusUpdate: ((Device) -> Void)?

    // MARK: - Lifecycle

    init() {
        if Config.enableRealtime {
            print("📡 Realtime Manager initialized")
        }
    }

    deinit {
        Task { @MainActor in
            await disconnect()
        }
    }

    // MARK: - Public API

    /// Subscribe to all family-related updates
    func subscribeToFamily(familyId: UUID) async {
        guard Config.enableRealtime else {
            print("⚠️ Realtime subscriptions disabled")
            return
        }

        print("📡 Subscribing to family: \(familyId)")

        // Subscribe to usage sessions
        await subscribeToUsageSessions(familyId: familyId)

        // Subscribe to earned time
        await subscribeToEarnedTime(familyId: familyId)

        // Subscribe to rules
        await subscribeToRules(familyId: familyId)

        // Subscribe to devices
        await subscribeToDevices(familyId: familyId)

        connectionState = .connected
        lastUpdate = Date()
    }

    /// Unsubscribe from all channels
    func disconnect() async {
        print("📡 Disconnecting from all channels")

        for (name, channel) in channels {
            await client.realtime.removeChannel(channel)
            print("📡 Removed channel: \(name)")
        }

        channels.removeAll()
        connectionState = .disconnected
    }

    // MARK: - Private Subscriptions

    private func subscribeToUsageSessions(familyId: UUID) async {
        let channelName = "usage-sessions-\(familyId)"

        guard channels[channelName] == nil else {
            print("⚠️ Already subscribed to \(channelName)")
            return
        }

        let channel = client.realtime.channel(channelName)

        // Listen for INSERT events
        let insertChanges = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "usage_sessions",
            filter: "family_id=eq.\(familyId)"
        )

        // Listen for UPDATE events
        let updateChanges = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "usage_sessions",
            filter: "family_id=eq.\(familyId)"
        )

        await channel.subscribe()

        // Handle INSERT
        Task {
            for await change in insertChanges {
                if let session = try? JSONDecoder().decode(UsageSession.self, from: JSONEncoder().encode(change.record)) {
                    print("📱 New usage session: \(session.appName)")
                    onUsageSessionUpdate?(session)
                    lastUpdate = Date()
                }
            }
        }

        // Handle UPDATE
        Task {
            for await change in updateChanges {
                if let session = try? JSONDecoder().decode(UsageSession.self, from: JSONEncoder().encode(change.record)) {
                    print("🔄 Updated usage session: \(session.appName)")
                    onUsageSessionUpdate?(session)
                    lastUpdate = Date()
                }
            }
        }

        channels[channelName] = channel
        print("✅ Subscribed to usage sessions")
    }

    private func subscribeToEarnedTime(familyId: UUID) async {
        let channelName = "earned-time-\(familyId)"

        guard channels[channelName] == nil else { return }

        let channel = client.realtime.channel(channelName)

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "earned_time",
            filter: "family_id=eq.\(familyId)"
        )

        await channel.subscribe()

        Task {
            for await change in changes {
                if let earnedTime = try? JSONDecoder().decode(EarnedTime.self, from: JSONEncoder().encode(change.record)) {
                    print("⭐ Earned time updated: \(earnedTime.educationalMinutes)/\(earnedTime.requiredEducationalMinutes) min")
                    onEarnedTimeUpdate?(earnedTime)
                    lastUpdate = Date()
                }
            }
        }

        channels[channelName] = channel
        print("✅ Subscribed to earned time")
    }

    private func subscribeToRules(familyId: UUID) async {
        let channelName = "rules-\(familyId)"

        guard channels[channelName] == nil else { return }

        let channel = client.realtime.channel(channelName)

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "screen_time_rules",
            filter: "family_id=eq.\(familyId)"
        )

        await channel.subscribe()

        Task {
            for await change in changes {
                if let rule = try? JSONDecoder().decode(ScreenTimeRule.self, from: JSONEncoder().encode(change.record)) {
                    print("📋 Rule updated: \(rule.name)")
                    onRuleUpdate?(rule)
                    lastUpdate = Date()
                }
            }
        }

        channels[channelName] = channel
        print("✅ Subscribed to rules")
    }

    private func subscribeToDevices(familyId: UUID) async {
        let channelName = "devices-\(familyId)"

        guard channels[channelName] == nil else { return }

        let channel = client.realtime.channel(channelName)

        let changes = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "devices",
            filter: "family_id=eq.\(familyId)"
        )

        await channel.subscribe()

        Task {
            for await change in changes {
                if let device = try? JSONDecoder().decode(Device.self, from: JSONEncoder().encode(change.record)) {
                    print("📱 Device updated: \(device.deviceName)")
                    onDeviceStatusUpdate?(device)
                    lastUpdate = Date()
                }
            }
        }

        channels[channelName] = channel
        print("✅ Subscribed to devices")
    }

    // MARK: - Connection Management

    func reconnect() async {
        print("🔄 Reconnecting...")
        connectionState = .reconnecting

        // Remove all channels
        for channel in channels.values {
            await client.realtime.removeChannel(channel)
        }
        channels.removeAll()

        connectionState = .disconnected
    }
}

// MARK: - Supporting Types

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case error(Error)

    var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .reconnecting:
            return "Reconnecting..."
        case .error(let error):
            return "Error: \(error.localizedDescription)"
        }
    }

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}

// MARK: - Realtime Extensions

extension RealtimeChannelV2 {
    func postgresChange<T: Sendable>(
        _ type: T.Type,
        schema: String,
        table: String,
        filter: String
    ) -> AsyncStream<PostgresChangeEvent> {
        let (stream, continuation) = AsyncStream.makeStream(of: PostgresChangeEvent.self)

        Task {
            for await change in self.postgresChange(
                AnyAction.self,
                schema: schema,
                table: table,
                filter: filter
            ) {
                continuation.yield(change)
            }
            continuation.finish()
        }

        return stream
    }
}

struct PostgresChangeEvent: Sendable {
    let record: [String: Any]
    let eventType: String
}
