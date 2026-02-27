///  MapView.swift
///  LGO
///  Created by Fabian on 27.02.26.
///  Diese View zeigt die Lagerkarte mit einem Punkt für die Position an

import SwiftUI

struct MapView: View {
    let location: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Das Hintergrundbild
                Image("Map")
                    .resizable()
                    .scaledToFit()
                
                // Der rote Punkt, wenn eine Position angegeben wurde
                if let coordinates = parseCoordinates(from: location) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(radius: 3)
                        .position(
                            x: coordinates.x * geometry.size.width,
                            y: coordinates.y * geometry.size.height
                        )
                }
            }
        }
        .aspectRatio(contentMode: .fit)
    }
    
    /// Wandelt verschiedene Koordinatenformate in normalisierte Werte um (0.0 - 1.0)
    /// Unterstützte Formate:
    /// - "x,y" z.B. "0.5,0.3" für direkte prozentuale Werte
    /// - "A3" für Raster-Koordinaten (A-Z für X, 1-99 für Y)
    private func parseCoordinates(from text: String) -> (x: CGFloat, y: CGFloat)? {
        let trimmed = text.trimmingCharacters(in: .whitespaces).uppercased()
        
        guard !trimmed.isEmpty else { return nil }
        
        // Format: "x,y" mit Dezimalwerten zwischen 0 und 1
        if trimmed.contains(",") {
            let parts = trimmed.split(separator: ",")
            guard parts.count == 2,
                  let x = Double(parts[0]),
                  let y = Double(parts[1]),
                  x >= 0, x <= 1,
                  y >= 0, y <= 1 else {
                return nil
            }
            return (CGFloat(x), CGFloat(y))
        }
        
        // Format: "A3" - Buchstabe (A-Z) + Zahl (1-99)
        var letters = ""
        var numbers = ""
        
        for char in trimmed {
            if char.isLetter {
                letters.append(char)
            } else if char.isNumber {
                numbers.append(char)
            }
        }
        
        guard !letters.isEmpty, !numbers.isEmpty,
              let letter = letters.first,
              let number = Int(numbers) else {
            return nil
        }
        
        // Berechne X-Position aus Buchstabe (A=0, B=1, ..., Z=25)
        // Wir nehmen an, dass es maximal 26 Spalten gibt (A-Z)
        let asciiValue = letter.asciiValue ?? 0
        let columnIndex = Int(asciiValue - Character("A").asciiValue!)
        
        // Berechne Y-Position aus Zahl
        // Wir nehmen an, dass es maximal 20 Reihen gibt (1-20)
        let maxColumns: CGFloat = 26
        let maxRows: CGFloat = 20
        
        guard columnIndex >= 0, columnIndex < Int(maxColumns),
              number >= 1, number <= Int(maxRows) else {
            return nil
        }
        
        // Normalisiere auf 0.0 - 1.0 und zentriere in der Zelle
        let x = (CGFloat(columnIndex) + 0.5) / maxColumns
        let y = (CGFloat(number) - 0.5) / maxRows
        
        return (x, y)
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Position: A3")
        MapView(location: "A3")
            .frame(height: 200)
            .padding()
        
        Text("Position: 0.5,0.5 (Mitte)")
        MapView(location: "0.5,0.5")
            .frame(height: 200)
            .padding()
        
        Text("Keine Position")
        MapView(location: "")
            .frame(height: 200)
            .padding()
    }
}
