// Jet color shader code for displaying depth map
// Full code available at: https://developer.apple.com/documentation/avfoundation/additional_data_capture/capturing_depth_using_the_lidar_camera
//
// Copyright © 2023 Apple Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#include <metal_stdlib>

using namespace metal;

typedef struct
{
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

// Display a 2D texture.
vertex ColorInOut planeVertexShader(Vertex in [[stage_in]])
{
    ColorInOut out;
    out.position = float4(in.position, 0.0f, 1.0f);
    out.texCoord = in.texCoord;
    return out;
}

// Convert a color value to RGB using a Jet color scheme.
static half4 getJetColorsFromNormalizedVal(half val) {
    half4 res ;
    if(val <= 0.01h)
        return half4();
    res.r = 1.5h - fabs(4.0h * val - 3.0h);
    res.g = 1.5h - fabs(4.0h * val - 2.0h);
    res.b = 1.5h - fabs(4.0h * val - 1.0h);
    res.a = 1.0h;
    res = clamp(res,0.0h,1.0h);
    return res;
}

fragment half4 planeFragmentShaderColorZap(ColorInOut in [[stage_in]],
                                           texture2d<half> colorYTexture [[ texture(0) ]],
                                           texture2d<half> colorCbCrTexture [[ texture(1) ]],
                                           texture2d<float> depthTexture [[ texture(2) ]],
                                           constant float &minDepth [[buffer(0)]],
                                           constant float &maxDepth [[buffer(1)]],
                                           constant float &globalMaxDepth [[buffer(2)]]
                                           )
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    half y = colorYTexture.sample(textureSampler, in.texCoord).r;
    half2 uv = colorCbCrTexture.sample(textureSampler, in.texCoord).rg - half2(0.5h, 0.5h);
    // Convert YUV to RGB inline.
    half4 rgbaResult = half4(y + 1.402h * uv.y, y - 0.7141h * uv.y - 0.3441h * uv.x, y + 1.772h * uv.x, 1.0h);
    float depth = depthTexture.sample(textureSampler, in.texCoord).r;
    if(depth > minDepth && depth < maxDepth)
    {
        half normDepth = (depth-minDepth)/(globalMaxDepth-minDepth);
        rgbaResult = rgbaResult * 0.5 + 0.5 * getJetColorsFromNormalizedVal(normDepth);
    }
    else if (depth>maxDepth && depth < maxDepth*1.1  )
    {
        rgbaResult = rgbaResult * 2 ;
    }
    return rgbaResult;
}
