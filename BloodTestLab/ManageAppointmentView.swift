import SwiftUI

struct ManageAppointmentView: View {
    @ObservedObject var dbHelper: SQLiteHelper
    var userId: Int
    @State private var appointments: [Appointment] = []
    @State private var newTestTypeIndex: Int = 0
    @State private var newAppointmentDate: Date = Date()
    @State private var errorMessage: String = ""

    let testTypes = ["Complete Blood Count (CBC)", "Lipid Profile", "Blood Sugar Test", "Liver Function Test", "Kidney Function Test", "Thyroid Function Test"]

    var body: some View {
        VStack {
            Text("Manage Appointments")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            if appointments.isEmpty {
                Text("No appointments found!")
                    .padding()
            } else {
                ScrollView {
                    ForEach(appointments, id: \.id) { appointment in
                        AppointmentCard(
                            appointment: appointment,
                            testTypes: testTypes,
                            dbHelper: dbHelper,
                            userId: userId,
                            onAppointmentUpdated: fetchAppointments
                        )
                    }
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
        }
        .onAppear {
            fetchAppointments()
        }
        .padding()
    }

    private func fetchAppointments() {
        appointments = dbHelper.getAppointmentsForUser(userId: userId)
        if appointments.isEmpty {
            errorMessage = "No appointments found."
        } else {
            errorMessage = ""
        }
    }
}

struct AppointmentCard: View {
    let appointment: Appointment
    let testTypes: [String]
    @ObservedObject var dbHelper: SQLiteHelper
    var userId: Int
    var onAppointmentUpdated: () -> Void

    @State private var newTestTypeIndex: Int = 0
    @State private var newAppointmentDate: Date = Date()
    @State private var showEditMode = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Doctor: \(appointment.doctorName)")
            Text("Date: \(appointment.appointmentDate)")
            Text("Tests: \(appointment.testTypes.joined(separator: ", "))")
            Text("Time: \(appointment.timeSlot)")
            Text("Address: \(appointment.address)")

            if showEditMode {
                editMode
            } else {
                Button("Edit Appointment") {
                    showEditMode.toggle()
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Button("Cancel Appointment") {
                if dbHelper.cancelAppointment(appointmentId: appointment.id) {
                    onAppointmentUpdated()
                } else {
                    print("Failed to cancel the appointment.")
                }
            }
            .foregroundColor(.red)
            .padding()
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private var editMode: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("New Test Type", selection: $newTestTypeIndex) {
                ForEach(0..<testTypes.count, id: \.self) {
                    Text(testTypes[$0])
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)

            DatePicker("New Appointment Date", selection: $newAppointmentDate, displayedComponents: .date)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            Button("Update Appointment") {
                let newTestType = testTypes[newTestTypeIndex]
                let formattedDate = formatDate(newAppointmentDate)

                if dbHelper.updateAppointment(
                    appointmentId: appointment.id,
                    newDate: formattedDate,
                    newTestType: newTestType
                ) {
                    showEditMode = false
                    onAppointmentUpdated()
                } else {
                    print("Failed to update the appointment.")
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button("Cancel Edit") {
                showEditMode = false
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct ManageAppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        ManageAppointmentView(dbHelper: SQLiteHelper(databaseName: "BloodTestLab.sqlite"), userId: 1)
    }
}
