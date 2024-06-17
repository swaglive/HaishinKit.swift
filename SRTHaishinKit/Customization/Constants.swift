import Logboard
import libsrt

let logger = LBLogger.with("com.haishinkit.SRTHaishinKit")

public struct SRTNotificationNames {
    public static let connectionStatusNotification = Notification.Name(rawValue: "com.haishinkit.SRTHaishinKit.SRTConnectionStatusNotification")

    public static let streamStatusNotification = Notification.Name(rawValue: "com.haishinkit.SRTHaishinKit.SRTStreamStatusNotification")
}

public struct SRTNotificationProperties {
    public static let status = "status"
}

public extension SRTConnection {
    enum SocketStatus: UInt32 {
        case initialized, opened, listening, connecting, connected, broken, closing, closed, nonexist

        public init?(srtStatus: SRT_SOCKSTATUS) {
            switch srtStatus {
            case SRTS_INIT: self = .initialized
            case SRTS_OPENED: self = .opened
            case SRTS_BROKEN: self = .broken
            case SRTS_CONNECTING: self = .connecting
            case SRTS_CONNECTED: self = .connected
            case SRTS_CLOSING: self = .closing
            case SRTS_CLOSED: self = .closed
            case SRTS_NONEXIST: self = .nonexist
            case SRTS_LISTENING: self = .listening
            default:
                return nil
            }
        }
    }
}
