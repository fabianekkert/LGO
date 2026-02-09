//
//  Item.swift
//  LGO
//
//  Created by Fabian on 09.02.26.
//

import SwiftData
import Foundation

@Model
final class Item {
    var timestamp: Date
    var name: String?
    var number: String?
    var quantity: Int?
    var minQuantity: Double?
    var location: String?

    init(timestamp: Date,
         name: String? = nil,
         number: String? = nil,
         quantity: Int? = 0,
         minQuantity: Double? = nil,
         location: String? = nil) {
        self.timestamp = timestamp
        self.name = name
        self.number = number
        self.quantity = quantity
        self.minQuantity = minQuantity
        self.location = location
    }
}
