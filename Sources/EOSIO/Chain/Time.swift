/// EOSIO time types.
/// - Author: Johan Nordberg <code@johan-nordberg.com>

import Foundation

/// Type representing a timestap with microsecond accuracy.
public struct TimePoint: Equatable, Hashable {
    internal static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return formatter
    }()

    /// Nanoseconds since 1970.
    public var value: Int64

    /// Create a new instance.
    /// - Parameter value: Nanoseconds since 1970.
    public init(_ value: Int64) {
        self.value = value
    }

    /// Create a new instance from a date.
    public init(_ date: Date) {
        self.value = Int64(date.timeIntervalSince1970 * 1_000_000)
    }

    /// Create a new instance from a `TimePointSec`
    public init(_ timePointSec: TimePointSec) {
        self.value = Int64(timePointSec.value) * 1_000_000
    }

    /// Create a new instance from a ISO 8601-ish date.
    /// - Parameter stringValue: Date string, e.g. `2019-01-22T21:42:55.123`.
    public init?(_ stringValue: String) {
        guard let date = Self.dateFormatter.date(from: stringValue) else {
            return nil
        }
        self.init(date)
    }

    /// Date representation.
    public var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(self.value / 1_000_000))
    }

    /// ISO 8601-ish formatted string.
    public var stringValue: String {
        return TimePointSec.dateFormatter.string(from: self.date)
    }

    /// Adds a time interval to this time point.
    mutating func addTimeInterval(_ timeInterval: TimeInterval) {
        self.value += Int64(timeInterval * 1_000_000)
    }

    /// Creates a new time point by adding a time interval.
    func addingTimeInterval(_ timeInterval: TimeInterval) -> TimePoint {
        return TimePoint(self.value + Int64(timeInterval * 1_000_000))
    }
}

/// Type representing a timestap with second accuracy.
public struct TimePointSec: Equatable, Hashable {
    internal static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    /// Seconds sinze 1970.
    public var value: UInt32

    /// Create a new instance from raw value.
    /// - Parameter value: Seconds since 1970.
    public init(_ value: UInt32) {
        self.value = value
    }

    /// Create a new instance from a Date.
    public init(_ date: Date) {
        self.value = UInt32(date.timeIntervalSince1970)
    }

    /// Create a new instance from a TimePoint.
    public init(_ timePoint: TimePoint) {
        self.value = UInt32(timePoint.value / 1_000_000)
    }

    /// Create a new instance from a ISO 8601-ish date.
    /// - Parameter date: Date string, e.g. `2019-01-22T21:42:55`.
    public init?(_ date: String) {
        guard let date = Self.dateFormatter.date(from: date) else {
            return nil
        }
        self.value = UInt32(date.timeIntervalSince1970)
    }

    /// Date representation.
    public var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(self.value))
    }

    /// ISO 8601-ish formatted string.
    public var stringValue: String {
        return Self.dateFormatter.string(from: self.date)
    }

    /// Adds a time interval to this time point.
    mutating func addTimeInterval(_ timeInterval: TimeInterval) {
        self.value += UInt32(timeInterval)
    }

    /// Creates a new time point by adding a time interval.
    func addingTimeInterval(_ timeInterval: TimeInterval) -> TimePointSec {
        return TimePointSec(self.value + UInt32(timeInterval))
    }
}

// MARK: ABI Coding

extension TimePoint: ABICodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let date = try container.decode(String.self)
        guard let instance = Self(date) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unable to decode date"
            )
        }
        self = instance
    }

    public init(fromAbi decoder: ABIDecoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(Int64.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.stringValue)
    }

    public func abiEncode(to encoder: ABIEncoder) throws {
        try encoder.encode(self.value)
    }
}

extension TimePointSec: ABICodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let instance = Self(try container.decode(String.self)) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unable to decode date"
            )
        }
        self = instance
    }

    public init(fromAbi decoder: ABIDecoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(UInt32.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.stringValue)
    }

    public func abiEncode(to encoder: ABIEncoder) throws {
        try encoder.encode(self.value)
    }
}

// MARK: Language extensions

extension TimePoint: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = TimePoint(value) ?? TimePoint(0)
    }
}

extension TimePoint: LosslessStringConvertible {
    public var description: String {
        return self.stringValue
    }
}

extension TimePoint: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int64) {
        self.value = value
    }
}

extension TimePointSec: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = TimePointSec(value) ?? TimePointSec(0)
    }
}

extension TimePointSec: LosslessStringConvertible {
    public var description: String {
        return self.stringValue
    }
}

extension TimePointSec: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt32) {
        self.value = value
    }
}
