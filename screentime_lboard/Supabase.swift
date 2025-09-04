//
//  Supabase.swift
//  screentime_lboard
//
//  Created following official Supabase iOS documentation
//

import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://dhwgtpetoqvlwfixrfjz.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRod2d0cGV0b3F2bHdmaXhyZmp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwMjQ3NTUsImV4cCI6MjA3MjYwMDc1NX0.onHfEd7gEQmliSwGPADNwl2D4bgA9G4nSZdj-Hua-X0"
)