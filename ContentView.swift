//
//  ContentView.swift
//  Pickles
//
//  Created by Kevin ONeil on 10/24/24.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var inputData: String = ""
    @State private var outputData: String = ""
    @State private var errorMessage: String? = nil
    @State private var isSerializationMode: Bool = false // Toggle mode state
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pickles - Data Serializer & Deserializer")
                .font(.largeTitle)
                .padding()
            
            // Mode Toggle Button
            HStack {
                Toggle(isOn: $isSerializationMode) {
                    Text(isSerializationMode ? "Serialization Mode" : "Deserialization Mode")
                        .font(.headline)
                        .foregroundColor(isSerializationMode ? .blue : .green)
                }
                .padding()
                .toggleStyle(SwitchToggleStyle(tint: isSerializationMode ? .blue : .green))
            }
            
            // Text Editors for Input and Output
            HStack {
                TextEditor(text: $inputData)
                    .border(Color.gray, width: 1)
                    .frame(height: 200)
                    .padding()
                    .onChange(of: inputData) { _ in
                        errorMessage = nil
                    }
                
                TextEditor(text: $outputData)
                    .border(Color.gray, width: 1)
                    .frame(height: 200)
                    .padding()
                    .disabled(true) // Output is read-only
            }
            
            // Action Buttons
            HStack {
                Button(isSerializationMode ? "Serialize" : "Deserialize") {
                    isSerializationMode ? serializeData() : deserializeData()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                if !isSerializationMode {
                    Button("Execute Code") {
                        executeDeserializedCode()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            
            // Error Message Display
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
    
    // Deserialization Function
    func deserializeData() {
        guard let data = inputData.data(using: .utf8) else {
            errorMessage = "Failed to convert input to data."
            return
        }
        
        do {
            let deserializedObject = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
            outputData = "\(deserializedObject ?? "Nil output")"
        } catch {
            errorMessage = "Deserialization error: \(error.localizedDescription)"
        }
    }
    
    // Serialization Function
    func serializeData() {
        let objectToSerialize = inputData
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: objectToSerialize, requiringSecureCoding: false)
            outputData = data.base64EncodedString()
        } catch {
            errorMessage = "Serialization error: \(error.localizedDescription)"
        }
    }
    
    // Simulated Code Execution Function
    func executeDeserializedCode() {
        do {
            let task = try NSRegularExpression(pattern: #"[a-zA-Z0-9]+\(\)"#, options: [])
            let matches = task.matches(in: inputData, range: NSRange(location: 0, length: inputData.count))
            
            if matches.isEmpty {
                errorMessage = "No executable code found in the input."
                return
            }
            
            // Simulating code execution
            outputData = "Executing code is simulated here. Be cautious with real code."
        } catch {
            errorMessage = "Execution error: \(error.localizedDescription)"
        }
    }
}
