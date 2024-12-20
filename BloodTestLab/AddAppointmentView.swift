import SwiftUI

struct AddAppointmentView: View {
    @ObservedObject var dbHelper: SQLiteHelper
    @State private var doctorName: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedTimeSlot: String = ""
    @State private var selectedTests: [String] = []
    @State private var address: String = ""
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""
    @State private var isError: Bool = false

    let availableTests = ["CBC", "Lipid Profile", "Blood Sugar", "Thyroid Panel"]
    let timeSlots = ["9:00 AM", "10:00 AM", "11:00 AM", "1:00 PM", "3:00 PM"]

    var body: some View {
        VStack {
            Text("Add Appointment")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)

            TextField("Doctor Name", text: $doctorName)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            DatePicker("Appointment Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            Picker("Available Time Slots", selection: $selectedTimeSlot) {
                ForEach(timeSlots, id: \.self) { slot in
                    Text(slot)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)

            VStack(alignment: .leading) {
                Text("Select Tests")
                    .font(.headline)
                ScrollView {
                ForEach(availableTests, id: \.self) { test in
                    Button(action: {
                        toggleTestSelection(test)
                    }) {
                        
                        HStack {
                            Text(test)
                            Spacer()
                            if selectedTests.contains(test) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }
            }
            .padding(.top)

            TextField("Address for Sample Collection", text: $address)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            if isError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }

            if !successMessage.isEmpty {
                Text(successMessage)
                    .foregroundColor(.green)
                    .padding(.top, 10)
            }

            Button("Add Appointment") {
                handleAddAppointment()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    private func toggleTestSelection(_ test: String) {
        if selectedTests.contains(test) {
            selectedTests.removeAll { $0 == test }
        } else {
            selectedTests.append(test)
        }
    }

    private func handleAddAppointment() {
        // Clear messages
        errorMessage = ""
        successMessage = ""
        isError = false

        // Validate fields
        if doctorName.isEmpty || address.isEmpty || selectedTimeSlot.isEmpty {
            errorMessage = "Please fill in all required fields."
            isError = true
            return
        }

        if selectedTests.isEmpty {
            errorMessage = "Please select at least one test."
            isError = true
            return
        }

        // Insert appointment into the database
        let userId = dbHelper.verifyUserCredentials(email: RegisterView(dbHelper: SQLiteHelper(databaseName: "BloodTestLab.sqlite")).email, password: RegisterView(dbHelper: SQLiteHelper(databaseName: "BloodTestLab.sqlite")).password) 
            
        
        
        if dbHelper.insertAppointment(userId: userId! ,doctorName: doctorName, testTypes: selectedTests, appointmentDate: selectedDate, timeSlot: selectedTimeSlot, address: address) {
            successMessage = "Appointment added successfully!"
            dbHelper.fetchAppointments()
            isError = false
        } else {
            errorMessage = "Failed to add appointment. Please try again."
            isError = true
        }
    }
    
    
}

struct AddAppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        AddAppointmentView(dbHelper: SQLiteHelper(databaseName: "BloodTestLab.sqlite"))
    }
}
