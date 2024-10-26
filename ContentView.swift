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

                // Action Buttons and File Handling Section
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

                    // File Import and Export Buttons
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
    
    func serializeToPickle(_ data: String) throws -> Data {
        // Python code to serialize data to a pickle object
        let code = """
        import pickle
        data = pickle.dumps(\(data))
        print(data)
        """

        // Run the Python code and return the result as binary data
        return try runPythonCodeReturningData(code)
    }
    
    
    func deserializePickleData(_ data: Data) throws -> Any {
        // Save data to a temporary file
        let tempFilePath = "/tmp/pickle_temp.pkl"
        try data.write(to: URL(fileURLWithPath: tempFilePath))

        // Python code to load and print the pickle data
        let code = """
        import pickle
        with open('\(tempFilePath)', 'rb') as f:
            data = pickle.load(f)
        print(data)
        """

        // Run the Python code and capture the output
        return try runPythonCodeReturningData(code)
    }
    
    
    // Import a .pkl file and deserialize it
    func importPickleFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "pkl")!]
        panel.allowsMultipleSelection = false

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

    // Export the current output as a .pkl file
    func exportPickleFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "pkl")!]
        panel.nameFieldStringValue = "exported_data.pkl"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try serializeToPickle(outputData)
                try data.write(to: url)
            } catch {
                errorMessage = "Failed to export .pkl file: \(error.localizedDescription)"
            }
        }
    }

    // Serialize data into pickle format
    func serializeData() {
        guard let data = inputData.data(using: .utf8) else {
            errorMessage = "Failed to encode input data."
            return
        }
        outputData = data.base64EncodedString()
    }

    // Deserialize data from pickle format
    func deserializeData() {
        guard let data = Data(base64Encoded: inputData) else {
            errorMessage = "Invalid input for deserialization."
            return
        }
        outputData = String(data: data, encoding: .utf8) ?? "Failed to decode data."
    }

    // Execute Python code
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

    // Validate if the mode matches the input data
    func validateModeMismatch() -> Bool {
        if isSerializationMode {
            if Data(base64Encoded: inputData) != nil {
                errorMessage = "Input appears to be serialized. Switch to 'Deserialize' mode."
                return false
            }
        }
        return true
    }
}
