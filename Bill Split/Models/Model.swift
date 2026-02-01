//
//  Model.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import Foundation
import Combine

class Model: ObservableObject {
    @Published var bills: [Bill] = []
    @Published var people: [Person] = []
    
    init(bills: [Bill], people: [Person]) {
        self.bills = bills
        self.people = people
    }
    
    init() {
        
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
