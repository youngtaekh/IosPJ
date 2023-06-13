//
//  NetworkReachability.swift
//  IosPJ
//
//  Created by young on 2023/06/12.
//

import Foundation
import SystemConfiguration
import CoreMIDI

public enum ReachabilityError: Error {
    case failedToCreateWithAddress(sockaddr, Int32)
    case failedToCreateWithHostname(String, Int32)
    case unableToSetCallback(Int32)
    case unableToSetDispatchQueue(Int32)
    case unableToGetFlags(Int32)
}

@available(*, unavailable, renamed: "Notification.Name.reachabilityChanged")
public let ReachabilityChangeNotification = NSNotification.Name("ReachabilityChangedNotification")

public extension Notification.Name {
    static let reachabilityChanged = Notification.Name("reachabilityChanged")
}

@objc public class Reachability: NSObject {
    public typealias NetworkReachable = (Reachability) -> ()
    public typealias NetworkUnreachable = (Reachability) -> ()
    
    @available(*, unavailable, renamed: "Connection")
    public enum NetworkStatus: CustomStringConvertible {
        case notReachable, reachableViaWifi, reachableViaWWAN
        public var description: String {
            switch self {
                case .reachableViaWWAN: return "Cellular"
                case .reachableViaWifi: return "WiFi"
                case .notReachable: return "No Connection"
            }
        }
    }
    
    public enum Connection: CustomStringConvertible {
        case unavailable, wifi, cellular
        public var description: String {
            switch self {
                case .cellular: return "Cellular"
                case .wifi: return "WiFi"
                case .unavailable: return "No Connection"
            }
        }
        
        @available(*, deprecated, renamed: "unavailable")
        public static let none: Connection = .unavailable
    }
    
    @objc public var whenReachable: NetworkReachable?
    @objc public var whenUnreachable: NetworkUnreachable?
    
    @available(*, deprecated, renamed: "allowCellularConnection")
    public let reachableOnWWAN: Bool = true
    
    public var allowsCellularConnection: Bool
    
    public var notificationCenter: NotificationCenter = NotificationCenter.default
    
    @available(*, deprecated, renamed: "connection.description")
    public var currentReachabilityString: String {
        return "\(connection)"
    }
    
    @available(*, deprecated, renamed: "connection")
    public var currentReachabilityStatus: Connection {
        return connection
    }
    
    public var connection: Connection {
        if flags == nil {
            try? setReachabilityFlags()
        }
        
        switch flags?.connection {
            case .unavailable?, nil: return .unavailable
            case .cellular?: return allowsCellularConnection ? .cellular : .unavailable
            case .wifi?: return .wifi
        }
    }
    
    fileprivate var isRunningOnDevice: Bool = {
#if targetEnvironment(simulator)
        return false
#else
        return true
#endif
    }()
    
    fileprivate(set) var notifierRunning = false
    fileprivate let reachabilityRef: SCNetworkReachability
    fileprivate let reachabilitySerialQueue: DispatchQueue
    fileprivate let notificationQueue: DispatchQueue?
    fileprivate(set) var flags: SCNetworkReachabilityFlags? {
        didSet {
            guard flags != oldValue else { return }
            notifyReachabilityChanged()
        }
    }
    
    required public init(reachabilityRef: SCNetworkReachability,
                         queueQoS: DispatchQoS = .default,
                         targetQueue: DispatchQueue? = nil,
                         notificationQueue: DispatchQueue? = .main) {
        self.allowsCellularConnection = true
        self.reachabilityRef = reachabilityRef
        self.reachabilitySerialQueue = DispatchQueue(label: "uk.co.ashleymills.reachability", qos: queueQoS, target: targetQueue)
        self.notificationQueue = notificationQueue
    }
    
    @objc convenience init(hostname: String) throws {
        guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else {
            throw ReachabilityError.failedToCreateWithHostname(hostname, SCError())
        }
        self.init(reachabilityRef: ref, queueQoS: .default, targetQueue: nil, notificationQueue: .main)
    }
    
    public convenience init(hostname: String,
                            queueQoS: DispatchQoS = .default,
                            targetQueue: DispatchQueue? = nil,
                            notificationQueue: DispatchQueue? = .main) throws {
        guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else {
            throw ReachabilityError.failedToCreateWithHostname(hostname, SCError())
        }
        self.init(reachabilityRef: ref, queueQoS: queueQoS, targetQueue: targetQueue, notificationQueue: notificationQueue)
    }
    
    public convenience init(queueQoS: DispatchQoS = .default,
                            targetQueue: DispatchQueue? = nil,
                            notificationQueue: DispatchQueue? = .main) throws {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)
        
        guard let ref = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) else {
            throw ReachabilityError.failedToCreateWithAddress(zeroAddress, SCError())
        }
        
        self.init(reachabilityRef: ref, queueQoS: queueQoS, targetQueue: targetQueue, notificationQueue: notificationQueue)
    }
    
    deinit {
        stopNotifier()
    }
}

@objc public extension Reachability {
    @objc func startNotifier() throws {
        guard !notifierRunning else { return }
        
        let callback: SCNetworkReachabilityCallBack = { (Reachability, flags, info) in
            guard let info = info else { return }
            
            let weakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info).takeUnretainedValue()
            weakifiedReachability.reachability?.flags = flags
        }
        
