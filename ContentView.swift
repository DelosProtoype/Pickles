import SwiftUI

struct ContentView: View {
    @State private var inputData: String = ""
    @State private var outputData: String = ""
    @State private var pythonShellOutput: String = "Python Execution Shell Output"
    @State private var selectedEncoding: String = "utf-8"
    @State private var selectedModule: String = "pickle"
    @State private var isSerializationMode: Bool = false
    @State private var errorMessage: String? = nil

    let encodingOptions = ["utf-8", "ascii", "latin-1", "unicode_escape"]
    let moduleOptions = ["pickle", "pickle5"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pickles - Data Serializer & Deserializer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            // Toggle to switch between serialization and deserialization
            HStack {
                Toggle(isOn: $isSerializationMode) {
                    Text(isSerializationMode ? "Serialization Mode" : "Deserialization Mode")
                        .font(.headline)
                        .foregroundColor(isSerializationMode ? .blue : .green)
                }
                .toggleStyle(SwitchToggleStyle(tint: isSerializationMode ? .blue : .green))
                .padding()
            }

            // Encoding and Module Selection
            HStack(spacing: 20) {
                Picker("Select Encoding Format", selection: $selectedEncoding) {
                    ForEach(encodingOptions, id: \.self) { encoding in
                        Text(encoding).tag(encoding)
                    }
                }
                .padding()

                Picker("Select Module Version", selection: $selectedModule) {
                    ForEach(moduleOptions, id: \.self) { module in
                        Text(module).tag(module)
                    }
                }
                .padding()
            }

            // Input and Output Sections with Labels
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

            // Python Shell Output Section with Full Black Background
            VStack(alignment: .leading) {
                Text("Python Shell Output (Scrollable):")
                    .font(.headline)
                    .padding(.leading)

                // Black background ScrollView and Text
                ScrollView {
                    VStack {
                        Text(pythonShellOutput)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.green)  // Bright green text
                            .font(.system(.body, design: .monospaced)) // Monospaced font
                    }
                    .frame(maxWidth: .infinity)  // Make the text view expand
                    .background(Color.black)     // Black background for the content
                }
                .frame(height: 150)
                .background(Color.black)         // Black background for the scroll view
                .border(Color.gray, width: 1)     // Optional border for clarity
                .padding([.leading, .trailing])
            }

            // Action Buttons for Serialize, Deserialize, and Execute
            HStack {
                Button(isSerializationMode ? "Serialize" : "Deserialize") {
                    checkModuleAvailability()
                    isSerializationMode ? serializeData() : deserializeData()
                }
                .buttonStyle(.borderedProminent)
                .foregroundColor(.white)
                .background(isSerializationMode ? Color.blue : Color.green)
                .cornerRadius(8)
                .padding()

                Button("Execute Pickle Code") {
                    executePythonCode()
                }
                .buttonStyle(.borderedProminent)
                .foregroundColor(.white)
                .background(Color.green) // Always green button
                .cornerRadius(8)
                .padding()
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

    // Check if the selected module version is installed
    func checkModuleAvailability() {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["python3", "-m", "pip", "show", selectedModule]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""

        if output.isEmpty {
            showAlert("\(selectedModule) is not installed. Please install it to proceed.")
        }
    }

    // Show alert if the module is missing
    func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Module Not Found"
        alert.informativeText = message
        alert.alertStyle = .warning

        // Add More Info button to open help guide
        alert.addButton(withTitle: "More Info")
        alert.addButton(withTitle: "Close")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openHelpGuide()
        }
    }
    
    func openHelpGuide() {
        if let url = URL(string: "https://helpguide.local/install-python-pip-pickle") {
            NSWorkspace.shared.open(url)
        }
    }

    // Serialize Data with Encoding Selection
    func serializeData() {
        let objectToSerialize = inputData

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: objectToSerialize, requiringSecureCoding: false)
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

    // Deserialize Data with Error Handling
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

    // Execute Simulated Python Code
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
