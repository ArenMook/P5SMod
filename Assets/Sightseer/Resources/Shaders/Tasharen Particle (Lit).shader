Shader "Tasharen/Particles/Lit"
{
	Properties
	{
		[HDR] _Color ("Color", Color) = (1, 1, 1, 1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0
		_Thickness ("Thickness Factor", Range(0.0, 1)) = 0.05
		_FadeStart ("Distance fade start", float) = 2.0
		_FadeEnd ("Distance fade end", float) = 10.0
		_LightEffect ("Light Effect (R = Day, G = Night)", Vector) = (0.9, 0.5, 0.0, 0.0)
		
		[HideInInspector] _AlphaMode ("_AlphaMode", float) = 0.0
		[HideInInspector] _LightingMode("_LightingMode", float) = 0.0
		[HideInInspector] _LightCount("_LightCount", float) = 0.0
		[HideInInspector] _BlendMode ("_BlendMode", float) = 0.0
	}

	SubShader
	{
		Tags
		{
			"RenderType"="Transparent"
			"IgnoreProjector"="True"
			"Queue"="Transparent"
		}

		Cull Back
		Zwrite Off
		
		CGPROGRAM
		#pragma target 4.0
		#pragma surface surf Tasharen vertex:vert addshadow alpha:fade nodynlightmap nodirlightmap 
		#pragma shader_feature SOFTPARTICLE_ON __
		#pragma shader_feature DISTANCEFADE_ON __
		#pragma shader_feature ALPHAEROSION_ON __
		#pragma shader_feature EMISSION_ON __	
		#pragma shader_feature BACKLIGHT_ON __

		#define ADJUST_NDOTL(ndotl) \
			ndotl = ndotl * (1.0 - _Thickness) + _Thickness; \
			ndotl *= ndotl;

		sampler2D _MainTex;
		half4 _Color;
		half _Thickness;
		float _FadeStart;
		float _FadeEnd;
		half4 TOD_LightColor;
		half4 _LightEffect;
	#ifdef SOFTPARTICLE_ON
		sampler2D _CameraDepthTexture;
		half _InvFade;
	#endif

		#include "Tasharen Lighting.cginc"

		//==============================================================================================

		inline float DistanceFade (float fadeDistEnd, float fadeDistStart, float3 worldPos)
		{
			float fadeDistance = distance(_WorldSpaceCameraPos, worldPos) - fadeDistEnd;
			return saturate(fadeDistance / (fadeDistStart - fadeDistEnd));
		}

		//==============================================================================================
	
		struct Input
		{
			float4 vertex : SV_POSITION;
			float4 color : COLOR;
			float2 uv_MainTex : TEXCOORD0;
		#ifdef SOFTPARTICLE_ON
			float4 projPos : TEXCOORD1;
		#endif
		#ifdef DISTANCEFADE_ON
			half distanceFade : TEXCOORD2;
		#endif
			float3 lookDir : TEXCOORD3;
		};

		//==============================================================================================
		
		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.lookDir = mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos.xyz;

		#ifdef SOFTPARTICLE_ON
			o.projPos = ComputeScreenPos(o.vertex);
			COMPUTE_EYEDEPTH(o.projPos.z);
		#endif
			
		#ifdef DISTANCEFADE_ON
			o.distanceFade = DistanceFade(_FadeEnd, _FadeStart, mul(unity_ObjectToWorld, v.vertex).xyz);
			o.distanceFade *= saturate((-UnityObjectToViewPos(v.vertex).z - _ProjectionParams.y) * 0.15);
		#endif
		}

		//==============================================================================================

		void surf (Input i, inout Output o)
		{
			half4 color = tex2D(_MainTex, i.uv_MainTex);
			color.rgb *= _Color.rgb;
			
		#ifdef ALPHAEROSION_ON
			color.a -= 1.0 - i.color.a;
		#else
			color.a *= i.color.a;
		#endif
			color.a *= _Color.a;
			
		#ifdef SOFTPARTICLE_ON
			float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
			color.a *= saturate (_InvFade * (sceneZ - i.projPos.z));
		#endif
			
		#ifdef DISTANCEFADE_ON
			color.a *= i.distanceFade;
		#endif
			
		#ifdef EMISSION_ON
			o.Emission = i.color.rgb;
		#else
			color.rgb *= i.color.rgb;
		#endif
			
			half intensity = lerp(_LightEffect.g, _LightEffect.r, TOD_LightColor.a);
			o.Emission = color.rgb * TOD_LightColor.rgb * (1.0 - intensity);
			o.Albedo = color.rgb * intensity;
			o.Alpha = color.a;
		}
		ENDCG
	} 
	Fallback Off
}
