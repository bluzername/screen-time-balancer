// AuthenticationView.swift
// Screen Time Parent - Login/Signup UI

import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isSignUp = false
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var nameError: String?
    @FocusState private var focusedField: Field?

    enum Field {
        case name, email, password
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and title
                    VStack(spacing: 16) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 70))
                            .foregroundColor(.blue)

                        Text("Screen Time Balancer")
                            .font(.title)
                            .fontWeight(.bold)

                        Text(isSignUp ? "Create Parent Account" : "Sign in to manage screen time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 16) {
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Full Name", text: $fullName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.name)
                                    .focused($focusedField, equals: .name)
                                    .onChange(of: fullName) { newValue in
                                        fullName = InputSanitizer.sanitizeText(newValue)
                                        fullName = InputSanitizer.limitLength(fullName, maxLength: 100)
                                        nameError = NameValidator.validationError(for: fullName)
                                    }

                                if let error = nameError, !fullName.isEmpty {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .focused($focusedField, equals: .email)
                                .onChange(of: email) { newValue in
                                    email = InputSanitizer.sanitizeText(newValue)
                                    email = InputSanitizer.limitLength(email, maxLength: 254)
                                    emailError = EmailValidator.validationError(for: email)
                                }

                            if let error = emailError, !email.isEmpty {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(isSignUp ? .newPassword : .password)
                                .focused($focusedField, equals: .password)
                                .onChange(of: password) { newValue in
                                    password = InputSanitizer.limitLength(newValue, maxLength: 128)
                                    if isSignUp {
                                        let validation = PasswordValidator.validate(password)
                                        passwordError = validation.errorMessage
                                    }
                                }

                            if isSignUp {
                                if let error = passwordError, !password.isEmpty {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                } else if !password.isEmpty {
                                    let strength = PasswordValidator.strength(password)
                                    HStack {
                                        Text("Password strength:")
                                            .font(.caption)
                                        Text(strength.description)
                                            .font(.caption)
                                            .foregroundColor(strengthColor(strength))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    // Action button
                    Button(action: {
                        if isSignUp {
                            viewModel.signUp(email: email, password: password, fullName: fullName)
                        } else {
                            viewModel.signIn(email: email, password: password)
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(viewModel.isLoading || !isFormValid)

                    // Toggle sign up/in
                    Button(action: {
                        isSignUp.toggle()
                        viewModel.errorMessage = nil
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                    }

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var isFormValid: Bool {
        if isSignUp {
            return emailError == nil &&
                   passwordError == nil &&
                   nameError == nil &&
                   !email.isEmpty &&
                   !password.isEmpty &&
                   !fullName.isEmpty &&
                   EmailValidator.isValid(email) &&
                   PasswordValidator.validate(password).isValid
        } else {
            return !email.isEmpty &&
                   !password.isEmpty &&
                   EmailValidator.isValid(email)
        }
    }

    private func strengthColor(_ strength: PasswordStrength) -> Color {
        switch strength {
        case .weak:
            return .red
        case .medium:
            return .orange
        case .strong:
            return .green
        }
    }
}
