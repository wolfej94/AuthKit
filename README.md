# AuthKit

AuthKit is a powerful authentication framework that provides easy-to-use methods for user authentication in your iOS application. It supports various authentication methods such as OAuth, Featherweight, and basic authentication.

## Features

- Authenticate users using email and password with OAuth, Featherweight, or basic authentication methods.
- Reauthenticate users using OAuth refresh tokens.
- Unauthenticate users and clear their session.
- Generate and manage RSA key pairs for code verification.
- Sign code challenge strings using RSA keys.
- Set bearer tokens manually for custom authentication scenarios.

## Installation

You can install AuthKit using Swift Package Manager. Follow these steps:

1. In Xcode, open your project.
2. Go to "File" -> "Swift Packages" -> "Add Package Dependency".
3. Paste the following URL: `https://github.com/wolfej94/AuthKit`.
4. Click "Next" and select the desired version rule.
5. Click "Next" and then "Finish".
6. Import AuthKit in your Swift files: `import AuthKit`.

## Usage

### Initialization

To get started with AuthKit, initialize an instance of the `AuthKit` class with your desired configuration:

```swift
let bundle = "com.yourapp.bundle"
let prompt = "Enter your passphrase"
let method = AuthenticationMethod.basic
let baseURL = URL(string: "https://example.com")!

let authKit = AuthKit(bundle: bundle, prompt: prompt, method: method, baseURL: baseURL)
```

### Authentication

Authenticate a user by providing their email and password:

```swift
let path = "/api/login"
let email = "test@example.com"
let password = "secretpassword"

try authKit.authenticate(path: path, email: email, password: password)
```

### Reauthentication

Reauthenticate a user using OAuth refresh tokens:

```swift
let path = "/api/refresh-token"

try authKit.reauthenticate(path: path)
```

### Unauthentication

Unauthenticate a user and clear their session:

```swift
try authKit.unauthenticate()
```

### RSA Key Pair Generation

Generate a new RSA key pair for code verification:

```swift
let publicKey = try authKit.generateKeyPair()
```

### Code Challenge Signing

Sign a code challenge string using the RSA key pair:

```swift
let challenge = "examplechallenge"
let signedChallenge = try authKit.sign(challenge: challenge)
```

### Manual Bearer Token Setting

Manually set the bearer token for custom authentication scenarios:

```swift
let token = "your-bearer-token"
try authKit.setBearerToken(to: token)
```

## Contributing

We welcome contributions to improve AuthKit and make it even more powerful and user-friendly. If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request on [GitHub](https://github.com/wolfej94/AuthKit).

## License

AuthKit is released under the [MIT License](https://opensource.org/licenses/MIT). See [LICENSE](https://github.com/wolfej94/AuthKit/blob/main/LICENSE) for details.

## Credits

AuthKit is created and maintained by [James Wolfe](https://github.com/wolfej94).

## Acknowledgements

We would like to thank the following open-source projects for their inspiration and contributions:

- [Valet](https://github.com/square/Valet) - Secure storage for Swift.
- [NetShears](https://github.com/divar-ir/NetShears) - Network request interception library.

## Contact

For any inquiries or questions, please contact [James Wolfe](mailto:james.wolfe94@outlook.com).
