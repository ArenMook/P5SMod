// NOTE: I think this shader is obsolete with Unity 5.6's changes to the particle system

Shader "Tasharen/Particles/Normal Mapped"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NormalMap ("Normalmap", 2D) = "bump" {}
		_Color ("Color", Color) = (1,1,1,1)
		_Brightness ("Brightness", Range(0.0, 10.0)) = 1.0
		_InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0
		_FadeDistance ("Near Clip Fade", Range(0.01, 10.0)) = 0.5
		//_FadeStart ("Fade Start", Float) = 100.0
		//_FadeEnd ("Fade End", Float) = 200.0
	}

	CGINCLUDE
	#define GI_INTENSITY 2.0
	#define ATTEN_BRIGHTNESS 2.0

	#include "Tasharen Lighting.cginc"
	#include "Tasharen Math.cginc"
	#include "AutoLight.cginc"

	sampler2D _MainTex;
	float4 _MainTex_ST;
	sampler2D _NormalMap;
	sampler2D_float _CameraDepthTexture;
	half4 _Color;
	half _Brightness;
	half _FadeDistance, _InvFade;
	//half _FadeStart, _FadeEnd, TOD_Fogginess;

	//==============================================================================================

	struct appdata_t 
	{
		float4 vertex	: POSITION;
		half4 color		: COLOR;
		float2 uv		: TEXCOORD0;
		float3 normal	: NORMAL;
	};

	struct v2f 
	{
		float4 vertex	: SV_POSITION;
		half4 color		: COLOR;
		float2 uv		: TEXCOORD0;
		float4 pos		: TEXCOORD1;
		float3 normal	: TEXCOORD2;
	//#ifdef SOFTPARTICLES_ON
		float4 projPos	: TEXCOORD3;
	//#endif
		//UNITY_FOG_COORDS(4)
		LIGHTING_COORDS(5, 6)
	};

	//==============================================================================================

	//inline half DistanceFade (half fadeDistEnd, half fadeDistStart, float3 worldPos)
	//{
	//	fadeDistStart = fadeDistStart - fadeDistStart * 0.5 * TOD_Fogginess;
	//	fadeDistEnd = fadeDistEnd - fadeDistEnd * 0.25 * TOD_Fogginess;
	//	half fadeDistance = distance(_WorldSpaceCameraPos, worldPos) - fadeDistEnd;
	//	return saturate(fadeDistance / (fadeDistStart - fadeDistEnd));
	//}

	//==============================================================================================

	v2f vert (appdata_t v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);

	//#ifdef SOFTPARTICLES_ON
		o.projPos = ComputeScreenPos(o.vertex);
		COMPUTE_EYEDEPTH(o.projPos.z);
	//#endif

		o.pos = mul(unity_ObjectToWorld, v.vertex);
		o.color = v.color;
		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		o.normal = v.normal;

		// Fade out the closer it is to the near clip plane.
		o.color.a *= saturate((-UnityObjectToViewPos(v.vertex).z - _ProjectionParams.y) / _FadeDistance);

		// Distance-based fade
		//o.color.a *= DistanceFade(_FadeEnd, _FadeStart, mul(unity_ObjectToWorld, v.vertex).xyz);

		TRANSFER_VERTEX_TO_FRAGMENT(o);
		//UNITY_TRANSFER_FOG(o, o.vertex);
		return o;
	}
	ENDCG

	Subshader
	{
		LOD 200
		Tags
		{
			"Queue"="Transparent"
			"IgnoreProjector"="True"
			"RenderType"="Transparent"
			"PreviewType" = "Plane"
		}

		Blend SrcAlpha OneMinusSrcAlpha
		Cull Back
		Lighting Off
		ZWrite Off

		//==============================================================================================
		// Base forward pass -- used by the main directional light
		//==============================================================================================

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile_particles
			#pragma multi_compile_fog
			#pragma target 4.0

			half4 frag (v2f IN) : SV_Target
			{
				half4 tex = tex2D(_MainTex, IN.uv);
				half4 c = IN.color * _Color;
				c.a *= tex.a;
				c.rgb *= _Brightness;
	
				// Spherical base normal
				//float3 localNormal = float3(IN.uv.xy * 2.0 - 1.0, 0.0);
				//localNormal.z = 1.0 - saturate(dot(localNormal.xy, localNormal.xy));
				//c.a *= localNormal.z;
				//half3 worldNormal = normalize(TransformByTBN2(localNormal, IN.normal, IN.pos.xyz, IN.uv));

				// Sample the normal map
				float3 worldNormal = UnpackNormal(_NormalMap, IN.normal, IN.pos.xyz, IN.uv);

			#ifndef USING_DIRECTIONAL_LIGHT
				float3 lightDir = UnityWorldSpaceLightDir(IN.pos.xyz);
				float distanceAttenuation = 1.0 / length(lightDir);
				lightDir *= distanceAttenuation;
			#else
				float3 lightDir = _WorldSpaceLightPos0.xyz;
			#endif

				// Dot product between the normal and the light directions
				half NdotL = dot(worldNormal, lightDir);

				// 100% light when facing the light, 50% light when light is shining through the particle.
				// This is like a cheap-and-dirty way of doing mie scattering.
				half diffuse = max(NdotL * 0.5 + 0.5, -NdotL * 0.5);

				// Only the side facing towards the light should have its texture-based definition
				// This approach will cause the texture to softly darken the face facing the light,
				// while the side facing away from the light will be lit using "ambient" lighting.
				c.rgb *= lerp(c.rgb, c.rgb * tex.rgb, diffuse);

				UNITY_LIGHT_ATTENUATION(atten, IN, IN.pos.xyz)
				atten *= ATTEN_BRIGHTNESS;
				atten *= diffuse;

				// Taking the full 360 degree arc as 0-1 range again helps define the shape
				atten *= (0.75 + 0.25 * NdotL);

			#ifndef USING_DIRECTIONAL_LIGHT
				atten *= distanceAttenuation;
			#endif
				//c.rgb *= UNITY_LIGHTMODEL_AMBIENT.rgb + _LightColor0.rgb * saturate(atten);

				// UNITY_LIGHTMODEL_AMBIENT.rgb doesn't look as well as using this approach:
				c.rgb = lerp(c.rgb, c.rgb * _LightColor0.rgb * saturate(atten), 0.9965);

			//#ifdef SOFTPARTICLES_ON
				float sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(IN.projPos))));
				c.a *= clamp((_InvFade * (sceneZ - IN.projPos.z)), 0.0, 1.0);
			//#endif

				//UNITY_APPLY_FOG(IN.fogCoord, c);
				return c;
			}
			ENDCG
		}

		//==============================================================================================
		// Additional light pass -- used by secondary light sources
		//==============================================================================================

		Pass
		{
			Name "FORWARDADD"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_particles
			//#pragma multi_compile_fog
			#pragma target 4.0

			half4 frag (v2f IN) : SV_Target
			{
				half4 tex = tex2D(_MainTex, IN.uv);
				half4 c = IN.color * _Color;
				c.a *= tex.a;
				c.rgb *= _Brightness;

				// Sample the normal map
				float3 worldNormal = UnpackNormal(_NormalMap, IN.normal, IN.pos.xyz, IN.uv);

			#ifndef USING_DIRECTIONAL_LIGHT
				float3 lightDir = UnityWorldSpaceLightDir(IN.pos.xyz);
				float distanceAttenuation = 1.0 / length(lightDir);
				lightDir *= distanceAttenuation;
			#else
				float3 lightDir = _WorldSpaceLightPos0.xyz;
			#endif

				// Dot product between the normal and the light directions
				half NdotL = dot(worldNormal, lightDir);
				half diffuse = max(NdotL * 0.5 + 0.5, -NdotL * 0.5);

				// Only the side facing towards the light should have its texture-based definition
				// This approach will cause the texture to softly darken the face facing the light,
				// while the side facing away from the light will be lit using "ambient" lighting.
				c.rgb *= lerp(c.rgb, c.rgb * tex.rgb, diffuse);
				c.rgb *= _LightColor0.rgb;

				// Light attenuation
				UNITY_LIGHT_ATTENUATION(atten, IN, IN.pos.xyz)
				atten *= ATTEN_BRIGHTNESS;
				atten *= diffuse;

				// Taking the full 360 degree arc as 0-1 range again helps define the shape
				//atten *= (0.75 + 0.25 * NdotL);

			#ifndef USING_DIRECTIONAL_LIGHT
				atten *= distanceAttenuation;
			#endif
				c.rgb *= atten;

			//#ifdef SOFTPARTICLES_ON
				float sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(IN.projPos))));
				c.a *= clamp((_InvFade * (sceneZ - IN.projPos.z)), 0.0, 1.0);
			//#endif

				// We're doing One One type blend, so attenuate by alpha
				c.rgb *= c.a;
				//UNITY_APPLY_FOG(IN.fogCoord, c);
				return c;
			}
			ENDCG
		}
	}
}
