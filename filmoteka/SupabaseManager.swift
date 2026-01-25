//
//  SupabaseManager.swift
//  filmoteka
//
//  Created by Aylin Hyusmen on 25.01.26.
//

import Foundation
import Supabase

class SupabaseManager {
    
    static let shared = SupabaseManager()
    let client: SupabaseClient
    
    private init() {
        
        let supabaseURL = URL(string: "https://zbifwkwqkfcfjsvspvxp.supabase.co")!
        let supabaseKey = "sb_publishable_p3RPd73cVkYoleli8eQzmg_XYrBiY4V"
        
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
    
    func signUp(email: String, password: String) async throws {
        try await client .auth.signUp(email: email, password: password)
    }
    
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }
    
}
