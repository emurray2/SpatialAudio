/**
 The base coordinator class that conforms to `MTKViewDelegate`. Subclasses can override:
 - `preparePipelineAndDepthState()` - to create a pipeline descriptor with the required vertex and fragment
                                      function to create a `pipelineState` and `depthState` if necessary.
- `draw()` - to perform the drawing operation.
 */
// Full code available at: https://developer.apple.com/documentation/avfoundation/additional_data_capture/capturing_depth_using_the_lidar_camera
//
// Copyright © 2023 Apple Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


import MetalKit

class MTKCoordinator<MTKViewRepresentable: MetalRepresentable>: NSObject, MTKViewDelegate {

    weak var mtkView: MTKView!

    var pipelineState: MTLRenderPipelineState!
    var metalCommandQueue: MTLCommandQueue
    var depthState: MTLDepthStencilState!
    var parent: MTKViewRepresentable

    init(parent: MTKViewRepresentable) {
        self.parent = parent
        self.metalCommandQueue = MetalEnvironment.shared.metalCommandQueue
        super.init()
    }

    /// Saves a reference to the `MTKView` in the coordinator and sets up the default settings.
    func setupView(mtkView: MTKView) {
        self.mtkView = mtkView
        self.mtkView.preferredFramesPerSecond = 60
        self.mtkView.isOpaque = true
        self.mtkView.framebufferOnly = false
        self.mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        self.mtkView.drawableSize = mtkView.frame.size
        self.mtkView.enableSetNeedsDisplay = false
        self.mtkView.colorPixelFormat = .bgra8Unorm
        self.mtkView.depthStencilPixelFormat = .depth32Float
        self.mtkView.contentMode = .scaleAspectFit
        self.mtkView.device = MetalEnvironment.shared.metalDevice
        preparePipelineAndDepthState()
    }

    /// The app uses a quad to draw a texture onscreen. It creates an `MTLVertexDescriptor` for this case.
    func createPlaneMetalVertexDescriptor() -> MTLVertexDescriptor {
        let mtlVertexDescriptor: MTLVertexDescriptor = MTLVertexDescriptor()
        // Store position in `attribute[[0]]`.
        mtlVertexDescriptor.attributes[0].format = .float2
        mtlVertexDescriptor.attributes[0].offset = 0
        mtlVertexDescriptor.attributes[0].bufferIndex = 0

        // Store texture coordinates in `attribute[[1]]`.
        mtlVertexDescriptor.attributes[1].format = .float2
        mtlVertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        mtlVertexDescriptor.attributes[1].bufferIndex = 0

        // Set stride to twice the `float2` bytes per vertex.
        mtlVertexDescriptor.layouts[0].stride = 2 * MemoryLayout<SIMD2<Float>>.stride
        mtlVertexDescriptor.layouts[0].stepRate = 1
        mtlVertexDescriptor.layouts[0].stepFunction = .perVertex

        return mtlVertexDescriptor
    }

    func preparePipelineAndDepthState() {}

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Override in subclass.
    }

    func draw(in view: MTKView) {
        // Override in subclass.
    }
}
