Shader "Tasharen/Bumped Glow"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_SpecTex ("Specular", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_GlowMap ("Glow Map", 2D) = "black" {}
		_Color ("Color", Color) = (1,1,1,1)
		_Specular ("Specular Color", Color) = (0.0664, 0.0664, 0.0664, 0.64)
		_Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.665
	}

	SubShader
	{
		LOD 200
		Tags { "RenderType"="Opaque" }
		Cull Back

		CGPROGRAM
		#pragma surface surf Tasharen vertex:vert
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma target 3.0

		//#define UNITY_GI_MODEL
		//#define GI_SOURCE TOD_Reflection

		#include "Tasharen Lighting.cginc"

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_SpecTex;
			float2 uv_BumpMap;
			float2 uv_GlowMap;
			V2F_DITHER_COORDS
		};

		sampler2D _MainTex;
		sampler2D _SpecTex;
		sampler2D _BumpMap;
		sampler2D _GlowMap;
		half4 _Color;
		half4 _Specular;
		half _Smoothness;

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			TRANSFER_DITHER(o, v.vertex);
		}

		void surf (Input IN, inout Output o)
		{
			half4 tex = tex2D(_MainTex, IN.uv_MainTex);
			half4 spec = tex2D(_SpecTex, IN.uv_SpecTex);
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			o.Albedo = tex.rgb * _Color.rgb;
			o.Specular = _Specular * spec;
			o.Specular.rgb *= o.Specular.a;
			o.Emission = tex2D(_GlowMap, IN.uv_GlowMap).rgb;
			o.Smoothness = _Smoothness;
			o.Alpha = _Color.a;
			APPLY_DITHER(IN);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
