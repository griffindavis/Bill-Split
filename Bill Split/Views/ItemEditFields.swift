//
//  ItemEditFields.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import SwiftUI

struct ItemEditFields: View {
    @ObservedObject var item: BillItem

    @FocusState.Binding var focus: FocusFields?

    var body: some View {
        TextField("New Item", text: $item.name)
            .focused($focus, equals: .name)
        TextField(
            "",
            value: $item.price,
            format: .number.precision(.fractionLength(2))
        )
            .keyboardType(.decimalPad)
            .focused($focus, equals: .price)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Next") {
                        focus = .price
                    }
                    Spacer()
                    Button("Done") {
                        focus = nil
                    }
                }
            }
    }
}

struct ItemEditFields_Previews: PreviewProvider {
    // Use a local FocusState in the preview
    @FocusState static var focus: FocusFields?

    static var previews: some View {
        ItemEditFields(
            item: BillItem(
                name: "French Onion Soup",
                price: 12.45,
                splitWith: []
            ),
            focus: $focus
        )
        .padding()
    }
}
