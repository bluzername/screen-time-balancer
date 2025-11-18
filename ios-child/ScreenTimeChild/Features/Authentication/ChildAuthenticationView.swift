// ChildAuthenticationView.swift
// Screen Time Child
//
// Authentication UI for child device

import SwiftUI

struct ChildAuthenticationView: View {
    @ObservedObject var viewModel: ChildAuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var inviteCode = ""
    @State private var showInviteCodeEntry = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and title
                    VStack(spacing: 16) {
                        Image(systemName: "hourglass.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.green)

                        Text("Screen Time Balancer")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Child Account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Info card
                    InfoCard()

                    if !showInviteCodeEntry {
                        // Sign in form
                        VStack(spacing: 16) {
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)

                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.password)
                        }
                        .padding(.horizontal)

                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        // Sign in button
                        Button(action: {
                            viewModel.signIn(email: email, password: password)
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disabled(viewModel.isLoading || !isFormValid)

                        // Toggle to invite code
                        Button(action: { showInviteCodeEntry = true }) {
                            Text("Have an invite code? Register device")
                                .font(.subheadline)
                        }
                    } else {
                        // Invite code entry
                        VStack(spacing: 16) {
                            Text("Enter Family Invite Code")
                                .font(.headline)

                            TextField("Invite Code", text: $inviteCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.oneTimeCode)
                                .autocapitalization(.allCharacters)
                                .multilineTextAlignment(.center)
                                .font(.system(.title3, design: .monospaced))
                        }
                        .padding(.horizontal)

                        Button(action: { /* Join family */ }) {
                            Text("Join Family")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disabled(inviteCode.count != 8)

                        Button(action: { showInviteCodeEntry = false }) {
                            Text("Back to sign in")
                                .font(.subheadline)
                        }
                    }

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
}

struct InfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("How It Works")
                    .font(.headline)
            }

            Text("Use educational apps to earn time for games and entertainment. Your parent can see your progress and help you balance screen time.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
