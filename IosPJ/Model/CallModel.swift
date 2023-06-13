//
//  CallModel.swift
//  IosPJ
//
//  Created by young on 2023/06/09.
//

import Foundation

class CallModel: NSObject {
    var counterpart: String?
    var outgoing = false
    var incoming = false
    var connected = false
    var terminated = false
    var mute = false
    var speaker = false
    
    init(counterpart: String? = nil, outgoing: Bool = false, incoming: Bool = false) {
        self.counterpart = counterpart
        self.outgoing = outgoing
        self.incoming = incoming
    }
}
