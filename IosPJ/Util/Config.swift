//
//  Config.swift
//  IosPJ
//
//  Created by young on 2023/06/12.
//

import Foundation

class Config {
    static let ADDRESS = "sip.linphone.org"
    static let PORT = "5061"
    static let ID = "everareen"
    static let PASSWORD = "lidue638"
    static let COUNTERPART = "youngtaek.people"
    
//    static let ADDRESS = "hongcafew-pbx.peoplev.net"
//    static let PORT = "5479"
//    static let ID = "1000005"
//    static let COUNTERPART = "1000004"
//    static let PASSWORD = "1234"
    
    static let TRANSPORT = "TLS"
    
    static let OUTGOING = 0
    static let INCOMING = 1
    static let CONNECTED = 2
    static let TERMINATED = 3
    
    static let INIT = "INIT"
    static let NONE = "NONE"
    static let MOBILE = "MOBILE"
    static let WIFI = "WIFI"
}
