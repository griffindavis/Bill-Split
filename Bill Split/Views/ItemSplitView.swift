//
//  ItemSplitView.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import SwiftUI

struct ItemSplitView: View {
    @ObservedObject var item: BillItem
    var people: Set<Person>
    
    @State private var editMode: EditMode = .active
    
    @FocusState private var focus: FocusFields?

    var body: some View {
        List(selection: $item.splitWith) {
            Section("Item Details") {
                ItemEditFields(item: item, focus: $focus)
            }
            Section("Split With") {
                ForEach(Array(people), id: \.self) { person in
                    Text(person.name)
                }
            }
        }
        .environment(\.editMode, $editMode)
    }
}

#Preview {
    ItemSplitView(
        item: BillItem(name: "Test", price: 10.00, splitWith: Set<Person>()),
        people: [Person(name: "Griffin"), Person(name: "Sam")]
    )
}
