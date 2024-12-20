import SwiftUI

struct RegisterView: View {
    @State private var name = ""
    @State var email = ""
    @State var password = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isError = false
    @ObservedObject var dbHelper: SQLiteHelper // Use @ObservedObject properly for SQLiteHelper

    var body: some View {
        VStack(spacing: 20) {
            Text("Register")
                .font(.largeTitle)
                .bold()
                .padding()

            // Name Text Field
            TextField("Name", text: $name)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // Email Text Field
            TextField("Email", text: $email)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)

            // Password Text Field
            SecureField("Password", text: $password)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // Error or Success Message
            if isError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top)
            } else if !successMessage.isEmpty {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding(.top)
            }

            // Register Button
            Button(action: handleRegister) {
                Text("Register")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    // MARK: - Register Logic
    private func handleRegister() {
        // Clear previous state
        errorMessage = ""
        successMessage = ""
        isError = false

        // Validate input
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required."
            isError = true
            return
        }

        // Check if user already exists
        if dbHelper.doesUserExist(email: email) { // Use dbHelper directly, not a binding
            errorMessage = "User already registered. Please log in."
            isError = true
            return
        }

        // Insert new user
        if (dbHelper.insertUser(name: name, email: email, password: password) != nil) {
            // Use dbHelper directly
            if let userId = dbHelper.verifyUserCredentials(email: email, password: password) {
                
            }
            successMessage = "Registration successful! You can now log in."
            isError = false
        } else {
            errorMessage = "Failed to register. Please try again."
            isError = true
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(dbHelper: SQLiteHelper(databaseName: "BloodTestLab.sqlite"))
    }
}
