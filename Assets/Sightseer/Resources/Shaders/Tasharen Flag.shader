﻿Shader "Tasharen/Flag"
{
	Properties
	{
		[NoScaleOffset] _MainTex ("Albedo (RGB), Alpha (A)", 2D) = "white" {}
		[NoScaleOffset] _BlendTex0 ("Detail 0 (RGB)", 2D) = "white" {}
		[NoScaleOffset] _DamageTex ("Damage Texture (A)", 2D) = "white" {}

		_Color ("Color", Color) = (1,1,1,1)
		_Cutoff ("Base Alpha cutoff", Range (0, 1)) = 0.5
		_BlendScale ("Blend Scale", Range(0, 4)) = 1.0
		_DamageScale ("Damage Scale", Range(0, 4)) = 1.0
		_BlendAlpha ("Blend Alpha", Range(0, 1)) = 0.5
		_Thickness ("Thickness Factor", Range(0, 1)) = 0.4
		_Condition ("Condition", Range(0, 1)) = 1.0
	}

	SubShader
	{
		LOD 200
		Cull Off

		Tags
		{
			"Queue" = "AlphaTest"
			"RenderType" = "Tasharen Flag"
		}

		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			Fog { Mode Off }
			Offset [_ShadowBias], [_ShadowBiasSlope]

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
			#include "UnityCG.cginc"
			#include "Tasharen Dither.cginc"

			sampler2D _MainTex, _DamageTex;
			half _Cutoff, _Condition, _DamageScale;

			struct v2f
			{
				V2F_SHADOW_CASTER;
				half3 tc : TEXCOORD1;
				V2F_DITHER_COORDS_IDX(2)
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert (appdata_full v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				TRANSFER_DITHER(o, v.vertex);
				o.tc = v.texcoord;
				return o;
			}

			float4 frag (v2f IN) : COLOR
			{
				half4 mainTex = tex2D(_MainTex, IN.tc.xy);
				mainTex.a *= lerp(tex2D(_DamageTex, IN.tc.xy * _DamageScale).a, 1.0, 0.25 + _Condition * 0.25);
				clip(mainTex.a - _Cutoff);
				APPLY_DITHER(IN);
				SHADOW_CASTER_FRAGMENT(IN);
			}
			ENDCG
		}

		CGPROGRAM
		#pragma surface surf Tasharen vertex:vert fullforwardshadows
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma multi_compile_instancing
		#pragma target 4.0

		//#define UNITY_GI_MODEL
		//#define GI_SOURCE TOD_Reflection

		sampler2D _MainTex, _BlendTex0, _DamageTex;
		half _BlendScale, _BlendAlpha, _Cutoff, _Thickness, _Condition, _DamageScale;
		half4 _Color;

		#define ADJUST_NDOTL(ndotl) \
			ndotl = ndotl * _Thickness + (1.0 - _Thickness); \
			ndotl *= ndotl;

		#include "Tasharen Lighting.cginc"

		struct Input
		{
			half4 tc : TEXCOORD0;
			half4 color : COLOR;
			half side : VFACE;
			V2F_COMMON_IDX(1)
		};

		#define CLIP _Cutoff

		void vert (inout appdata_full v, out Input o)
		{
			INITIALIZE_VERTEX(Input, v, o);
			o.tc.xy = v.texcoord.xy;
			o.tc.zw = v.texcoord1.xy;
			o.color = v.color;
		}

		void surf (Input IN, inout Output o)
		{
			half4 mainTex = tex2D(_MainTex, IN.tc.xy);
			mainTex.a *= lerp(tex2D(_DamageTex, IN.tc.xy * _DamageScale).a, 1.0, 0.25 + _Condition * 0.25);
			clip(mainTex.a - _Cutoff);
			half4 blend = tex2D(_BlendTex0, IN.tc.xy * _BlendScale);
			blend.rgb = lerp(mainTex.rgb, mainTex.rgb * blend.rgb * _Color.rgb, _BlendAlpha);
			o.Albedo = blend.rgb;
			o.Alpha = mainTex.a;
			
			o.Normal = half3(0.0, 0.0, 1.0);
			o.Normal *= IN.side; // Flip the normal if it's facing away from the camera (double-sided shader)
			
			APPLY_DITHER(IN)
		}
		ENDCG
	}
	FallBack "Legacy Shaders/Transparent/Cutout/Diffuse"
}
