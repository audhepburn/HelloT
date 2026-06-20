//
//  LoginView.swift
//  HelloT
//
//  Created by Hermes on 2026/6/8.
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import GoogleSignIn

// MARK: - 登录页面

struct LoginView: View {
    // 深浅色模式
    @AppStorage("isDarkMode") private var isDarkMode = false

    // 表单状态
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showRegister = false

    // 背景与文字颜色
    private var bgColor: Color { isDarkMode ? .neuBgDark : .neuBg }
    private var textColor: Color { isDarkMode ? .white.opacity(0.85) : .black.opacity(0.75) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: 顶部品牌区域
                    headerSection

                    // MARK: Sign in with Apple
                    appleSignInButton

                    // MARK: Sign in with Google
                    googleSignInButton

                    // MARK: 分割线 "or"
                    orDivider

                    // MARK: Email 登录表单
                    emailLoginForm

                    // MARK: 登录按钮
                    signInButton

                    // MARK: 底部注册链接
                    signUpLink
                }
                .padding(.horizontal, 28)
                .padding(.top, 40)
                .padding(.bottom, 32)
            }
            .background(bgColor.ignoresSafeArea())
            .navigationBarHidden(true)
            .alert(L("error"), isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .disabled(isLoading)
            // sheet 方式打开注册页
            .sheet(isPresented: $showRegister) {
                RegisterView(isDarkMode: isDarkMode)
            }
        }
    }

    // MARK: - 顶部品牌区域

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 52))
                .foregroundColor(.blue)

            Text("HelloT")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(textColor)

            Text(L("welcome"))
                .font(.subheadline)
                .foregroundColor(textColor.opacity(0.6))
        }
        .padding(.bottom, 16)
    }

    // MARK: - Sign in with Apple 按钮

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            let hashedNonce = AuthManager.shared.startSignInWithAppleFlow()
            request.requestedScopes = [.fullName, .email]
            request.nonce = hashedNonce
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    AuthManager.shared.signInWithApple(credential: credential)
                }
            case .failure(let error):
                if (error as? ASAuthorizationError)?.code != .canceled {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .neuRaised(isDark: isDarkMode, radius: 8, offset: 5)
    }

    // MARK: - Sign in with Google 按钮

    private var googleSignInButton: some View {
        Button {
            AuthManager.shared.signInWithGoogle { error in
                if let error {
                    errorMessage = error.localizedDescription
                }
            }
        } label: {
            HStack(spacing: 12) {
                // "G" 图标
                Text("G")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(L("sign.in.google"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
        }
    }

    // MARK: - 分割线 "or"

    private var orDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(textColor.opacity(0.2))
                .frame(height: 1)

            Text(L("or"))
                .font(.subheadline)
                .foregroundColor(textColor.opacity(0.4))

            Rectangle()
                .fill(textColor.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Email 登录表单

    private var emailLoginForm: some View {
        VStack(spacing: 16) {
            TextField(L("email"), text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(bgColor)
                )
                .neuInset(isDark: isDarkMode, radius: 6, offset: 4)
                .foregroundColor(textColor)

            SecureField(L("password"), text: $password)
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(bgColor)
                )
                .neuInset(isDark: isDarkMode, radius: 6, offset: 4)
                .foregroundColor(textColor)
        }
    }

    // MARK: - 登录按钮

    private var signInButton: some View {
        Button {
            guard !email.isEmpty, !password.isEmpty else {
                errorMessage = L("field.required")
                return
            }
            isLoading = true
            AuthManager.shared.signInWithEmail(email: email, password: password) { success, error in
                isLoading = false
                if !success {
                    errorMessage = error
                }
            }
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(L("sign.in"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
            )
            .neuRaised(isDark: isDarkMode, radius: 8, offset: 5)
        }
        .disabled(isLoading)
    }

    // MARK: - 底部注册链接

    private var signUpLink: some View {
        HStack(spacing: 4) {
            Text(L("no.account"))
                .font(.subheadline)
                .foregroundColor(textColor.opacity(0.5))

            Button {
                showRegister = true
            } label: {
                Text(L("sign.up"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.blue)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - 注册页面

struct RegisterView: View {
    let isDarkMode: Bool

    // 表单状态
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    // 背景与文字颜色
    private var bgColor: Color { isDarkMode ? .neuBgDark : .neuBg }
    private var textColor: Color { isDarkMode ? .white.opacity(0.85) : .black.opacity(0.75) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 标题
                    Text(L("sign.up"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                        .padding(.top, 32)
                        .padding(.bottom, 12)

                    // Name 输入框
                    TextField(L("name"), text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(bgColor)
                        )
                        .neuInset(isDark: isDarkMode, radius: 6, offset: 4)
                        .foregroundColor(textColor)

                    // Email 输入框
                    TextField(L("email"), text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(bgColor)
                        )
                        .neuInset(isDark: isDarkMode, radius: 6, offset: 4)
                        .foregroundColor(textColor)

                    // Password 输入框
                    SecureField(L("password"), text: $password)
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(bgColor)
                        )
                        .neuInset(isDark: isDarkMode, radius: 6, offset: 4)
                        .foregroundColor(textColor)

                    // Confirm Password 输入框
                    SecureField(L("confirm.password"), text: $confirmPassword)
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(bgColor)
                        )
                        .neuInset(isDark: isDarkMode, radius: 6, offset: 4)
                        .foregroundColor(textColor)

                    // Sign Up 按钮
                    Button {
                        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
                            errorMessage = L("field.required")
                            return
                        }
                        guard password == confirmPassword else {
                            errorMessage = L("password.mismatch")
                            return
                        }
                        isLoading = true
                        AuthManager.shared.signUpWithEmail(
                            email: email,
                            password: password,
                            name: name
                        ) { success, error in
                            isLoading = false
                            if !success {
                                errorMessage = error
                            } else {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(L("sign.up"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                        .neuRaised(isDark: isDarkMode, radius: 8, offset: 5)
                    }
                    .disabled(isLoading)

                    // 底部返回登录链接
                    HStack(spacing: 4) {
                        Text(L("has.account"))
                            .font(.subheadline)
                            .foregroundColor(textColor.opacity(0.5))

                        Button {
                            dismiss()
                        } label: {
                            Text(L("sign.in"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 28)
            }
            .background(bgColor.ignoresSafeArea())
            .navigationBarHidden(true)
            .alert(L("error"), isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .disabled(isLoading)
        }
    }
}
