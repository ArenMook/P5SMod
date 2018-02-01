#ifndef TASHAREN_LIGHTING_INCLUDE
#define TASHAREN_LIGHTING_INCLUDE

#include "UnityPBSLighting.cginc"
#include "Tasharen Dither.cginc"

// Change GI term's intensity using this define:
#ifndef GI_INTENSITY
#define GI_INTENSITY 0.75
#endif

// The closer to 1, the more blurred the sampled cube texture will be
#ifndef GI_BLUR
#define GI_BLUR 0.9
#endif

// Makes it possible to adjust the calculated dot product between the normal and the light's direction
#ifndef ADJUST_NDOTL
#define ADJUST_NDOTL(ndotl)
#endif
	
//==============================================================================================
// Define a custom cubemap for indirect illumination: #define GI_SOURCE <texture>
// To blend indirect lighting from multiple probes, #define BLEND_ENVIRONMENT
//==============================================================================================

#if !defined(GI_SOURCE) && !defined(GI_SOURCE0)

	#define GI_SOURCE0 unity_SpecCube0
	#define GI_SOURCE1 unity_SpecCube1

	#ifndef DECODE_HDR0
	#define DECODE_HDR0(col) DecodeHDR(col, unity_SpecCube0_HDR).rgb
	#endif

	#ifndef DECODE_HDR1
	#define DECODE_HDR1(col) DecodeHDR(col, unity_SpecCube1_HDR).rgb
	#endif

#else

	#ifndef GI_SOURCE0
	#define GI_SOURCE0 GI_SOURCE
	#endif

	UNITY_DECLARE_TEXCUBE(GI_SOURCE0);

	#ifndef GI_SOURCE1
	#define GI_SOURCE1 GI_SOURCE0
	#else
	UNITY_DECLARE_TEXCUBE_NOSAMPLER(GI_SOURCE1);
	#endif

	#ifndef DECODE_HDR0
	#define DECODE_HDR0(col) col.rgb
	#endif

	#ifndef DECODE_HDR1
	#define DECODE_HDR1(col) col.rgb
	#endif

#endif

//==============================================================================================
// Default output data structure.
// Replace with a custom one by using this define prior to including CW.cginc:
// #define OUTPUT Output
//==============================================================================================

#ifndef OUTPUT
#define OUTPUT Output

struct Output
{
	half3 Albedo;
	half4 Specular;
	half3 Normal;
	half3 Emission;
	half Smoothness;
	half Occlusion;
	half Alpha;
};
#endif

//==============================================================================================
// Sample the specular cubemap created by the reflection probe, blur it and use it as diffuse.
//==============================================================================================

inline half3 SampleDiffuseTerm (half3 normalWorld)
{
#ifdef GI_SINGLE_SAMPLE
	// Fast, imprecise version:
	half4 diffuse = UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, normalWorld, GI_BLUR * UNITY_SPECCUBE_LOD_STEPS);
#else
	// Smoother but slower version:
	half3 right = normalize(cross(half3(0.0, 1.0, 0.0), normalWorld));
	half3 up = normalize(cross(normalWorld, right));
	const half sampleFactor = GI_BLUR * UNITY_SPECCUBE_LOD_STEPS;
	const half jitterFactor = 0.3;
	
	half4 diffuse = (UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, normalWorld, sampleFactor) +
		UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, lerp(normalWorld,  up, jitterFactor), sampleFactor) +
		UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, lerp(normalWorld, -up, jitterFactor), sampleFactor) +
		UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, lerp(normalWorld,  right, jitterFactor), sampleFactor) +
		UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, lerp(normalWorld, -right, jitterFactor), sampleFactor)) * 0.2;
#endif
	return DECODE_HDR0(diffuse) * GI_INTENSITY;
}

//==============================================================================================
// Sample the specular cubemap created by the reflection probe, blur it and use it as diffuse.
//==============================================================================================

