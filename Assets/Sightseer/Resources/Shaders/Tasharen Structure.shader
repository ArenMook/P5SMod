Shader "Tasharen/Structure"
{
	Properties
	{
		_MainTex ("Grayscale (R), Color mask (GB), Specular (A)", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_GlowMap ("Glow (RGB)", 2D) = "white" {}
		_Color0 ("Color 1", Color) = (1,1,1,1)
		_Color2 ("Color 2", Color) = (1,1,1,1)
		_Color3 ("Color 3", Color) = (1,1,1,1)
		_Specular ("Specular", Color) = (0.2,0.2,0.2,1)
		[HDR] _Glow ("Glow Color", Color) = (0,0,0,1)
		[Space] _Smoothness ("Smoothness", Range(0,1)) = 0.81
		[HideInInspector] _GlowBrightness ("Glow Brightness", Range(0,1)) = 1.0
	}

	SubShader
	{
		LOD 200
		Tags { "RenderType"="Opaque" }
		Cull Back

		CGPROGRAM
		#pragma surface surf Tasharen vertex:vert fullforwardshadows
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma target 3.0

		//#define UNITY_GI_MODEL
		//#define GI_SOURCE TOD_Reflection

		#include "Tasharen Lighting.cginc"

		struct Input
		{
			float2 uv_MainTex;
			V2F_DITHER_COORDS
		};

		sampler2D _MainTex, _BumpMap, _GlowMap;
		half4 _Color0, _Color2, _Color3, _Specular, _Glow;
		half _Smoothness, _GlowBrightness;

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			TRANSFER_DITHER(o, v.vertex);
		}

		void surf (Input IN, inout Output o)
		{
			half4 tex = tex2D(_MainTex, IN.uv_MainTex);
			half4 glow = tex2D(_GlowMap, IN.uv_MainTex);
			glow.rgb *= _Glow.rgb * (_Glow.a * _GlowBrightness);

			half tintAmount = max(0.0, 1.0 - max(glow.r, max(glow.g, glow.b)));

			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
			
			half4 c = lerp(_Color0, _Color2, tex.g);
			c = lerp(c, _Color3, tex.b);
			
			o.Albedo = lerp(tex.rrr, c.rgb * tex.rrr, tintAmount);

			o.Specular.rgb = _Specular.rgb * (tex.a * c.a * tintAmount);
			o.Specular.a = dot(tex.rrr, tex.aaa) * _Specular.a;

			o.Emission = glow.rgb;
			o.Smoothness = _Smoothness;

			APPLY_DITHER(IN);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
