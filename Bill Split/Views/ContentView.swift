//
//  ContentView.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import SwiftUI

struct ContentView: View {
    @State var showAddBill: Bool = false
    
    @EnvironmentObject var model: Model
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(model.bills, id: \.self) { bill in
                    NavigationLink(destination: EditBillView(bill: bill)) {
                        Text(bill.name)
                    }
                }
            }
            .navigationTitle("Bills")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showAddBill = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBill) {
                AddBillView(isPresented: $showAddBill)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(Model())
}
