//
//  ResultsView.swift
//  BloodTestLab
//
//  Created by sarmad on 12/19/24.
//

import Foundation
import SwiftUI

struct ResultsView: View {
    @ObservedObject var dbHelper: SQLiteHelper
    var userId: Int
    @State private var results: [(testType: String, result: String)] = []

    var body: some View {
        VStack {
            Text("Your Test Results")
                .font(.largeTitle)
                .padding()

            if results.isEmpty {
                Text("No results found.")
                    .padding()
            } else {
                List(results, id: \.testType) { result in
                    VStack(alignment: .leading) {
                        Text("Test Type: \(result.testType)")
                            .font(.headline)
                        Text("Result: \(result.result)")
                    }
                }
            }

            Spacer()
        }
        .onAppear {
            self.results = dbHelper.getResults(userId: userId)
        }
    }
}

