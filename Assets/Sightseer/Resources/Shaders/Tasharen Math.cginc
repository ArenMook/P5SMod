#ifndef TASHAREN_MATH_INCLUDE
#define TASHAREN_MATH_INCLUDE

//==============================================================================================
// Helper function that calculates the world-space normal without the need of a tangent
//==============================================================================================

inline float3 UnpackNormal (sampler2D normalMapTexture, float3 worldNormal, float3 worldPosition, float2 uv)
{
	float3 dp1 = ddx(worldPosition);
	float3 dp2 = ddy(worldPosition) * _ProjectionParams.x;
	float2 duv1 = ddx(uv);
	float2 duv2 = ddy(uv) * _ProjectionParams.x;
	float3 dp2perp = cross(dp2, worldNormal);
	float3 dp1perp = cross(worldNormal, dp1);
	float3 T = dp2perp * duv1.x + dp1perp * duv2.x;
	float3 B = dp2perp * duv1.y + dp1perp * duv2.y;
	float invmax = rsqrt(max(dot(T, T), dot(B, B)));
	return mul(UnpackNormal(tex2D(normalMapTexture, uv)), float3x3(T * invmax, B * invmax, worldNormal));
}

//==============================================================================================
// Helper function that calculates the world-space normal without the need of a tangent
//==============================================================================================

inline float3 UnpackNormal (sampler2D normalMapTexture, float3 worldPosition, float2 uv)
{
	float3 dp1 = ddx(worldPosition);
	float3 dp2 = ddy(worldPosition) * _ProjectionParams.x;
	float3 worldNormal = normalize(cross(dp1, dp2));
	float2 duv1 = ddx(uv);
	float2 duv2 = ddy(uv) * _ProjectionParams.x;
	float3 dp2perp = cross(dp2, worldNormal);
	float3 dp1perp = cross(worldNormal, dp1);
	float3 T = dp2perp * duv1.x + dp1perp * duv2.x;
	float3 B = dp2perp * duv1.y + dp1perp * duv2.y;
	float invmax = rsqrt(max(dot(T, T), dot(B, B)));
	return mul(UnpackNormal(tex2D(normalMapTexture, uv)), float3x3(T * invmax, B * invmax, worldNormal));
}

//==============================================================================================
// Handy function that can transform the specified normal map's value into world space
//==============================================================================================

inline half3 TransformByTBN (half3 normalMap, half3 worldNormal, half3 worldTangent)
{
	half3 worldBinormal = cross(worldTangent, worldNormal);
	half3 tSpace0 = half3(worldTangent.x, worldBinormal.x, worldNormal.x);
	half3 tSpace1 = half3(worldTangent.y, worldBinormal.y, worldNormal.y);
	half3 tSpace2 = half3(worldTangent.z, worldBinormal.z, worldNormal.z);
	return half3(dot(tSpace0, normalMap), dot(tSpace1, normalMap), dot(tSpace2, normalMap));
}

//==============================================================================================
// Handy function that can transform the specified normal map's value into world space
//==============================================================================================

inline half3 TransformByTBN (half3 normalMap, half3 worldNormal, half3 worldTangent, half3 worldBinormal)
{
	half3 tSpace0 = half3(worldTangent.x, worldBinormal.x, worldNormal.x);
	half3 tSpace1 = half3(worldTangent.y, worldBinormal.y, worldNormal.y);
	half3 tSpace2 = half3(worldTangent.z, worldBinormal.z, worldNormal.z);
	return half3(dot(tSpace0, normalMap), dot(tSpace1, normalMap), dot(tSpace2, normalMap));
}

//==============================================================================================
// Given the sampled local normal, calculate the world-space normal
//==============================================================================================

