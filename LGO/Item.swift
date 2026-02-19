//  Item.swift
//  LGO
//  Created by Fabian on 09.02.26.
//  In dieser Datei wird die class angelegt, welche als Vorlage für die Artikel verwendet wird. Auf die einzelnen Positionen kann man mit Item."variablen name" zugreifen. Zeile 22-32 dienen nur zur Initialisierung

import SwiftData

@Model
final class Item {
    var itemname: String
    var itemnumber: String
    var quantity: Int
    var minQuantityIsOn: Bool
    var minQuantity: Int
    var orderdIsOn: Bool
    var location: String

    init(
        itemname: String = "",
        itemnumber: String = "",
        quantity: Int = 0,
        minQuantityIsOn: Bool = false,
        minQuantity: Int = 0,
        orderdIsOn: Bool = false,
        location: String = ""
    ) {
        self.itemname = itemname
        self.itemnumber = itemnumber
        self.quantity = quantity
        self.minQuantityIsOn = minQuantityIsOn
        self.minQuantity = minQuantity
        self.orderdIsOn = orderdIsOn
        self.location = location
    }
}
