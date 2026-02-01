//
//  Bill.swift
//  Bill Split
//
//  Created by Griffin Davis on 11/21/25.
//

import Combine
import Foundation
import FoundationModels
import PhotosUI
import SwiftUI
import Vision

class Bill: Identifiable, Hashable, ObservableObject {
    
    // Keep an ID for the bill
    var id: UUID = UUID()
    
    // Bill specific details
    @Published var name: String
    @Published var amount: Double
    @Published var items: [BillItem] = [] {
        didSet { setupItems() }
    }
    @Published var tax: Double
    @Published var tip: Double
    @Published var fees: Double
    @Published var people: Set<Person>

    // Image and AI parsing data
    @Published var imageData: UIImage?
    @Published var extractedText: String = ""
    @Published var AIResponse: String = ""
    @Published var sortedLines: [OCRLine] = []
    @Published var mergedLines: [OCRLine] = []

    
    /// Track the total of the overall bill
    var total: Double {
        itemTotal + feeTotal
    }
    
    /// Separate value for total fees
    var feeTotal: Double {
        tax + tip + fees
    }

    /// Keep a separate value for the item totals, this will be used to calculate percentage of fees
    var itemTotal: Double {
        items.reduce(0) { $0 + $1.price }
    }
    
    /// Keep track of if there's a difference between the total amount and what is documented in items
    var discrepancy: Double {
        total - amount
    }
    
    /// Helper to determine how much each person owes
    /// - Parameter person: The person to calculate for
    /// - Returns: The total amount they owe
    func amountFor(_ person: Person) -> Double {
        var personItemTotal: Double = 0.0
        for item in items {
            if item.splitWith.contains(person) {
                personItemTotal += item.amountPerPerson
            }
        }
        
        return personItemTotal + (feeTotal * (personItemTotal / itemTotal))
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        amount: Double = 0,
        items: [BillItem] = [],
        tax: Double = 0,
        tip: Double = 0,
        fees: Double = 0,
        people: Set<Person>,
        extractedText: String = "",
        AIResponse: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.items = items
        self.tax = tax
        self.tip = tip
        self.fees = fees
        self.people = people
        self.extractedText = extractedText
        self.AIResponse = AIResponse
    }

    /// Copy this object to a new one
    /// - Returns: A new representation of the object
    func copy() -> Bill {
        let newItems = items.map { $0.copy() }
        let bill = Bill(
            name: name,
            amount: amount,
            items: newItems,
            tax: tax,
            tip: tip,
            fees: fees,
            people: Set<Person>(people),
            extractedText: extractedText,
            AIResponse: AIResponse
        )
        bill.imageData = imageData
        return bill
    }
    
    /// Helper to delete an item from the bill
    /// - Parameter offsets: The offset of the item in the list
    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    /// Helper struct for each OCR line
    struct OCRLine: Encodable {
        let text: String
        let verticalPlacement: Int
        let horizontalPlacement: Int
    }

    /// Merge adjacent OCR lines when their vertical placement (x-left) is within a threshold.
    /// Assumes `sortedLines` is sorted by `verticalPlacement` descending (right-most first).
    /// - Parameter threshold: Maximum absolute difference in `verticalPlacement` to consider lines on the same column group.
    /// - Returns: Merged lines where texts are concatenated in reading order.
    private func mergeSortedLinesByVerticalPlacement(threshold: Int = 8) -> [OCRLine] {
        guard !sortedLines.isEmpty else { return [] }
        
        print("Threshold: \(threshold)")

        var result: [OCRLine] = []
        var current = sortedLines[0]

        for idx in 1..<sortedLines.count {
            let next = sortedLines[idx]
            let delta = abs(current.verticalPlacement - next.verticalPlacement)

            if delta <= threshold {
                // Merge texts; keep the earlier horizontal placement (top-most) for ordering
                let mergedText = current.text + " " + next.text
                let mergedVertical = (current.verticalPlacement + next.verticalPlacement) / 2
                let mergedHorizontal = min(current.horizontalPlacement, next.horizontalPlacement)
                current = OCRLine(text: mergedText, verticalPlacement: mergedVertical, horizontalPlacement: mergedHorizontal)
            } else {
                result.append(current)
                current = next
            }
        }
        result.append(current)
        return result
    }
    
    /// Function to pull the text out of the image
    /// - Parameter image: The image to pull text from
    func recognizeText(image: UIImage) async {
        guard let cgImage = image.cgImage else { return }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage)

