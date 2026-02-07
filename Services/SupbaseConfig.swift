//
//  SupbaseConfig.swift
//  AzChat
//
//  Created by Amal  on 19/08/1447 AH.
//

import Foundation
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    
    private init() {
        // ضع المفاتيح من Supabase Dashboard → Settings → API
        let supabaseURL = URL(string: "https://arwotczbkueqzsttneux.supabase.co")!
        let supabaseKey = "sb_publishable_rs_gInOYL6IPpcLBUt2LLQ_BNcM_B2O" // الصق المفتاح الذي نسخته
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}
