//
//  ExtractedTextView.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import PhotosUI
import SwiftUI
import Vision

struct ExtractedTextView: View {
    @ObservedObject var bill: Bill

    var body: some View {
        ScrollView {
            if let image = bill.imageData {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("Can't find image :(")
            }
            Divider()
            ForEach(bill.mergedLines, id: \.self.text) { line in
                HStack{
                    Text(line.text)
                    Spacer()
                    Text("\(line.verticalPlacement)")
                }
            }
            Divider()
            Text(bill.AIResponse)
        }
        .padding(.horizontal)
    }
}

#Preview {
    ExtractedTextView(
        bill: Bill(name: "Test", amount: 1.0, people: Set<Person>())
    )
}
