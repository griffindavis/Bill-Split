//
//  PeopleMultiSelect.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import SwiftUI

struct PeopleMultiSelect: View {
    @State var newPerson: Person = Person(name: "")
    @Binding var selected: Set<Person>
    
    @State private var editMode: EditMode = .active
    
    @EnvironmentObject var model: Model
    var body: some View {
        List(selection: $selected) {
            Section(header: HStack {
                Text("New Person")
                Spacer()
                Button("Add") {
                    model.people.append(newPerson)
                    newPerson = Person(name: "")
                }
            }) {
                TextField("Enter Name", text: $newPerson.name)
            }
            Section("People") {
                ForEach(model.people, id: \.self) { person in
                    Text(person.name)
                }
            }
        }
        .environment(\.editMode, $editMode)
    }
}

#Preview {
    PeopleMultiSelect(selected: .constant(Set<Person>()))
        .environmentObject(Model())
}
