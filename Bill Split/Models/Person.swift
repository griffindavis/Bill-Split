//
//  Person.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import Foundation
import Combine

class Person: Identifiable, Hashable, ObservableObject {
    var id: UUID = UUID()
    @Published var name: String
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
    
    // Hashable
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
