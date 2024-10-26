import SwiftUI

struct ContentView: View {
    @State private var inputData: String = ""
    @State private var outputData: String = ""
    @State private var pythonShellOutput: String = "Python Execution Shell Output"
    @State private var selectedEncoding: String = "Auto-Detect"
    @State private var selectedModule: String = "pickle"
    @State private var isSerializationMode: Bool = false  // Start in Deserialization mode
    @State private var errorMessage: String? = nil

    let encodingOptionsForSerialization = ["Base64", "UTF-8", "ASCII", "UTF-16", "Latin-1", "Hex"]
    let encodingOptionsForDeserialization = ["Auto-Detect", "Base64", "UTF-8", "ASCII", "UTF-16", "Latin-1", "Hex"]
    let moduleOptions = ["pickle", "pickle5"]

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
                        ForEach(isSerializationMode ? encodingOptionsForSerialization : encodingOptionsForDeserialization, id: \.self) { encoding in
                            Text(encoding).tag(encoding)
                        }
                    }
                    .padding()
                    .onChange(of: isSerializationMode) { _ in
                        autoDetectEncoding()
                    }

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
                        // Serialize/Deserialize Button
                        Button(isSerializationMode ? "Serialize" : "Deserialize") {
                            if validateModeMismatch() {
                                isSerializationMode ? serializeData() : deserializeData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()

                        // Execute Pickle Code Button
                        Button("Execute Pickle Code") {
                            executePythonCode()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }

                    Spacer().frame(width: 80)

                    Toggle(isOn: $isSerializationMode) {
                        Text(isSerializationMode ? "Serialization Mode" : "Deserialization Mode")
                            .font(.headline)
                    }
                    .toggleStyle(SwitchToggleStyle())
                    .padding()
                }
            }
            .padding()
        }
    }

    // Auto-detect encoding based on input data
    func autoDetectEncoding() {
        guard !isSerializationMode else { return }  // Only auto-detect in deserialization mode

        if let detectedEncoding = detectEncoding(for: inputData) {
            selectedEncoding = detectedEncoding
        } else {
            selectedEncoding = "Auto-Detect"
            errorMessage = "Failed to auto-detect encoding. Please select manually."
        }
    }

    // Detect encoding of input data
    func detectEncoding(for input: String) -> String? {
        if let _ = Data(base64Encoded: input) {
            return "Base64"
        } else if let _ = input.data(using: .utf8) {
            return "UTF-8"
        } else if let _ = input.data(using: .ascii) {
            return "ASCII"
        } else if let _ = input.data(using: .utf16) {
            return "UTF-16"
        } else if input.range(of: #"^[0-9a-fA-F]+$"#, options: .regularExpression) != nil {
            return "Hex"
        } else {
            return nil
        }
    }

    // Validate if the input matches the selected encoding format
    func validateModeMismatch() -> Bool {
        if isSerializationMode {
            if Data(base64Encoded: inputData) != nil && selectedEncoding == "Base64" {
                errorMessage = "Input data is already serialized. Switch to 'Deserialize' mode."
                return false
            }
        } else if selectedEncoding == "Auto-Detect" {
            autoDetectEncoding()
        }
        errorMessage = nil
        return true
    }

    // Validate executable code
    func validateExecutableCode() -> Bool {
        if inputData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "No executable code found. Please enter valid Python code."
            return false
        }
        errorMessage = nil
        return true
    }

    // Execute Python code using a subprocess
    func executePythonCode() {
        guard validateExecutableCode() else { return }

        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["python3", "-c", inputData]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? "Execution failed."

        DispatchQueue.main.async {
            self.pythonShellOutput = output
        }
    }

    // Serialize input data
    func serializeData() {
        guard let data = inputData.data(using: .utf8) else {
            errorMessage = "Failed to encode input data."
            return
        }

        switch selectedEncoding {
        case "Base64":
            outputData = data.base64EncodedString()
        case "Hex":
            outputData = data.map { String(format: "%02x", $0) }.joined()
        default:
            errorMessage = "Encoding not supported."
        }
    }

    // Deserialize input data
    func deserializeData() {
        guard let data = Data(base64Encoded: inputData) else {
            errorMessage = "Invalid input for selected encoding."
            return
        }

        outputData = String(data: data, encoding: .utf8) ?? "Failed to decode data."
    }
}
