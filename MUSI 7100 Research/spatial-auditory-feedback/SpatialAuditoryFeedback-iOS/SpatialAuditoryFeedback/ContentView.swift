//
// Copyright (C) 2024 Evan Murray
//
// ContentView.swift
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

struct ContentView: View {
    @StateObject private var camera = CameraManager()
    @Environment(\.modelContext) private var modelContext
    @State private var maxDepth = Float(5.0)
    @State private var minDepth = Float(0.0)
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            VStack {
                SliderDepthBoundaryView(val: $maxDepth, label: "Max Depth", minVal: 0.0, maxVal: 15.0)
                SliderDepthBoundaryView(val: $minDepth, label: "Min Depth", minVal: 0.0, maxVal: 15.0)
                MetalTextureColorZapView(
                    rotationAngle: rotationAngle,
                    maxDepth: $maxDepth,
                    minDepth: $minDepth,
                    capturedData: camera.capturedData
                )
                .aspectRatio(calcAspect(orientation: viewOrientation, texture: camera.capturedData.depth), contentMode: .fit)
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
