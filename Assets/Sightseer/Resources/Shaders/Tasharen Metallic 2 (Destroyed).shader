Shader "Tasharen/Metallic 2 (Destroyed)"
{
	Properties
	{
		[NoScaleOffset] _MainTex ("Texture (RGB), Specular (A)", 2D) = "white" {}
		[NoScaleOffset][Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
		[NoScaleOffset] _MaskTex ("Mask: R = smoothness, G = metal, B = glow, A = specular", 2D) = "white" {}
		[NoScaleOffset] _DamageTex ("Damage Texture (RGBA)", 2D) = "black" {}

		_Color ("Color", Color) = (1,1,1,1)
		_Specularity ("Specularity", Range(0,1)) = 0.2
		_Metallic ("Metallic", Range(0,1)) = 0.2
		_Smoothness ("Smoothness", Range(0,1)) = 0.81
		_TriplanarScale ("Damage Scale", Vector) = (0.5, 0.25, 1, 1)
		_Condition ("Condition", Range(0,1)) = 1.0

		[HDR] _Glow ("Glow Color", Color) = (0,0,0,1)
		[HideInInspector] _GlowBrightness ("Glow Brightness", Range(0,1)) = 1.0

		_FadeOut ("Fade out", Range (0, 1)) = 1
	}

	SubShader
	{
		LOD 200
		Tags { "RenderType"="Opaque" }
		Cull Off
		
		Tags
		{

			"Queue" = "AlphaTest"
			"RenderType" = "TransparentCutout"
			"IgnoreProjector" = "True"
		}

		CGPROGRAM
		#pragma surface surf Tasharen vertex:vert fullforwardshadows
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma target 4.0

		//#define UNITY_GI_MODEL
		//#define GI_SOURCE TOD_Reflection

		#include "Tasharen Lighting.cginc"
		#include "Tasharen Damage.cginc"

		struct Input
		{
			float2 uv_MainTex : TEXCOORD0;
			half4 color : COLOR;
			V2F_DITHER_COORDS_IDX(1)
			V2F_TRIPLANAR(2, 3)
		};

		sampler2D _MainTex, _BumpMap, _MaskTex, _DamageTex;
		half4 _Color, _Specular, _Glow, _TriplanarScale;
		half _Specularity, _Metallic, _Smoothness, _GlowBrightness, _Condition, _FadeOut;

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			TRANSFER_DITHER(o, v.vertex);
			o.color = v.color;
			TRANSFER_TRIPLANAR(v, o);
		}

		void surf (Input IN, inout Output o)
		{
			TRIPLANAR_SAMPLE_AND_CLIP2(IN, _DamageTex, _FadeOut, _TriplanarScale.x, _TriplanarScale.y, triplanar, damage);

			half4 tex = tex2D(_MainTex, IN.uv_MainTex);
			half4 mask = tex2D(_MaskTex, IN.uv_MainTex);

			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
			o.Albedo = lerp(tex.rgb, _Color.rgb * tex.rgb, mask.g * _Color.a);

			o.Specular.rgb = _Color.rgb * (_Specularity * mask.r * mask.g * _Metallic);
			o.Specular.a = _Specularity * mask.a;

			o.Emission = _Glow.rgb * (_Glow.a * mask.b * _GlowBrightness);
			o.Smoothness = _Smoothness * mask.r;

			TRIPLANAR_OVERLAY(IN, damage, 0.0, 1.0, IN.color.a, 1.0);
			APPLY_DITHER(IN);
		}
		ENDCG
	}
	FallBack "Tasharen/Metallic (Destroyed)"
}
