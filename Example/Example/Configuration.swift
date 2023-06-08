//
//  Configuration.swift
//  Example
//
//  Created by James Wolfe on 07/06/2023.
//

import Foundation
import AuthKit

class Configuration {
    
    static let clientID: String = Bundle.main.object(forInfoDictionaryKey: "client_id") as! String
    static let clientSecret: String = Bundle.main.object(forInfoDictionaryKey: "client_secret") as! String
    static let url: URL = .init(string: Bundle.main.object(forInfoDictionaryKey: "url") as! String)!
    static let auth = AuthKit(bundle: Bundle.main.bundleIdentifier!, prompt: NSLocalizedString("ContentView.RefreshPrompt.Text", comment: ""), method: .featherweight, baseURL: url)
}
