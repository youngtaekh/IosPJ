//
//  CallModel.swift
//  IosPJ
//
//  Created by young on 2023/06/09.
//

import Foundation

class CallModel: NSObject {
    var callId: Int = 0
    var counterpart: String
    var uuid: UUID
    var outgoing = false
    var incoming = false
    var connected = false
    var terminated = false
    var endClick = false
    var busy = false
    var mute = false
    var speaker = false
    
    init(counterpart: String, uuid: UUID, outgoing: Bool = false, incoming: Bool = false) {
        self.counterpart = counterpart
        self.uuid = uuid
        self.outgoing = outgoing
        self.incoming = incoming
    }
}
