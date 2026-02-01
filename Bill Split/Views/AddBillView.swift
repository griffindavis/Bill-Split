//
//  AddBillView.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import PhotosUI
import SwiftUI
import Vision

struct AddBillView: View {
    @Binding var isPresented: Bool
    @State var newBill = Bill(people: Set<Person>())
    @EnvironmentObject var model: Model

    @State private var receiptImage: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                EditBillView(bill: newBill)
                VStack {
                    Spacer()
                    PhotosPicker(selection: $receiptImage, matching: .images) {
                        Label("Start with an image", systemImage: "photo")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isPresented = false
                        model.bills.insert(newBill.copy(), at: 0)
                        newBill = Bill(people: Set<Person>())
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onChange(of: receiptImage) { oldItem, newItem in
            Task {
                guard let item = newItem else { return } // unwrap the optional
                guard let imageData = try? await item.loadTransferable(
                        type: Data.self
                    ) else { return }
                guard let uiImage = UIImage(data: imageData) else { return }
                newBill.imageData = uiImage
                await newBill.recognizeText(image: uiImage)
                await newBill.processText()
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddBillView(isPresented: .constant(true))
            .environmentObject(Model())
    }
}
