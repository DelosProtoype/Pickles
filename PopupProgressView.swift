//
//  PopupProgressView.swift
//  Pickles
//
//  Created by Kevin ONeil on 10/30/24.
//


import SwiftUI

struct PopupProgressView: View {
    @Binding var progressValue: Double
    @Binding var taskDescription: String
    @Binding var isProcessing: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text(taskDescription)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)

            ProgressView(value: progressValue, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()
                .frame(maxWidth: .infinity)

            Button("Cancel") {
                isProcessing = false  // Allow the user to cancel the operation
            }
            .buttonStyle(.bordered)
            .foregroundColor(.white)
            .padding(.bottom)

        }
        .padding()
        .background(Color.black.opacity(0.9))  // Match the dark theme with transparency
        .cornerRadius(12)
        .shadow(radius: 10)
        .frame(maxWidth: 400, maxHeight: 200)
    }
}
