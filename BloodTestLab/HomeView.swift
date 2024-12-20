import SwiftUI

struct HomeView: View {
    @ObservedObject var dbHelper: SQLiteHelper
    var userId: Int

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Welcome to Blood Test Lab!")
                    .font(.largeTitle)
                    .padding()

                // Add Appointment Button
                NavigationLink(destination: AddAppointmentView(dbHelper: dbHelper)) {
                    Text("Add Appointment")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                // Manage Appointment Button
                NavigationLink(destination: ManageAppointmentView(dbHelper: dbHelper, userId: userId)) {
                    Text("Manage Appointment")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                }

                // View Results Button
                NavigationLink(destination: ResultsView(dbHelper: dbHelper, userId: userId)) {
                    Text("View Results")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }

                Spacer()
            }
            .padding()
        }
    }
}
