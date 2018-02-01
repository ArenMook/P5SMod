Shader "Tasharen/Advanced AO Cutout"
{
	Properties
	{
		[NoScaleOffset] _MainTex ("AO from Surforge (RGB), Glass (black A)", 2D) = "white" {}
		[NoScaleOffset] _ColorMask ("Color Mask (RGB), Tint Amount (A)", 2D) = "black" {}
		[NoScaleOffset][Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
		[NoScaleOffset] _OcclusionMap ("Ambient Occlusion (using UV2)", 2D) = "white" {}
		[NoScaleOffset] _BlendTex0 ("Detail 0 (RGB), Smoothness (A)", 2D) = "white" {}
		[NoScaleOffset] _BlendTex1 ("Detail 1 (RGB), Smoothness (A)", 2D) = "white" {}
		[NoScaleOffset] _DamageTex ("Damage Texture (RGBA)", 2D) = "black" {}

		_Color0 ("Color Mask's Red Color", Color) = (1, 1, 1, 1)
		_Color1 ("Color Mask's Green Color", Color) = (0.1, 0.1, 0.1, 1)
		_Color2 ("Color Mask's Blue Color", Color) = (0.353, 0, 0, 1)
		_Color3 ("Color Mask's Black Color", Color) = (0.2, 0.2, 0.2, 0.2)

		_Spec0 ("Color Mask's Red Specular", Color) = (0,0,0,0)
		_Spec1 ("Color Mask's Green Specular", Color) = (0,0,0,0)
		_Spec2 ("Color Mask's Blue Specular", Color) = (0,0,0,0)
		_Spec3 ("Color Mask's Black Specular", Color) = (0,0,0,0)

		[Space] _TexBlend ("Detail Blend (for each color, 0-1 range)", Vector) = (0, 0, 0, 0)
		_BlendScale ("Detail UV Scale (for each color)", Vector) = (2, 2, 2, 2)
		_BlendAlpha ("Detail Blend Alpha (for each color, 0-1)", Vector) = (0.5, 0.5, 0.5, 0.5)
		_Metallic ("Metallic (for each color, 0-1 range)", Vector) = (0.2, 0.9, 0.9, 0)
		_Smoothness ("Smoothness (for each color, 0-1 range)", Vector) = (0.8, 0.9, 0.9, 0.2)
		_OcclusionStrength ("Occlusion Strength", Range(0, 1)) = 1.0
		_TriplanarScale ("Triplanar Scale", Vector) = (0.5, 0.25, 1, 1)

		_Condition ("Condition", Range(0, 1)) = 1.0
		_Cutoff ("Base Alpha cutoff", Range (0, 1)) = 0.5
	}

	SubShader
	{
		LOD 200
		Cull Off

		Tags
		{
			"Queue" = "AlphaTest"
			"RenderType" = "Tasharen Cutout"
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

			sampler2D _MainTex;
			half _Cutoff;

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

			float4 frag (v2f i) : COLOR
			{
				clip(tex2D(_MainTex, i.tc).a - _Cutoff);
				APPLY_DITHER(i);
				SHADOW_CASTER_FRAGMENT(i);
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

		#include "Tasharen Lighting.cginc"
		#include "Tasharen Damage.cginc"

		struct Input
		{
			half4 tc : TEXCOORD0;
			half4 color : COLOR;
			half side : VFACE;
			V2F_COMMON_IDX(1)
			V2F_TRIPLANAR(2, 3)
		};

		sampler2D _DamageTex;
		half4 _TriplanarScale;
		half _Condition;

		#define CLIP _Cutoff
		#include "Tasharen Advanced AO.cginc"

		void vert (inout appdata_full v, out Input o)
		{
			CommonVertexShader(v, o);
			TRANSFER_TRIPLANAR(v, o);
		}

		void surf (Input IN, inout Output o)
		{
			half4 mainTex, mask, blend, ao;
			half tintAmount;
			CommonSurfaceShader(IN, o, mainTex, mask, blend, ao, tintAmount);
			o.Normal *= IN.side; // Flip the normal if it's facing away from the camera (double-sided shader)
			SAMPLE_TRIPLANAR_OVERLAY(IN, _DamageTex, _TriplanarScale.x, _Condition, tintAmount * mainTex.a, IN.color.a, ao.r);
		}
		ENDCG
	}
	FallBack "Legacy Shaders/Transparent/Cutout/Diffuse"
}
