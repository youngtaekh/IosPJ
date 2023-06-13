//
//  RegistrationModel.swift
//  IosPJ
//
//  Created by young on 2023/06/09.
//

import Foundation

class RegistrationModel {
    var userId: String?
    var registered = false
    
    init(userId: String? = nil) {
        self.userId = userId
    }
}
