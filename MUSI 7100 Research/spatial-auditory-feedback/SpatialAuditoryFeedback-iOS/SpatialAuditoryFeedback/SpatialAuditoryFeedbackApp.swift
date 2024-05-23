//
// Copyright (C) 2024 Evan Murray
//
// SpatialAuditoryFeedbackApp.swift
// SpatialAuditoryFeedback
// Created by Evan Murray on 4/7/24.
//
// This file is part of SpatialAuditoryFeedback.
//
// SpatialAuditoryFeedback is an application designed to map descriptors of joint position to parameters in ambisonics renderers.
//
// SpatialAuditoryFeedback is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// SpatialAuditoryFeedback is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with SpatialAuditoryFeedback. If not, see <https://www.gnu.org/licenses/>.
//


import SwiftUI
import SwiftData

@main
struct SpatialAuditoryFeedbackApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
