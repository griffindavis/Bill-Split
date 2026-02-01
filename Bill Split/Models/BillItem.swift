//
//  BillItem.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import Foundation
import Combine

class BillItem: Identifiable, Hashable, ObservableObject {
    
    /// Identifier
    var id: UUID = UUID()
    
    /// Base published details
    @Published var name: String
    @Published var price: Double
    @Published var splitWith: Set<Person>
    
    
    /// Amount this will cost per person, dependent on how many people split it
    var amountPerPerson: Double {
        if splitWith.count == 0 {
            return price
        }
        return price / Double(splitWith.count)
    }
    
    /// Helper to determine if the item is valid to save
    var valid: Bool {
        name != "" && price != 0
    }
    
    init(id: UUID = UUID(), name: String, price: Double, splitWith: Set<Person>) {
        self.id = id
        self.name = name
        self.price = price
        self.splitWith = splitWith
    }
    
    
    /// Copy this object to a new one
    /// - Returns: A new representation of the object
    func copy() -> BillItem {
        return BillItem(
            id: UUID(),
            name: name,
            price: price,
            splitWith: splitWith
        )
    }
    
    // MARK: - Hashable
    static func == (lhs: BillItem, rhs: BillItem) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
