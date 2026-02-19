//  Item.swift
//  LGO
//  Created by Fabian on 09.02.26.
//  In dieser Datei wird die class angelegt, welche als Vorlage für die Artikel verwendet wird. Auf die einzelnen Positionen kann man mit Item."variablen name" zugreifen. Zeile 22-32 dienen nur zur Initialisierung

import Foundation
import SwiftData

@Model
class Item {
    
    var itemname:        String = ""      // Variable für die Artikelbezeichnung
    var itemnumber:      String = ""      // Variable für die Artikelnummer
    var quantity:        String = ""      // Variable für die Anzahl
    var minQuantityIsOn: Bool   = false   // Variable für den Schaltzustand vom Toggle Meldebestand
    var minQuantity:     String = ""      // Variable für den Meldebestand
    var orderdIsOn:      Bool   = false   // Variable für den Schaltzustand vom Toggle Bestellt
    var location:        String = ""      // Variable für den Lagerort
    var edit:            Bool   = false   // Variable für die Action bearbeiten
    var delete:          Bool   = false   // Variable für die Ation löschen
    
    init(itemname: String = "", itemnumber: String = "", quantity: String = "", minQuantityIsOn: Bool = false, minQuantity: String = "", orderdIsOn: Bool = false, location: String = "", edit: Bool = false, delete: Bool = false) {
        self.itemname = itemname
        self.itemnumber = itemnumber
        self.quantity = quantity
        self.minQuantityIsOn = minQuantityIsOn
        self.minQuantity = minQuantity
        self.orderdIsOn = orderdIsOn
        self.location = location
        self.edit = edit
        self.delete = delete
    }
}

