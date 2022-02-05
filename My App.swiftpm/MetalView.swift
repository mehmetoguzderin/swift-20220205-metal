import MetalKit
import SwiftUI

let metalLibrary = """
fragment half4 tileShader() {
    return half4(0, 0, 1, 1);
}
"""

struct MetalView: UIViewRepresentable {
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: MetalView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var library: MTLLibrary!
        var function: MTLFunction!
        var pipeline: MTLRenderPipelineState? = nil
        init(_ parent: MetalView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.device = metalDevice
            }
            if let metalCommandQueue = device.makeCommandQueue() {
                self.commandQueue = metalCommandQueue
            }
            do {
                self.library = try self.device.makeLibrary(source: metalLibrary, options: .none)
                self.function = self.library.makeFunction(name: "tileShader")!
                let descriptor = MTLTileRenderPipelineDescriptor()
                descriptor.tileFunction = self.function
                descriptor.threadgroupSizeMatchesTileSize = true
                descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.rgba16Float
                self.pipeline = try device.makeRenderPipelineState(tileDescriptor: descriptor, options: MTLPipelineOption(), reflection: nil)
            } catch {
                print("\(error)")
            }
            super.init()
        }
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable else {
                return
            }
            if let commandBuffer = commandQueue.makeCommandBuffer() {
                if let renderPassDescriptor = view.currentRenderPassDescriptor {
                    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 1, 1)
                    renderPassDescriptor.colorAttachments[0].loadAction = .load
                    renderPassDescriptor.colorAttachments[0].storeAction = .store
                    if let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                        if let renderPipeline = self.pipeline {
                            renderCommandEncoder.setCullMode(.back)
                            renderCommandEncoder.setFrontFacing(.counterClockwise)
                            renderCommandEncoder.setRenderPipelineState(renderPipeline)
                            renderCommandEncoder.dispatchThreadsPerTile(MTLSize(width: renderCommandEncoder.tileWidth, height: renderCommandEncoder.tileHeight, depth: 1))
                        }
                        renderCommandEncoder.endEncoding()
                    }
            commandBuffer.present(drawable)
            commandBuffer.commit()
                }
            }
        }
    }
    static func makeView() -> MTKView {
        let mtkView = MTKView()
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.colorPixelFormat = MTLPixelFormat.rgba16Float
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
        return mtkView
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIView(context: UIViewRepresentableContext<MetalView>) -> MTKView {
        let mtkView = MetalView.makeView()
        mtkView.delegate = context.coordinator
        return mtkView
    }
    func updateUIView(_ nsView: MTKView, context: UIViewRepresentableContext<MetalView>) {
    }
}
