//
//  Buddy.swift
//  IosPJ
//
//  Created by young on 2023/06/12.
//

import Foundation

class Buddy {
    func setBuddy(to: String) {
        PJManager().setBuddy(to, isSub: false);
    }
    func delBuddy(to: String) {
        PJManager().deleteBuddy(to);
    }
    func sendMessage(to: String) {
        PJManager().sendInstanceMessage(to, msg: "test message")
    }
}