inline half3 SampleDiffuseTerm (half3 normalWorld, UnityGIInput data)
{
#ifdef GI_SINGLE_SAMPLE
	half4 diffuse0 = UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, normalWorld, GI_BLUR * UNITY_SPECCUBE_LOD_STEPS);
#else
	half3 right = normalize(cross(half3(0.0, 1.0, 0.0), normalWorld));
	half3 up = normalize(cross(normalWorld, right));
	const float sampleFactor = GI_BLUR * UNITY_SPECCUBE_LOD_STEPS;
	const float jitterFactor = 0.3;
	
	half4 diffuse0 = (UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, normalWorld, sampleFactor) +
		UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, lerp(normalWorld,  up, jitterFactor), sampleFactor) +
		UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, lerp(normalWorld, -up, jitterFactor), sampleFactor) +
		UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, lerp(normalWorld,  right, jitterFactor), sampleFactor) +
		UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, lerp(normalWorld, -right, jitterFactor), sampleFactor)) * 0.2;
#endif

#if defined(BLEND_ENVIRONMENT) && defined(UNITY_SPECCUBE_BLENDING)
	half blendLerp = data.boxMin[0].w;
	
	UNITY_BRANCH
	if (blendLerp < 0.99999)
	{
#ifdef GI_SINGLE_SAMPLE
		half4 diffuse1 = (UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE1, normalWorld, sampleFactor) +
			UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE1, lerp(normalWorld,  up, jitterFactor), sampleFactor) +
			UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE1, lerp(normalWorld, -up, jitterFactor), sampleFactor) +
			UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE1, lerp(normalWorld,  right, jitterFactor), sampleFactor) +
			UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE1, lerp(normalWorld, -right, jitterFactor), sampleFactor)) * 0.2;
#else
		half4 diffuse1 = UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE1, normalWorld, GI_BLUR * UNITY_SPECCUBE_LOD_STEPS);
#endif
		return lerp(DECODE_HDR1(diffuse1), DECODE_HDR0(diffuse0), blendLerp) * GI_INTENSITY;
	}
#endif
	return DECODE_HDR0(diffuse0) * GI_INTENSITY;
}

//==============================================================================================
// Global Illumination -- diffuse pass, based on BRDF1_Unity_PBS
//==============================================================================================

inline UnityGI TasharenGI_Base (UnityGIInput data, half3 normalWorld)
{
	UnityGI gi;
	ResetUnityGI(gi);

#ifndef LIGHTMAP_ON
	gi.light = data.light;
	gi.light.color *= data.atten;
#endif

#if UNITY_SHOULD_SAMPLE_SH
 #ifdef UNITY_GI_MODEL
	// This flat out doesn't work when a skybox-based ambient lighting is used with the skybox updated at run-time
	gi.indirect.diffuse = ShadeSHPerPixel (normalWorld, data.ambient, data.worldPos);
 #else
	// This gives similar results and also happens to work properly
	//gi.indirect.diffuse = UNITY_SAMPLE_TEXCUBE_LOD(GI_SOURCE0, normalWorld, 0.8 * UNITY_SPECCUBE_LOD_STEPS).rgb;
	
	// An even smoother version using 5 samples instead of 1, also closer matching the ShadeSHPerPixel result.
	gi.indirect.diffuse = SampleDiffuseTerm(normalWorld, data);
 #endif
#endif

#ifdef LIGHTMAP_ON
	half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lightmapUV.xy);
	half3 bakedColor = DecodeLightmap(bakedColorTex);

 #ifdef DIRLIGHTMAP_OFF
	gi.indirect.diffuse = bakedColor;

 #ifdef SHADOWS_SCREEN
	gi.indirect.diffuse = MixLightmapWithRealtimeAttenuation (gi.indirect.diffuse, data.atten, bakedColorTex);
 #endif

 #elif DIRLIGHTMAP_COMBINED
	half4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, data.lightmapUV.xy);
	gi.indirect.diffuse = DecodeDirectionalLightmap (bakedColor, bakedDirTex, normalWorld);

 #ifdef SHADOWS_SCREEN
	gi.indirect.diffuse = MixLightmapWithRealtimeAttenuation (gi.indirect.diffuse, data.atten, bakedColorTex);
 #endif

 #elif DIRLIGHTMAP_SEPARATE
	half4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, data.lightmapUV.xy);
	gi.indirect.diffuse = DecodeDirectionalSpecularLightmap (bakedColor, bakedDirTex, normalWorld, false, 0, gi.light);

	half2 uvIndirect = data.lightmapUV.xy + half2(0.5, 0);
	bakedColor = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, uvIndirect));
	bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, uvIndirect);
	gi.indirect.diffuse += DecodeDirectionalSpecularLightmap (bakedColor, bakedDirTex, normalWorld, false, 0, gi.light2);
 #endif
