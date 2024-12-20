import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isError = false
    @State private var navigateToHome = false
    @State private var userId: Int? // User ID for successful login
    let dbHelper: SQLiteHelper // Use SQLiteHelper as a plain class instance

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Login")
                    .font(.largeTitle)
                    .bold()
                    .padding()

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

                // Error Message
                if isError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top)
                }

                // Login Button
                Button(action: handleLogin) {
                    Text("Login")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                // Navigation to Register View
                NavigationLink(destination: RegisterView(dbHelper: dbHelper)) {
                    Text("Don't have an account? Register")
                        .foregroundColor(.blue)
                        .padding(.top)
                }

                Spacer()

                // Navigation to HomeView on successful login
                NavigationLink(destination: HomeView(dbHelper: dbHelper, userId: userId ?? 0),
                               isActive: $navigateToHome) {
                    EmptyView()
                }
                .hidden()
            }
            .padding()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Login Logic
    private func handleLogin() {
        // Clear previous state
        errorMessage = ""
        isError = false

        // Validate input
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in both fields."
            isError = true
            return
        }

        // Verify credentials using SQLiteHelper
        if let userId = dbHelper.verifyUserCredentials(email: email, password: password) {
            self.userId = userId
            navigateToHome = true
        } else {
            errorMessage = "Invalid credentials. Please try again."
            isError = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(dbHelper: SQLiteHelper(databaseName: "BloodTestLab.sqlite"))
    }
}
