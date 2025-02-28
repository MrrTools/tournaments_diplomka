import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var navigateToMainPage = false
    @State private var showPublicTournaments = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Login").font(.largeTitle).bold().padding()

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button("Login") {
                    AuthService.shared.loginUser(email: email, password: password) { success, error, user in
                        if success {
                            showPublicTournaments = false
                            navigateToMainPage = true
                        } else {
                            self.errorMessage = error
                        }
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                NavigationLink("Register", destination: RegistrationView())
                    .padding()

                Button("Continue without registration") {
                    showPublicTournaments = true
                    navigateToMainPage = true
                }
                .padding()
                .foregroundColor(.blue)

                // ✅ NavigationLink sa aktivuje len keď navigateToMainPage = true
                NavigationLink(destination: MainPageView(showPublicTournaments: showPublicTournaments),
                               isActive: $navigateToMainPage) {
                    EmptyView()
                }
            }
            .padding()
        }
    }
}