            let request = VNRecognizeTextRequest { [weak self] request, error in
                defer { continuation.resume() }

                guard error == nil,
                    let observations = request.results as? [VNRecognizedTextObservation],
                    let self = self
                else {
                    return
                }

                let width = CGFloat(cgImage.width)
                let height = CGFloat(cgImage.height)

                var lines: [OCRLine] = []
                
                // Convert each observation to an OCRLine
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    
                    // normalized in Vision space (origin at bottom-left)
                    let boundingBox = observation.boundingBox

                    // Convert to pixel coordinates with origin at top-left (image space)
                    let xLeft = Int((boundingBox.minX * width).rounded())
                    let yTop = Int(((boundingBox.minY) * height).rounded())

                    lines.append(
                        OCRLine(
                            text: candidate.string,
                            verticalPlacement: xLeft,
                            horizontalPlacement: yTop,
                        )
                    )
                }
                
                lines.sort { $0.verticalPlacement > $1.verticalPlacement }
                
                self.sortedLines = lines
                self.mergedLines = self.mergeSortedLinesByVerticalPlacement(threshold: (Int(height * 0.02)))
                
                for line in mergedLines {
                    extractedText.append(line.text + "|")
                }
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error.localizedDescription)")
                continuation.resume()
            }
        }
    }
    
    /// Takes the extracted text and hands it off to AI to build out the JSON object representing the bill
    func processText() async {

        let instructions = """
            You are a receipt parser. You will be given all of the text extracted from the receipt in a | delimited list of items.

            Evaluate each piece of text to determine the item and the cost. 
            Not all pieces of text provided will be relevant, ignore headers and footers and other things that would not be relevant for parsing a receipt for the use case of splitting it with friends.

            Your task is to extract:
            - The name of the bill (usually the vendor or a short description)
            - The total amount
            - A list of items with their names and prices
            - Tax, Tip, and other Fees as separate values (not as items)

            Normalization:
            - Normalize numbers by removing currency symbols and commas.
            - If a value is missing or cannot be determined, set it to 0.

            Output Requirements:
            1. Only output valid JSON, with no extra text, comments, or Markdown formatting.
            2. All keys and string values must use double quotes.
            3. Prices and amounts must be numbers (no currency symbols).
            4. Do not include any of the coordinate data in your output.
            5. The total of all items plus tax, tip, and fees should equal the amount of the bill.
            6. Tax, Tip, and Fees must be in their own fields, not represented as items.
            7. The JSON must match this structure exactly:

            {
              "bill": {
                "name": "string",
                "amount": number,
                "items": [
                  { "name": "string", "price": number }
                ],
                "tax": number,
                "tip": number,
                "fees": number
              }
            }

            8. Do not make up any items that are not specifically included in the input.
            """

        let prompt = extractedText

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            self.AIResponse = response.content

            let formattedContent = response.content.replacingOccurrences(
                of: "```json",
                with: ""
            ).replacingOccurrences(of: "```", with: "")

            if let jsonData = formattedContent.data(using: .utf8) {
                let parseableResponse = try JSONDecoder().decode(
                    BillResponse.self,
                    from: jsonData
                )

                let bill = parseableResponse.bill
                self.name = bill.name
                self.amount = bill.amount
                self.items = bill.items.map {
                    BillItem(name: $0.name, price: $0.price, splitWith: [])
                }
                self.tax = bill.tax
                self.tip = bill.tip
                self.fees = bill.fees
            }
        } catch {
            print("Error! \(error.localizedDescription)")
            print(AIResponse)
        }
    }

    
    /// Response object for the bill from AI
    struct BillResponse: Decodable {
        let bill: BillData
    }
    
    /// Helper struct for the data coming back from AI
    struct BillData: Decodable {
        let name: String
        let amount: Double
        let items: [BillItemData]
        let tax: Double
        let tip: Double
        let fees: Double
    }
    
    /// Helper struct for each item coming back from AI
    struct BillItemData: Decodable {
        let name: String
        let price: Double
    }

    // MARK: - Handle changes from items to update the UI for rendering amount owed per person

    /// Store Combine subscriptions so they are retained for the lifetime of the object.
    private var cancellables = Set<AnyCancellable>()

    /// This function sets up the subscriptions for all BillItems in the items array.
    private func setupItems() {
        cancellables.removeAll()
        for item in items {
            item.objectWillChange
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellables)
        }
    }
    // MARK: - Handle Hashable conformance
    static func == (lhs: Bill, rhs: Bill) -> Bool {
        return lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

