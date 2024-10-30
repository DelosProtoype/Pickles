
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
    @State private var progressValue: Double = 0.0  // Track progress
    @State private var isProcessing: Bool = false  // Track if processing is ongoing
    @State private var taskDescription: String = ""
    
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
                
                if isProcessing {
                           VStack {
                               Text(taskDescription)
                                   .font(.headline)
                               ProgressView(value: progressValue, total: 1.0)
                                   .padding()
                           }
                       }
                
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
                         _ = createWorkingDirectory()  // Ensure the working directory is created on app launch
                     }
        }
    }
    
    func startSerialization() {
        isProcessing = true
        taskDescription = "Serializing Data..."
        progressValue = 0.0

        DispatchQueue.global(qos: .background).async {
            let totalBytes = self.inputData.count
            var processedBytes = 0
            var serializedData = Data()

            for chunk in self.inputData.split(by: 1024) {
                Thread.sleep(forTimeInterval: 0.05)
                if let chunkData = chunk.data(using: .utf8) {
                    serializedData.append(chunkData)
                }

                processedBytes += chunk.count
                let progress = Double(processedBytes) / Double(totalBytes)
                DispatchQueue.main.async {
                    self.progressValue = progress
                }
            }

            DispatchQueue.main.async {
                self.outputData = serializedData.base64EncodedString()
                self.isProcessing = false
                self.progressValue = 1.0
            }
        }
    }

    func startDeserialization() {
        isProcessing = true
        taskDescription = "Deserializing Data..."
        progressValue = 0.0

        DispatchQueue.global(qos: .background).async {
            guard let data = Data(base64Encoded: self.inputData) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid input for deserialization."
                    self.isProcessing = false
                }
                return
            }

            let totalBytes = data.count
            var processedBytes = 0
            var deserializedString = ""

            for chunk in data.chunked(by: 1024) {
                Thread.sleep(forTimeInterval: 0.05)
                if let chunkString = String(data: chunk, encoding: .utf8) {
                    deserializedString += chunkString
                }

                processedBytes += chunk.count
                let progress = Double(processedBytes) / Double(totalBytes)
                DispatchQueue.main.async {
                    self.progressValue = progress
                }
            }

            DispatchQueue.main.async {
                self.outputData = deserializedString
                self.isProcessing = false
                self.progressValue = 1.0
            }
        }
    }

    func updateEncodingSelection() {
        selectedEncoding = isSerializationMode ? encodingOptionsForSerialization.first ?? "Base64" : "Auto-Detect"
    }

    func createWorkingDirectory() -> URL? {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            errorMessage = "Failed to access the Documents directory."
            return nil
        }

        let directory = documentsPath.appendingPathComponent("PicklesApp")
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                errorMessage = "Failed to create working directory: \(error.localizedDescription)"
                return nil
            }
        }
        return directory
    }


    func runPythonCodeReturningData(_ code: String) throws -> Data {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["python3", "-c", code]

        // Set the working directory to ~/Documents/PicklesApp
        if let workingDirectory = createWorkingDirectory()?.path {
            task.currentDirectoryPath = workingDirectory
        }

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
        // Create or access the working directory
        guard let workingDirectory = createWorkingDirectory() else {
            throw NSError(domain: "DeserializationError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to access the working directory."
            ])
        }

        // Save the binary data to a temporary file in the working directory
        let tempFilePath = workingDirectory.appendingPathComponent("pickle_temp.pkl")

        do {
            try data.write(to: tempFilePath)
        } catch {
            throw NSError(domain: "FileWriteError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to save the file '\(tempFilePath.lastPathComponent)'."
            ])
        }

        // Python code to load the pickle data and print the result
        let code = """
        import pickle
        with open('\(tempFilePath.path)', 'rb') as f:
            obj = pickle.load(f)
        print(obj)
        """

        // Run the Python code and capture the output
        let outputData = try runPythonCodeReturningData(code)

        // Ensure the output is valid UTF-8
        guard let result = String(data: outputData, encoding: .utf8) else {
            throw NSError(domain: "DeserializationError", code: 2, userInfo: [
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
        guard let directory = createWorkingDirectory() else {
            errorMessage = "Unable to create or access the working directory."
            return
        }

        let openPanel = NSOpenPanel()
        openPanel.directoryURL = directory
        openPanel.allowedContentTypes = [.init(filenameExtension: "pkl")!]
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK, let url = openPanel.url {
            do {
                let data = try Data(contentsOf: url)
                let deserializedObject = try deserializePickleData(data)
                inputData = "\(deserializedObject)"
                outputData = "Imported Data:\n\(deserializedObject)"
            } catch let error as NSError {
                if error.domain == NSCocoaErrorDomain && error.code == NSFileWriteNoPermissionError {
                    errorMessage = "You don’t have permission to save the file. Please check your directory permissions."
                } else {
                    errorMessage = "Failed to import .pkl file: \(error.localizedDescription)"
                }
            }
        }
    }

    func exportPickleFile() {
        guard let directory = createWorkingDirectory() else {
            errorMessage = "Unable to create or access the working directory."
            return
        }

        let exportURL = directory.appendingPathComponent("exported_data.pkl")

        do {
            let data = try serializeToPickle(outputData)
            try data.write(to: exportURL)
            print("Exported to: \(exportURL.path)")
        } catch {
            errorMessage = "Failed to export .pkl file: \(error.localizedDescription)"
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

extension String {
    func split(by length: Int) -> [String] {
        var result: [String] = []
        var currentIndex = startIndex

        while currentIndex < endIndex {
            let nextIndex = index(currentIndex, offsetBy: length, limitedBy: endIndex) ?? endIndex
            let chunk = String(self[currentIndex..<nextIndex])
            result.append(chunk)
            currentIndex = nextIndex
        }

        return result
    }
}

extension Data {
    func chunked(by length: Int) -> [Data] {
        var chunks: [Data] = []
        var index = 0

        while index < count {
            let chunkSize = Swift.min(length, count - index)
            let chunk = self.subdata(in: index..<index + chunkSize)
            chunks.append(chunk)
            index += chunkSize
        }

        return chunks
    }
}


