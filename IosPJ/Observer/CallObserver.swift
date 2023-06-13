//
//  CallObserver.swift
//  IosPJ
//
//  Created by young on 2023/06/09.
//

import Foundation

protocol CallObserver {
    func onOutgoingCall(model: CallModel)
    func onConnected(model: CallModel)
    func onTerminated(model: CallModel)
}
