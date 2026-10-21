//
//  Item.swift
//  Selaras
//
//  Created by Hana Azizah Nurhadi on 21/10/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
