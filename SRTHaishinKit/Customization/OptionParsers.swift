//
//  OptionParsers.swift
//  SRTHaishinKit
//
//  Created by 立宣于 on 2023/11/1.
//

import Foundation

struct OptionsParser {
    static func parse(_ value: Any, for option: SRTSocketOption) -> Data? {
        switch option.type {
        case .string:
            return String(describing: value).data(using: .utf8)
        case .int:
            guard var v: Int32 = NumberOptionParser.shared.toInt32(from: value) else {
                return nil
            }
            return .init(Data(bytes: &v, count: MemoryLayout.size(ofValue: v)))
        case .int64:
            guard var v: Int64 = NumberOptionParser.shared.toInt64(from: value) else {
                return nil
            }
            return .init(Data(bytes: &v, count: MemoryLayout.size(ofValue: v)))
        case .bool:
            var v: Int32 = 0
            if let isTrue = BoolOptionParser.shared.parse(value), isTrue {
                v = 1
            }
            return .init(Data(bytes: &v, count: MemoryLayout.size(ofValue: v)))
        case .enumeration:
            return nil
        }
    }
}

class NumberOptionParser {
    static let shared = NumberOptionParser()
    private let numberParser = NumberFormatter()

    func toInt32(from raw: Any) -> Int32? {
        if let int32: Int32 = toSignedInt(from: raw) {
            return int32
        } else if let text = raw as? String {
            return toNumber(from: text)?.int32Value
        }
        return nil
    }

    func toInt64(from raw: Any) -> Int64? {
        if let int64: Int64 = toSignedInt(from: raw) {
            return int64
        } else if let text = raw as? String {
            return toNumber(from: text)?.int64Value
        }
        return nil
    }

    func toSignedInt<IntType: SignedInteger>(from raw: Any) -> IntType? {
        if let int = raw as? (any SignedInteger) {
            return IntType(int)
        }
        return nil
    }

    func toNumber(from text: String) -> NSNumber? {
        return numberParser.number(from: text)
    }
}

class BoolOptionParser {
    static let shared = BoolOptionParser()
    private let numberParser = NumberOptionParser()

    func parse(_ raw: Any) -> Bool? {
        if let bool = raw as? Bool {
            return bool
        } else if let int: Int = numberParser.toSignedInt(from: raw) {
            switch int {
            case 1:
                return true
            case 0:
                return false
            default:
                return nil
            }
        } else if let text = raw as? String {
            switch text.lowercased() {
            case "true", "t":
                return true
            case "false", "f":
                return false
            default:
                return nil
            }
        }
        return nil
    }
}