inline float3 TransformByTBN2 (float3 normalMap, float3 worldNormal, float3 worldPosition, float2 uv)
{
	float3 dp1 = ddx(worldPosition);
	float3 dp2 = ddy(worldPosition) * _ProjectionParams.x;
	float2 duv1 = ddx(uv);
	float2 duv2 = ddy(uv) * _ProjectionParams.x;
	float3 dp2perp = cross(dp2, worldNormal);
	float3 dp1perp = cross(worldNormal, dp1);
	float3 T = dp2perp * duv1.x + dp1perp * duv2.x;
	float3 B = dp2perp * duv1.y + dp1perp * duv2.y;
	float invmax = rsqrt(max(dot(T, T), dot(B, B)));
	return mul(normalMap, float3x3(T * invmax, B * invmax, worldNormal));
}

//==============================================================================================
// Given the sampled local normal, calculate the world-space normal
//==============================================================================================

inline float3 TransformByTBN2 (float3 normalMap, float3 worldPosition, float2 uv)
{
	float3 dp1 = ddx(worldPosition);
	float3 dp2 = ddy(worldPosition) * _ProjectionParams.x;
	float3 worldNormal = normalize(cross(dp1, dp2));
	float2 duv1 = ddx(uv);
	float2 duv2 = ddy(uv) * _ProjectionParams.x;
	float3 dp2perp = cross(dp2, worldNormal);
	float3 dp1perp = cross(worldNormal, dp1);
	float3 T = dp2perp * duv1.x + dp1perp * duv2.x;
	float3 B = dp2perp * duv1.y + dp1perp * duv2.y;
	float invmax = rsqrt(max(dot(T, T), dot(B, B)));
	return mul(normalMap, float3x3(T * invmax, B * invmax, worldNormal));
}

//==============================================================================================
// Calculate the approximate pixel normal given its position.
// Note that this method is blocky, not precise, and won't work at depth discontinuities.
// It's also per-polygon, as there is no vertex blending.
// Doing a pass to render normals to a render texture is generally a much better approach.
//==============================================================================================

inline float3 CalculateNormal (float3 pos)
{
	return normalize(cross(ddx(pos), ddy(pos)));
}

//==============================================================================================
// Helper function that calculates the object's scaling without having to pass it to the shader
//==============================================================================================

inline float3 CalculateObjectScale ()
{
	float3 objX = float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x); //== mul((float3x3)scaleMat, half3(1, 0, 0));
	float3 objY = float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y); //== mul((float3x3)scaleMat, half3(0, 1, 0));
	float3 objZ = float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z); //== mul((float3x3)scaleMat, half3(0, 0, 1));
	return float3(length(objX), length(objY), length(objZ));
}

//==============================================================================================
// Given the normal, calculate the triplanar texture contribution
//==============================================================================================

inline half3 CalculateTriplanarContribution (half3 normal, half blendPower)
{
	half3 contribution = pow(saturate(abs(normalize(normal))), blendPower);
	return contribution / dot(contribution, 1.0);
}

//==============================================================================================
// Given the object space normal, calculate the vertex tangent.
//==============================================================================================

inline half4 CalculateTriplanarTangent (half3 normal, half blendPower)
{
	half3 signage = sign(normal);
	half3 contribution = CalculateTriplanarContribution(normal, blendPower);
	return half4(contribution.y, -signage.z * contribution.z, signage.x * contribution.x, -1.0);
}

//==============================================================================================
// Given the world space normal, calculate the vertex tangent.
//==============================================================================================

inline half4 CalculateTriplanarTangentFromWorldNormal (half3 normal, half blendPower)
{
	half4 tangent = CalculateTriplanarTangent(normal, blendPower);
	tangent.xyz = mul((float3x3)unity_WorldToObject, tangent.xyz);
	return tangent;
}

//==============================================================================================
// Read the specified texture using triplanar texture sampling
//==============================================================================================

inline half4 SampleTriplanar (sampler2D tex, half4 tc0, half4 tc1, half4 tc2, half3 signage, half3 contribution)
{
	return	lerp(tex2D(tex, tc0.xy), tex2D(tex, tc0.zw), signage.x) * contribution.x +
			lerp(tex2D(tex, tc1.xy), tex2D(tex, tc1.zw), signage.y) * contribution.y +
			lerp(tex2D(tex, tc2.xy), tex2D(tex, tc2.zw), signage.z) * contribution.z;
}
#endif
