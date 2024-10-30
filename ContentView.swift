
// iteration 001



import SwiftUI

struct ContentView: View {
    @State private var inputData: String = ""
    @State private var outputData: String = ""
    @State private var pythonShellOutput: String = "Python Execution Shell Output"
    @State private var selectedEncoding: String = "Auto-Detect"
    @State private var selectedModule: String = "pickle"
    @State private var isSerializationMode: Bool = false  // Start in Deserialization mode
    @State private var errorMessage: String? = nil

    let encodingOptionsForSerialization = ["Base64", "UTF-8", "ASCII", "UTF-16", "Latin-1", "Hex", "Pickle Byte String"]
    let encodingOptionsForDeserialization = ["Auto-Detect", "Base64", "UTF-8", "ASCII", "UTF-16", "Latin-1", "Hex", "Pickle Byte String"]
    let moduleOptions = ["pickle", "pickle5"]

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 20) {
                Text("Pickles - Data Serializer & Deserializer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                HStack(spacing: 20) {
                    Picker("Select Encoding Format", selection: $selectedEncoding) {
                        ForEach(isSerializationMode ? encodingOptionsForSerialization : encodingOptionsForDeserialization, id: \.self) { encoding in
                            Text(encoding).tag(encoding)
                        }
                    }
                    .padding()
                    .onChange(of: isSerializationMode) { _ in updateEncodingSelection() }

                    Picker("Select Module Version", selection: $selectedModule) {
                        ForEach(moduleOptions, id: \.self) { module in
                            Text(module).tag(module)
                        }
                    }
                    .padding()
                }

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
                        Text("Output Data:")
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

                VStack(alignment: .leading) {
                    Text("Python Shell Output:")
                        .font(.headline)
                        .padding(.leading)

                    ScrollView {
                        VStack {
                            Text(pythonShellOutput)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.green)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                    }
                    .frame(height: geometry.size.height * 0.2)
                    .background(Color.black)
                    .border(Color.gray, width: 1)
                    .padding([.leading, .trailing])
                }

                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                }

                Spacer()

                HStack(spacing: 40) {
                    Button(isSerializationMode ? "Serialize" : "Deserialize") {
                        if validateModeMismatch() {
                            isSerializationMode ? serializeData() : deserializeData()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()

                    Button("Execute Pickle Code") {
                        executePythonCode()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()

                    Button("Import .pkl") {
                        importPickleFile()
                    }
                    .buttonStyle(.bordered)

                    Button("Export .pkl") {
                        exportPickleFile()
                    }
                    .buttonStyle(.bordered)

                    Toggle(isOn: $isSerializationMode) {
                        Text(isSerializationMode ? "Serialization Mode" : "Deserialization Mode")
                            .font(.headline)
                    }
                    .toggleStyle(SwitchToggleStyle())
                    .padding()
                }
            }
            .padding()
            .onAppear {
                createWorkingDirectory()
            }
        }
    }

    // Ensure correct encoding selection when switching modes
    func updateEncodingSelection() {
        if isSerializationMode {
            selectedEncoding = encodingOptionsForSerialization.first ?? "Base64"
        } else {
            selectedEncoding = "Auto-Detect"
        }
    }

    // Create a working directory in ~/Documents/Pickles
    func createWorkingDirectory() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let picklesDirectory = documentsPath.appendingPathComponent("Pickles")

        if !fileManager.fileExists(atPath: picklesDirectory.path) {
            do {
                try fileManager.createDirectory(at: picklesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                errorMessage = "Failed to create working directory: \(error.localizedDescription)"
            }
        }
    }

    func runPythonCodeReturningData(_ code: String) throws -> Data {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["python3", "-c", code]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()
        task.waitUntilExit()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        if task.terminationStatus != 0 {
            throw NSError(domain: "PythonExecutionError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to execute Python code."
            ])
        }
        return outputData
    }

    func serializeToPickle(_ input: String) throws -> Data {
        let code = """
        import pickle
        import sys
        data = pickle.dumps('\(input)')
        sys.stdout.buffer.write(data)
        """

        // Run the Python code and return the binary result directly
        return try runPythonCodeReturningData(code)
    }

    func deserializePickleData(_ data: Data) throws -> Any {
        // Save the binary data to a temporary file
        let tempFilePath = "/tmp/pickle_temp.pkl"
        try data.write(to: URL(fileURLWithPath: tempFilePath))

        // Python code to load the pickle data and print the result
        let code = """
        import pickle
        with open('\(tempFilePath)', 'rb') as f:
            obj = pickle.load(f)
        print(obj)
        """

        // Run the Python code and capture the output
        let outputData = try runPythonCodeReturningData(code)

        // Ensure the output is valid UTF-8
        guard let result = String(data: outputData, encoding: .utf8) else {
            throw NSError(domain: "DeserializationError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to decode deserialized data."
            ])
        }
        return result
    }

    func serializeData() {
        switch selectedEncoding {
        case "Pickle Byte String":
            do {
                let data = try serializeToPickle(inputData)
                outputData = data.map { String(format: "\\x%02x", $0) }.joined()
            } catch {
                errorMessage = "Serialization error: \(error.localizedDescription)"
            }
        default:
            guard let data = inputData.data(using: .utf8) else {
                errorMessage = "Failed to encode input data."
                return
            }
            outputData = data.base64EncodedString()
        }
    }

    func deserializeData() {
        if selectedEncoding == "Pickle Byte String" {
            guard let data = convertPickleStringToData(inputData) else {
                errorMessage = "Invalid Pickle Byte String input."
                return
            }

            do {
                let deserializedObject = try deserializePickleData(data)
                outputData = "\(deserializedObject)"
            } catch {
                errorMessage = "Deserialization error: \(error.localizedDescription)"
            }
        } else {
            // Handle other encodings, such as Base64
            guard let data = Data(base64Encoded: inputData) else {
                errorMessage = "Invalid input for deserialization."
                return
            }
            outputData = String(data: data, encoding: .utf8) ?? "Failed to decode data."
        }
    }

    func convertPickleStringToData(_ input: String) -> Data? {
        // Clean and remove escape sequences
        let cleanedString = input
            .replacingOccurrences(of: "b'", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\\x", with: "")

        // Ensure the cleaned string has an even number of characters
        guard cleanedString.count % 2 == 0 else {
            print("Error: Input string has an odd length.")
            return nil
        }

        // Convert hex string to binary data
        var byteArray: [UInt8] = []
        var index = cleanedString.startIndex

        while index < cleanedString.endIndex {
            let nextIndex = cleanedString.index(index, offsetBy: 2)
            let byteString = String(cleanedString[index..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                byteArray.append(byte)
            }
            index = nextIndex
        }
        return Data(byteArray)
    }

    func importPickleFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "pkl")!]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                let deserializedObject = try deserializePickleData(data)
                inputData = "\(deserializedObject)"
                outputData = "Imported Data:\n\(deserializedObject)"
            } catch {
                errorMessage = "Failed to import .pkl file: \(error.localizedDescription)"
            }
        }
    }

    func exportPickleFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "pkl")!]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try serializeToPickle(outputData)
                try data.write(to: url)
            } catch {
                errorMessage = "Failed to export .pkl file: \(error.localizedDescription)"
            }
        }
    }

    func validateModeMismatch() -> Bool {
        if isSerializationMode {
            // Check if input appears to be serialized data
            if Data(base64Encoded: inputData) != nil {
                errorMessage = "Input appears to be serialized. Switch to 'Deserialize' mode."
                return false
            }
        } else {
            // Check if input is valid for deserialization
            if inputData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "No input data provided. Please enter valid serialized data."
                return false
            }
        }
        errorMessage = nil
        return true
    }
    
    func handleLargeInputData() {
        let maxAllowedSize = 10 * 1024 * 1024 // 10MB
        if inputData.count > maxAllowedSize {
            errorMessage = "Input data is too large. Maximum allowed size is 10MB."
        }
    }

    func validateInputForDeserialization() -> Bool {
        guard !inputData.isEmpty else {
            errorMessage = "Empty input data. Please provide valid data to deserialize."
            return false
        }
        
        if selectedEncoding == "Pickle Byte String" && convertPickleStringToData(inputData) == nil {
            errorMessage = "Invalid Pickle Byte String format. Please check your input."
            return false
        }
        
        return true
    }
    
    func executePythonCode() {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["python3", "-c", inputData]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()
        task.waitUntilExit()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        pythonShellOutput = String(data: outputData, encoding: .utf8) ?? "Execution failed."
    }
}
