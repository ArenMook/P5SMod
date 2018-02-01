#ifndef TASHAREN_DEPTH_CGINC
#define TASHAREN_DEPTH_CGINC

#include "UnityCG.cginc"

#ifndef DEPTH_TEX
#define DEPTH_TEX _CameraDepthTexture
#endif

uniform sampler2D_float DEPTH_TEX;

// Set via code like so:
// mMat.SetMatrix("_ViewProjectInverse", (mCam.projectionMatrix * mCam.worldToCameraMatrix).inverse);
uniform float4x4 _ViewProjectInverse;

// The 'uv' are expected to be image effect UVs (screen space)
inline float3 GetWorldPos (float2 uv, float depth)
{
	float4 v = mul(_ViewProjectInverse, float4(uv * 2.0 - 1.0, depth, 1.0));
	return v.xyz / v.w;
}

// The 'uv' are expected to be image effect UVs (screen space)
inline float3 GetWorldPos (float2 uv)
{
	float depth = SAMPLE_DEPTH_TEXTURE(DEPTH_TEX, uv);
	return GetWorldPos(uv, depth);
}
#endif