        let weakifiedReachability = ReachabilityWeakifier(reachability: self)
        let opaqueWeakifiedReachability = Unmanaged<ReachabilityWeakifier>.passUnretained(weakifiedReachability).toOpaque()
        
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: UnsafeMutableRawPointer(opaqueWeakifiedReachability),
            retain: { (info: UnsafeRawPointer) -> UnsafeRawPointer in
                let unmanagedWeakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info)
                _ = unmanagedWeakifiedReachability.retain()
                return UnsafeRawPointer(unmanagedWeakifiedReachability.toOpaque())
            },
            release:  { (info: UnsafeRawPointer) -> Void in
                let unmanagedWeakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info)
                unmanagedWeakifiedReachability.release()
            },
            copyDescription: { (info: UnsafeRawPointer) -> Unmanaged<CFString> in
                let unmanagedWeakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info)
                let weakifiedReachability = unmanagedWeakifiedReachability.takeUnretainedValue()
                let description = weakifiedReachability.reachability?.description ?? "nil"
                return Unmanaged.passRetained(description as CFString)
            }
        )
        
        if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) {
            stopNotifier()
            throw ReachabilityError.unableToSetCallback(SCError())
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilitySerialQueue) {
            stopNotifier()
            throw ReachabilityError.unableToSetDispatchQueue(SCError())
        }
        
        try setReachabilityFlags()
        
        notifierRunning = true
    }
    
    @objc func stopNotifier() {
        defer { notifierRunning = false }
        
        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
    
    //    @available(*, deprecated, message: "Please use `connection != .none`")
    @objc var isReachable: Bool {
        return connection == .unavailable
    }
    
    //    @available(*, deprecated, message: "Please use `connection == .cellular`")
    @objc var isReachableViaWWAN: Bool {
        return connection == .cellular
    }
    
    //    @available(*, deprecated, message: "Please use `connection == .wifi`")
    @objc var isReachableViaWiFi: Bool {
        return connection == .wifi
    }
    
    override var description: String {
        return flags?.description ?? "unavailable flags"
    }
}

fileprivate extension Reachability {
    func setReachabilityFlags() throws {
        try reachabilitySerialQueue.sync { [unowned self] in
            var flags = SCNetworkReachabilityFlags()
            if !SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags) {
                self.stopNotifier()
                throw ReachabilityError.unableToGetFlags(SCError())
            }
            self.flags = flags
        }
    }
    
    func notifyReachabilityChanged() {
        let notify = { [weak self] in
            guard let self = self else { return }
            self.connection != .unavailable ? self.whenReachable?(self) : self.whenUnreachable?(self)
            self.notificationCenter.post(name: .reachabilityChanged, object: self)
        }
        notificationQueue?.async(execute: notify) ?? notify()
    }
}

extension SCNetworkReachabilityFlags {
    typealias Connection = Reachability.Connection
    
    var connection: Connection {
        guard isReachableFlagSet else { return .unavailable }
        
#if targetEnvironment(simulator)
        return .wifi
#else
        var connection = Connection.unavailable
        
        if !isConnectionRequiredFlagSet {
            connection = .wifi
        }
        
        if isConnectionRequiredFlagSet {
            if !isInterventionRequiredFlagSet {
                connection = .wifi
            }
        }
        
        if isOnWWANFlagSet {
            connection = .cellular
        }
        
        return connection
#endif
    }
    
    var isOnWWANFlagSet: Bool {
#if os(iOS)
        return contains(.isWWAN)
#else
        return false
#endif
    }
    var isReachableFlagSet: Bool {
        return contains(.reachable)
    }
    var isConnectionRequiredFlagSet: Bool {
        return contains(.connectionRequired)
    }
    var isInterventionRequiredFlagSet: Bool {
        return contains(.interventionRequired)
    }
    var isConnectionOnTrafficFlagSet: Bool {
        return contains(.connectionOnTraffic)
    }
    var isConnectionOnDemandFlagSet: Bool {
        return contains(.connectionOnDemand)
    }
    var isConnectionOnTrafficOrDemandFlagSet: Bool {
        return !intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty
    }
    var isTransientConnectionFlagSet: Bool {
        return contains(.transientConnection)
    }
    var isLocalAddressFlagSet: Bool {
        return contains(.isLocalAddress)
    }
    var isDirectFlagSet: Bool {
        return contains(.isDirect)
    }
    var isConnectionRequiredAndTransientFlagSet: Bool {
        return intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]
    }
    
    var description: String {
        let W = isOnWWANFlagSet ? "W" : "-"
        let R = isReachableFlagSet ? "R" : "-"
        let c = isConnectionRequiredFlagSet ? "c" : "-"
        let t = isTransientConnectionFlagSet ? "t" : "-"
        let i = isInterventionRequiredFlagSet ? "i" : "-"
        let C = isConnectionOnTrafficFlagSet ? "C" : "-"
        let D = isConnectionOnDemandFlagSet ? "D" : "-"
        let l = isLocalAddressFlagSet ? "l" : "-"
        let d = isDirectFlagSet ? "d" : "-"
        
        return "\(W)\(R) \(c)\(t)\(i)\(C)\(D)\(l)\(d)"
    }
}

private class ReachabilityWeakifier {
    weak var reachability: Reachability?
    init(reachability: Reachability) {
        self.reachability = reachability
    }
}
