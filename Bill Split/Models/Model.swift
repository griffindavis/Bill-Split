//
//  Model.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import Foundation
import Combine

class Model: ObservableObject {
    
    /// Set of bills stored in the app
    @Published var bills: [Bill] = []
    
    /// The people that are allowed to split bills
    @Published var people: [Person] = []
    
    init(bills: [Bill], people: [Person]) {
        self.bills = bills
        self.people = people
    }
    
    init() {
        
        // This is just for testing
        let peopleArray = [
            Person(name: "Griffin"),
            Person(name: "Caroline"),
            Person(name: "Josh")
        ]
        
        self.bills = [
            Bill(name: "Groceries", amount: 100.00, people: [peopleArray[1]]),
            Bill(name: "Electricity", amount: 150.00, people: [peopleArray[0]])]
        self.people = peopleArray
    }
}
