Pickles - Data Serializer & Deserializer

Overview

Pickles is a powerful and easy-to-use macOS application designed to serialize and deserialize data using Python’s pickle module. It offers a polished interface with encoding format selection, Python module version checks, and even a Python shell simulation for executing code dynamically. The app is tailored for developers working with serialized data, students learning about data serialization, or anyone looking to manipulate and transport complex data models effectively.

Features

	•	Serialization & Deserialization:
	•	Toggle between Serialization and Deserialization modes with a single switch.
	•	Color-Coded Button:
	•	Blue for Serialization.
	•	Green for Deserialization.
	•	Encoding Format Selection:
	•	Choose from several encoding formats, including:
	•	utf-8
	•	ascii
	•	latin-1
	•	unicode_escape
	•	Python Module Version Management:
	•	Select between different installed module versions such as pickle or pickle5.
	•	Module Availability Checks:
	•	If a selected module is missing, the app shows an alert with the option to learn how to install it.
	•	Python Shell Simulation:
	•	Black background with bright green text, replicating a terminal-like look and feel.
	•	Displays output in a scrollable shell window to handle larger outputs.
	•	Copyable Output Data:
	•	Output data fields allow users to select and copy content easily.
	•	Module Availability Alerts with Help Guide:
	•	If a required Python module is missing, the app displays an alert with two options:
	•	“More Info”: Takes the user to a help guide with installation steps for Python, Pip, and Pickle.
	•	“Close”: Dismisses the alert.

Usage Instructions

1. Serialization Mode

	•	Select Serialization Mode using the toggle switch.
	•	Enter your data in the Input Data field.
	•	Choose the encoding format and module version from the dropdowns.
	•	Click the Serialize button (blue) to convert the input data into a Base64-encoded pickle format.
	•	The serialized result will appear in the Output Data field, ready to copy or use elsewhere.

2. Deserialization Mode

	•	Toggle to Deserialization Mode using the switch.
	•	Paste Base64-encoded data into the Input Data field.
	•	Click the Deserialize button (green) to convert the data back to its original form.
	•	The deserialized result will be displayed in the Output Data field.

3. Python Shell Execution

	•	Enter any code or data you want to simulate in the Input Data field.
	•	Click the “Execute Pickle Code” button (always green).
	•	The simulated output will appear in the Python Shell Output field, styled with black background and green text.

Python Module Availability and Installation Guide

The Pickles app checks for the availability of selected Python modules before performing serialization or deserialization.

If a Module is Missing:

	1.	The app will display an alert saying the module is not installed.
	2.	Click “More Info” in the alert to open the installation guide in your browser.

How to Install Python, Pip, and Pickle on macOS:

	1.	Install Homebrew (if not already installed):

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


	2.	Install Python using Homebrew:

brew install python


	3.	Install Pip (if not already installed):

sudo easy_install pip


	4.	Install the required module (e.g., pickle5):

pip3 install pickle5



Troubleshooting

	•	Encoding Errors: Ensure the selected encoding matches the input data type.
	•	Module Not Found: Install the missing Python modules following the steps in the help guide.
	•	Python Shell Display Issues: If the shell output doesn’t display correctly, try resizing the window or restarting the app.
	•	Serialization Errors: If data cannot be serialized, verify that the input is compatible with the selected encoding and module.

How to Build and Run the Project

	1.	Clone the Repository:

git clone https://github.com/yourusername/pickles.git
cd pickles


	2.	Open the Project in Xcode:

open Pickles.xcodeproj


	3.	Build and Run the App:
	•	Use Cmd + R in Xcode to build and launch the application.

Contributing

We welcome contributions to improve Pickles! If you’d like to contribute:

	1.	Fork the repository.
	2.	Create a new branch for your feature or bug fix.
	3.	Submit a pull request with a detailed description of your changes.

License

This project is licensed under the MIT License - see the LICENSE file for details.

Contact

If you encounter any issues or have questions about using the Pickles app, please submit an issue on the GitHub repository.