#endif

#ifdef DYNAMICLIGHTMAP_ON
	half4 realtimeColorTex = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, data.lightmapUV.zw);
	half3 realtimeColor = DecodeRealtimeLightmap (realtimeColorTex);

 #ifdef DIRLIGHTMAP_OFF
	gi.indirect.diffuse += realtimeColor;
 #elif DIRLIGHTMAP_COMBINED
	half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, data.lightmapUV.zw);
	gi.indirect.diffuse += DecodeDirectionalLightmap (realtimeColor, realtimeDirTex, normalWorld);
 #elif DIRLIGHTMAP_SEPARATE
	half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, data.lightmapUV.zw);
	half4 realtimeNormalTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicNormal, unity_DynamicLightmap, data.lightmapUV.zw);
	gi.indirect.diffuse += DecodeDirectionalSpecularLightmap (realtimeColor, realtimeDirTex, normalWorld, true, realtimeNormalTex, gi.light3);
 #endif
#endif
	return gi;
}

//==============================================================================================
// Global illumination -- specular pass
//==============================================================================================

inline half3 TasharenGI_IndirectSpecular (UnityGIInput data, half occlusion, half3 normalWorld, Unity_GlossyEnvironmentData glossIn)
{
#if UNITY_SPECCUBE_BOX_PROJECTION
	half3 originalReflUVW = glossIn.reflUVW;
#endif

#if UNITY_SPECCUBE_BOX_PROJECTION
	glossIn.reflUVW = BoxProjectedCubemapDirection (originalReflUVW, data.worldPos, data.probePosition[0], data.boxMin[0], data.boxMax[0]);
#endif

	half3 specular = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE(GI_SOURCE0), data.probeHDR[0], glossIn);

#if UNITY_SPECCUBE_BLENDING
	half blendLerp = data.boxMin[0].w;
	
	UNITY_BRANCH
	if (blendLerp < 0.99999)
	{
	#if UNITY_SPECCUBE_BOX_PROJECTION
		glossIn.reflUVW = BoxProjectedCubemapDirection (originalReflUVW, data.worldPos, data.probePosition[1], data.boxMin[1], data.boxMax[1]);
	#endif

		half3 env1 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE_SAMPLER(GI_SOURCE1, GI_SOURCE0), data.probeHDR[1], glossIn);
		specular = lerp(env1, specular, blendLerp);
	}
#endif
	return specular * occlusion;
}

//==============================================================================================
// Custom BRDF
//==============================================================================================

#ifndef BRDF
#define BRDF TasharenBRDF

