import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import GoogleSignIn

// MARK: - Firebase 认证管理器

/// 统一管理 Firebase 身份认证，支持 Apple、Google、邮箱密码三种登录方式
final class AuthManager: ObservableObject {

    // MARK: - 单例

    static let shared = AuthManager()

    // MARK: - 发布属性

    /// 当前 Firebase 用户，nil 表示未登录
    @Published var user: FirebaseAuth.User?
    /// 是否已认证
    @Published var isAuthenticated: Bool = false

    // MARK: - 私有状态

    /// Sign in with Apple 流程中使用的原始 nonce（未哈希）
    private var currentNonce: String?

    // MARK: - 初始化

    private init() {
        listenAuthState()
    }

    // MARK: - 认证状态监听

    /// 监听 Firebase 认证状态变化，自动更新 user / isAuthenticated
    private func listenAuthState() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = (user != nil)
            }
        }
    }

    // MARK: - Sign in with Apple

    /// 启动 Apple 登录流程，生成 nonce 并返回其 SHA256 哈希值。
    /// 调用方将返回值传给 ASAuthorizationAppleIDRequest 的 requestedOperation。
    @discardableResult
    func startSignInWithAppleFlow() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    /// 处理 Apple 登录成功后的凭据，完成 Firebase 认证
    /// - Parameter credential: ASAuthorizationAppleIDCredential
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        guard let nonce = currentNonce else {
            print("[AuthManager] Apple 登录失败：缺少 nonce")
            return
        }
        guard let appleIDToken = credential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("[AuthManager] Apple 登录失败：无法读取 identityToken")
            return
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )

        Auth.auth().signIn(with: firebaseCredential) { [weak self] result, error in
            if let error {
                print("[AuthManager] Apple 登录失败：\(error.localizedDescription)")
                return
            }
            guard let result else { return }
            self?.saveUserToFirestore(result.user)
            self?.currentNonce = nil
        }
    }

    // MARK: - Sign in with Google

    /// 使用 Google 登录，获取 idToken + accessToken 后完成 Firebase 认证
    func signInWithGoogle() {
        // 获取当前 presenting ViewController
        guard let presentingVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            print("[AuthManager] Google 登录失败：无法获取 presenting ViewController")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { [weak self] result, error in
            if let error {
                print("[AuthManager] Google 登录失败：\(error.localizedDescription)")
                return
            }
            guard let result,
                  let idToken = result.user.idToken?.tokenString else {
                print("[AuthManager] Google 登录失败：无法获取 idToken")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error {
                    print("[AuthManager] Firebase Google 认证失败：\(error.localizedDescription)")
                    return
                }
                if let authResult {
                    self?.saveUserToFirestore(authResult.user)
                }
            }
        }
    }

    // MARK: - Email / Password

    /// 邮箱密码登录
    /// - Parameters:
    ///   - email: 邮箱
    ///   - password: 密码
    ///   - completion: 结果回调 (success, errorMessage)
    func signInWithEmail(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error {
                completion(false, error.localizedDescription)
                return
            }
            if let result {
                self?.saveUserToFirestore(result.user)
            }
            completion(true, nil)
        }
    }

    /// 邮箱密码注册
    /// - Parameters:
    ///   - email: 邮箱
    ///   - password: 密码
    ///   - name: 显示名称
    ///   - completion: 结果回调 (success, errorMessage)
    func signUpWithEmail(email: String, password: String, name: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error {
                completion(false, error.localizedDescription)
                return
            }
            guard let result else {
                completion(false, "注册失败")
                return
            }
            // 设置显示名称
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            changeRequest.commitChanges { _ in
                self?.saveUserToFirestore(result.user)
                completion(true, nil)
            }
        }
    }

    // MARK: - 登出

    /// 登出 Firebase 和 Google 账号
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            print("[AuthManager] 登出失败：\(error.localizedDescription)")
        }
    }

    // MARK: - 删除账号

    /// 删除当前用户账号：先删除 Firestore 用户文档，再删除 Firebase Auth 用户
    /// - Parameter completion: 结果回调 (success, errorMessage)
    func deleteAccount(completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, "当前无登录用户")
            return
        }

        let uid = user.uid
        let db = Firestore.firestore()

        // 先删除 Firestore 用户文档
        db.collection("users").document(uid).delete { error in
            if let error {
                print("[AuthManager] 删除用户文档失败：\(error.localizedDescription)")
            }

            // 再删除 Auth 用户
            user.delete { error in
                if let error {
                    completion(false, error.localizedDescription)
                    return
                }
                completion(true, nil)
            }
        }
    }

    // MARK: - Firestore 持久化

    /// 将用户基本信息写入 Firestore users 集合（merge 模式）
    /// - Parameter user: Firebase 用户
    private func saveUserToFirestore(_ user: FirebaseAuth.User) {
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "displayName": user.displayName ?? "",
            "email": user.email ?? "",
            "lastLoginAt": FieldValue.serverTimestamp()
        ]
        db.collection("users").document(user.uid).setData(data, merge: true) { error in
            if let error {
                print("[AuthManager] 保存用户数据失败：\(error.localizedDescription)")
            }
        }
    }

    // MARK: - 辅助方法

    /// 生成指定长度的随机 nonce 字符串
    /// - Parameter length: 字符串长度，默认 32
    /// - Returns: 随机 nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }

            for random in randoms {
                if remainingLength == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    /// 对字符串进行 SHA256 哈希
    /// - Parameter input: 原始字符串
    /// - Returns: 哈希后的十六进制字符串
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
