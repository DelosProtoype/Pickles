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
    @State private var pythonShellOutput: String = "Python Execution Shell Output"
    @State private var errorMessage: String? = nil
    @State private var isSerializationMode: Bool = false // Toggle state for mode

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pickles - Data Serializer & Deserializer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            // Mode Toggle Section
            HStack {
                Toggle(isOn: $isSerializationMode) {
                    Text(isSerializationMode ? "Serialization Mode" : "Deserialization Mode")
                        .font(.headline)
                        .foregroundColor(isSerializationMode ? .blue : .green)
                }
                .toggleStyle(SwitchToggleStyle(tint: isSerializationMode ? .blue : .green))
                .padding([.leading, .trailing])
            }

            // Input and Output Sections
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Input Data:")
                        .font(.headline)
                    TextEditor(text: $inputData)
                        .border(Color.gray, width: 1)
                        .frame(height: 200)
                        .padding()
                        .onChange(of: inputData) { _ in
                            errorMessage = nil
                        }
                }

                VStack(alignment: .leading) {
                    Text("Output Data (Copyable):")
                        .font(.headline)
                    ScrollView {
                        Text(outputData)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .border(Color.gray, width: 1)
                            .textSelection(.enabled) // Enable copying from output
                    }
                    .frame(height: 200)
                    .padding()
                }
            }
            .padding([.leading, .trailing])

            // Python Shell Output Section
            VStack(alignment: .leading) {
                Text("Python Shell Output (Scrollable):")
                    .font(.headline)
                    .padding(.leading)

                ScrollView {
                    Text(pythonShellOutput)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black) // Black background
                        .foregroundColor(.green)  // Bright green text
                        .font(.system(.body, design: .monospaced)) // Monospaced font
                }
                .frame(height: 150)
                .border(Color.gray, width: 1)
                .padding([.leading, .trailing])
            }

            // Action Buttons
            HStack {
                Button(isSerializationMode ? "Serialize" : "Deserialize") {
                    isSerializationMode ? serializeData() : deserializeData()
                }
                .buttonStyle(.borderedProminent)
                .padding()

                Button("Execute Pickle Code") {
                    executePythonCode()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }

            // Error Message Display
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding([.leading, .trailing, .bottom])
            }
        }
        .frame(width: 850, height: 600) // Fixed window size
        .padding()
    }

    // Serialize Function with Integrity Check
    func serializeData() {
        let objectToSerialize = inputData

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: objectToSerialize, requiringSecureCoding: false)
            // Verify integrity by decoding the object back
            if let decodedObject = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? String, decodedObject == objectToSerialize {
                let base64String = data.base64EncodedString()
                outputData = base64String
                pythonShellOutput = "Serialized Data (Base64):\n\(base64String)"
            } else {
                errorMessage = "Serialization integrity check failed. Data is corrupted."
            }
        } catch {
            errorMessage = "Serialization error: \(error.localizedDescription)"
        }
    }

    // Deserialize Function with Error Handling
    func deserializeData() {
        guard let data = Data(base64Encoded: inputData) else {
            errorMessage = "Invalid input. Please provide valid Base64 data."
            return
        }

        do {
            let deserializedObject = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
            outputData = "\(deserializedObject ?? "Nil output")"
            pythonShellOutput = "Deserialized Data:\n\(outputData)"
        } catch {
            errorMessage = "Deserialization error: \(error.localizedDescription)"
        }
    }

    // Simulated Code Execution Function
    func executePythonCode() {
        guard !inputData.isEmpty else {
            errorMessage = "No input data to execute."
            return
        }

        pythonShellOutput = """
        Python Shell Execution:
        Running code with input...
        \(inputData)
        (Simulated) Execution complete!
        """
    }
}
