//
//  EditBillView.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import SwiftUI

enum DefaultPercent: String, CaseIterable, Identifiable {
    case p18 = "18%"
    case p20 = "20%"
    case p22 = "22%"
    case custom = "Custom"

    var id: String { rawValue }

    var percentage: Double? {
        switch self {
        case .p18: return 0.18
        case .p20: return 0.20
        case .p22: return 0.22
        case .custom: return nil
        }
    }
}

struct EditBillView: View {
    
    /// The bill that the user is editing
    @ObservedObject var bill: Bill
    
    
    /// The app level data such as other bills and the people to add to bills
    @EnvironmentObject var model: Model
    
    /// Object to modify for creating new items
    @StateObject private var newItem = BillItem(
        name: "",
        price: 0.0,
        splitWith: Set<Person>()
    )

    /// The percent tip to calculate
    @State private var percentTip: DefaultPercent = .custom

    /// Handles jumping focus between edit fields
    @FocusState private var focus: FocusFields?

    /// For showing and hiding the taxes, tips, and fees
    @State private var showExtras: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section(
                    header: HStack {
                        Text("Details")
                        Spacer()
                        NavigationLink(
                            destination: ExtractedTextView(bill: bill)
                        ) {
                            Text("Extracted Info")
                        }
                        .disabled(bill.AIResponse == "")
                    }
                ) {
                    HStack {
                        Label("", systemImage: "pencil.and.scribble")
                        Spacer()
                        TextField("Bill Name", text: $bill.name)
                    }
                    HStack {
                        Label("Total:", systemImage: "dollarsign")
                        TextField(
                            "",
                            value: $bill.amount,
                            format: .number.precision(.fractionLength(2))
                        )
                        .keyboardType(.decimalPad)
                        Spacer()
                        Text(
                            bill.discrepancy.formatted(
                                .currency(code: "USD")
                            )
                        )
                        .padding(.horizontal)
                        .background(bill.discrepancy == 0 ? .green : .red)
                        .clipShape(Capsule())
                    }
                }
                Section {
                    DisclosureGroup(isExpanded: $showExtras) {
                        HStack {
                            Label("Tax:", systemImage: "percent")
                            TextField(
                                "",
                                value: $bill.tax,
                                format: .number.precision(.fractionLength(2))
                            )
                            .keyboardType(.decimalPad)
                        }
                        HStack {
                            Label("Fee:", systemImage: "doc.text")
                            TextField(
                                "",
                                value: $bill.fees,
                                format: .number.precision(.fractionLength(2))
                            )
                            .keyboardType(.decimalPad)
                        }
                        HStack {
                            Label("Tip:", systemImage: "hand.thumbsup")
                            TextField(
                                "",
                                value: $bill.tip,
                                format: .number.precision(.fractionLength(2))
                            )
                            .keyboardType(.decimalPad)
                        }
                        HStack {
                            Picker("", selection: $percentTip) {
                                ForEach(DefaultPercent.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .onChange(of: percentTip) { _, newValue in
                            if let percentage = newValue.percentage {
                                bill.tip = bill.itemTotal * percentage
                            }
                        }
                    } label: {
                        HStack {
                            Label("Extras", systemImage: "doc.text")
                            Spacer()
                            Text(bill.feeTotal.formatted(.currency(code: "USD")))
                        }
                    }
                }
                Section(
                    header: HStack {
                        Text("People")
                        Spacer()
                        NavigationLink(
                            destination: PeopleMultiSelect(
                                selected: $bill.people
                            )
                        ) {
                            Text("Add / Edit")
                        }
                    }
                ) {
                    if bill.people.count == 0 {
                        Label(
                            "Tap 'Add/Edit' to add people to the bill",
                            systemImage: "lightbulb.max"
                        )
                    }
                    ForEach(Array(bill.people), id: \.id) { person in
                        HStack {
                            Text(person.name)
                            Spacer()
                            Text(
                                bill.amountFor(person)
                                    .formatted(.currency(code: "USD"))
                            )
                        }
                    }
                }
                Section(
                    header: HStack {
                        Text("Add Item")
                        Spacer()
                        Button("Add") {
                            withAnimation {
                                bill.items.insert(newItem.copy(), at: 0)
                            }
                            newItem.name = ""
                            newItem.price = 0
                            focus = nil
                        }
                        .disabled(!newItem.valid)
                    }
                ) {
                    ItemEditFields(item: newItem, focus: $focus)
                }
                if !bill.items.isEmpty {
                    Section(
                        header:
                            HStack {
                                Text("Items")
                                Spacer()
                                Button("Sync Total") {
                                    bill.amount = bill.items.reduce(0) {
                                        $0 + $1.price
                                    }
                                }
                                .disabled(bill.discrepancy == 0)
                            }
                    ) {
                        ForEach(bill.items, id: \.self) { item in
                            NavigationLink(
                                destination: ItemSplitView(
                                    item: item,
                                    people: bill.people
                                )
                            ) {
                                HStack {
                                    if item.splitWith.count == 0 {
                                        Label {
                                            Text(item.name)
                                        } icon: {
                                            Image(systemName: "person.crop.circle.badge.plus")
                                                .foregroundStyle(.red)  // only affects the image
                                        }
                                    } else {
                                        Label(item.name, systemImage: "checkmark")
                                    }
                                    Spacer()
                                    Text(
                                        item.price.formatted(.currency(code: "USD"))
                                    )
                                }
                            }
                        }
                        .onDelete(perform: bill.deleteItems)
                    }
                }
            }
            .onAppear {
                newItem.name = ""
                newItem.price = 0
            }
        }
    }
}

#Preview {
    EditBillView(
        bill: Bill(
            name: "Test",
            amount: 100.00,
            items: [
                BillItem(
                    name: "Test 1",
                    price: 100.00,
                    splitWith: Set<Person>()
                ),
                BillItem(
                    name: "Test 2",
                    price: 50.00,
                    splitWith: Set<Person>()
                ),
            ],
            people: []
        )
    )
    .environmentObject(Model())
}
