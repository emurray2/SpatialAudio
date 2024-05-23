//
// Copyright (C) 2024 Evan Murray
//
// PoseDetector.swift
// SpatialAuditoryFeedback
// Created by Evan Murray on 4/18/24.
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


import Foundation
import OSCKit
import Vision
import AVFoundation

class PoseDetector {
    // Create OSC client and OSC server for sending control data
    private let oscClient = OSCClient()
    private let oscServer = OSCServer(port: 3001)
    // Create a request to detect a body pose in 3D space.
    private let request = VNDetectHumanBodyPose3DRequest()

    init() {
        do { try oscServer.start() } catch { print(error) }
        do { try oscClient.start() } catch { print(error) }
    }

    func mapPoseToPanning(cmSampleBuffer: CMSampleBuffer, depthData: AVDepthData) {
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: cmSampleBuffer, depthData: depthData, orientation: .up)
        do {
            // Perform the body pose request.
            try requestHandler.perform([request])

            // Get the observation.
            if let observation = request.results?.first {
                guard let childPosition = try? observation.recognizedPoint(.leftWrist).localPosition else { return }
                let translationChild = simd_make_float3(childPosition.columns.3[0],
                                                        childPosition.columns.3[1],
                                                        childPosition.columns.3[2])

                // The rotation around the x-axis.
                var pitch = (Float.pi / 2)

                // The rotation around the y-axis.
                var yaw = acos(translationChild.z / simd_length(translationChild))

                // The rotation around the z-axis.
                var roll = atan2((translationChild.y), (translationChild.x))

                // Convert to degrees for SceneRotator IEM plugin: https://plugins.iem.at/docs/scenerotator/
                pitch = pitch * (180 / Float.pi)
                roll = roll * (180 / Float.pi)
                yaw = yaw * (180 / Float.pi)
                if pitch.isNaN { pitch = 0.0 }
                if roll.isNaN { roll = 0.0 }
                if yaw.isNaN { yaw = 0.0 }

                let message = OSCMessage("/SceneRotator/ypr", values: OSCValues([yaw, pitch, roll]))

                do {
                    try oscClient.send(message, to: "192.168.1.7", port: 3001)
                } catch let err {
                    print(err.localizedDescription)
                }
            }
        } catch {
            print("Unable to perform the request: \(error).")
        }
    }
}