half4 TasharenBRDF (half3 diffColor, half4 specColor, half oneMinusReflectivity, half oneMinusRoughness, half3 normal, half3 viewDir,
	UnityLight light, UnityIndirect gi)
{
	half roughness = 1.0 - oneMinusRoughness;
	half3 halfDir = Unity_SafeNormalize (light.dir + viewDir);

#if UNITY_BRDF_GGX 
	// This shift causes seriously weird lighting on double-sided geometry
	//half shiftAmount = dot(normal, viewDir);
	//normal = shiftAmount < 0.0f ? normal + viewDir * (-1e-5f) : normal;
	half nl = DotClamped(normal, light.dir);
#else
	half nl = light.ndotl;
#endif

	ADJUST_NDOTL(nl);

	half nh = BlinnTerm (normal, halfDir);
	half nv = DotClamped(normal, viewDir);
	half lv = DotClamped(light.dir, viewDir);
	half lh = DotClamped(light.dir, halfDir);

#if UNITY_BRDF_GGX
	half V = SmithJointGGXVisibilityTerm (nl, nv, roughness);
	half D = GGXTerm (nh, roughness);
#else
	half V = SmithBeckmannVisibilityTerm (nl, nv, roughness);
	half D = NDFBlinnPhongNormalizedTerm (nh, RoughnessToSpecPower (roughness));
#endif

	half nlPow5 = Pow5(1.0 - nl);
	half nvPow5 = Pow5(1.0 - nv);
	half Fd90 = 0.5 + 2.0 * lh * lh * roughness;
	half disneyDiffuse = (1.0 + (Fd90 - 1.0) * nlPow5) * (1.0 + (Fd90 - 1.0) * nvPow5);
	half specularTerm = (V * D) * 0.7853981633975; // Pi/4
	half realRoughness = roughness*roughness;
	half surfaceReduction;
	
	if (IsGammaSpace())
	{
		specularTerm = sqrt(max(1e-4h, specularTerm));
		surfaceReduction = 1.0 - 0.28 * realRoughness * roughness;
	}
	else surfaceReduction = 1.0 / (realRoughness * realRoughness + 1.0);

	specularTerm = max(0.0, specularTerm * specColor.a * specColor.a * nl);

	half diffuseTerm = disneyDiffuse * nl;
	half grazingTerm = saturate(oneMinusRoughness * specColor.a + (1.0 - oneMinusReflectivity));
	return half4(diffColor * (gi.diffuse + light.color * diffuseTerm) +
		light.color * (FresnelTerm (specColor.rgb, lh) * specularTerm * _LightColor0.a) +
		surfaceReduction * gi.specular * FresnelLerp (specColor.rgb, grazingTerm, nv) * specColor.a, 1.0);
}
#endif

//==============================================================================================
// Global illumination function.
// Replace with a custom one by using this define prior to including Tasharen Lighting.cginc:
// #define LIGHTING_GI LightingTasharen_GI
//==============================================================================================

#ifndef LIGHTING_GI
#define LIGHTING_GI LightingTasharen_GI

inline void LightingTasharen_GI (OUTPUT s, UnityGIInput data, inout UnityGI gi)
{
	// Basic GI
	gi = TasharenGI_Base(data, s.Normal);

	// Specular GI
	Unity_GlossyEnvironmentData env;
	env.roughness = 1.0 - s.Smoothness;
	env.reflUVW = reflect(-data.worldViewDir, s.Normal);
	gi.indirect.specular = TasharenGI_IndirectSpecular(data, s.Occlusion, s.Normal, env);
}
#endif

//==============================================================================================
// Primary lighting function.
// Replace with a custom one by using this define prior to including Tasharen Lighting.cginc:
// #define LIGHTING LightingTasharen
//==============================================================================================

#ifndef LIGHTING
#define LIGHTING LightingTasharen

inline half4 LightingTasharen (OUTPUT s, half3 viewDir, UnityGI gi)
{
	s.Normal = normalize(s.Normal);

	half oneMinusReflectivity;
	s.Albedo = EnergyConservationBetweenDiffuseAndSpecular (s.Albedo, s.Specular.rgb, oneMinusReflectivity);

	half outputAlpha;
	s.Albedo = PreMultiplyAlpha (s.Albedo, s.Alpha, oneMinusReflectivity, outputAlpha);

	half4 c = BRDF (s.Albedo, s.Specular, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);
	c.rgb += UNITY_BRDF_GI (s.Albedo, s.Specular.rgb, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, s.Occlusion, gi);
	c.a = outputAlpha;
	return c;
}
#endif
#endif
