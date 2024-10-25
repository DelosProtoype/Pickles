import SwiftUI

struct ContentView: View {
    @State private var inputData: String = ""
    @State private var outputData: String = ""
    @State private var pythonShellOutput: String = "Python Execution Shell Output"
    @State private var selectedEncoding: String = "utf-8"
    @State private var selectedModule: String = "pickle"
    @State private var isSerializationMode: Bool = false  // Start in Deserialization mode
    @State private var errorMessage: String? = nil

    let encodingOptions = ["utf-8", "ascii", "latin-1", "unicode_escape"]
    let moduleOptions = ["pickle", "pickle5"]

    // Custom colors
    let darkGreen = Color(red: 0.0, green: 0.5, blue: 0.0)
    let redButton = Color.red

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 20) {
                Text("Pickles - Data Serializer & Deserializer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

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
                            .frame(height: geometry.size.height * 0.25)
                            .padding()
                    }

                    VStack(alignment: .leading) {
                        Text("Output Data (Copyable):")
                            .font(.headline)
                        ScrollView {
                            Text(outputData)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .border(Color.gray, width: 1)
                                .textSelection(.enabled)
                        }
                        .frame(height: geometry.size.height * 0.25)
                        .padding()
                    }
                }

                // Python Shell Output Section
                VStack(alignment: .leading) {
                    Text("Python Shell Output (Scrollable):")
                        .font(.headline)
                        .padding(.leading)

                    ScrollView {
                        VStack {
                            Text(pythonShellOutput)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.green)
                                .font(.system(.body, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                    }
                    .frame(height: geometry.size.height * 0.2)
                    .background(Color.black)
                    .border(Color.gray, width: 1)
                    .padding([.leading, .trailing])
                }

                // Error Message Display (Above Buttons)
                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                }

                Spacer()

                // Action Buttons and Toggle Alignment
                HStack(spacing: 40) {
                    HStack {
                        // Serialize/Deserialize Button with Dynamic Colors
                        Button(isSerializationMode ? "Serialize" : "Deserialize") {
                            if validateModeMismatch() {
                                isSerializationMode ? serializeData() : deserializeData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.white)
                        .background(isSerializationMode ? Color.blue : darkGreen)  // Blue for Serialize, Green for Deserialize
                        .cornerRadius(8)
                        .padding()

                        // Execute Pickle Code Button (Always Red)
                        Button("Execute Pickle Code") {
                            guard validateExecutableCode() else { return }
                            executePythonCode()
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.white)
                        .background(redButton)  // Ensure Red Button
                        .cornerRadius(8)
                        .padding()
                    }

                    Spacer().frame(width: 80)  // Space between buttons and the toggle

                    // Toggle Button for Serialization/Deserialization Mode
                    Toggle(isOn: $isSerializationMode) {
                        Text(isSerializationMode ? "Serialization Mode" : "Deserialization Mode")
                            .font(.headline)
                            .foregroundColor(isSerializationMode ? .blue : darkGreen)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: isSerializationMode ? .blue : darkGreen))
                    .padding()
                }
            }
            .padding()
        }
    }

    // Validate if the user has entered the correct type of data for the selected mode
    func validateModeMismatch() -> Bool {
        if isSerializationMode {
            // Check if the input data is non-empty and not already Base64 encoded
            if Data(base64Encoded: inputData) != nil {
                errorMessage = "Input data appears to be serialized. Please switch to 'Deserialize' mode."
                return false
            }
        } else {
            // Check if the input data is Base64 encoded (serialized)
            if Data(base64Encoded: inputData) == nil {
                errorMessage = "Input data is not serialized. Please switch to 'Serialize' mode."
                return false
            }
        }
        errorMessage = nil  // No mismatch detected
        return true
    }

    // Validate if input contains executable code
    func validateExecutableCode() -> Bool {
        if inputData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "No executable code found. Please enter valid Python code."
            return false
        }
        errorMessage = nil
        return true
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

    func serializeData() {
        let objectToSerialize = inputData

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: objectToSerialize, requiringSecureCoding: false)
            let base64String = data.base64EncodedString()
            outputData = base64String
            pythonShellOutput = "Serialized Data (Base64):\n\(base64String)"
        } catch {
            errorMessage = "Serialization error: \(error.localizedDescription)"
        }
    }

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
