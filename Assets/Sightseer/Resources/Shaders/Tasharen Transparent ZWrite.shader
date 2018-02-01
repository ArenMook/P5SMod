Shader "Tasharen/Transparent (ZWrite)"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (1,1,1,1)
		_Specular ("Specular Color", Color) = (0.0664, 0.0664, 0.0664, 0.64)
		_Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.665
	}

	SubShader
	{
		Tags
		{
			"Queue"="Geometry+100"
			"RenderType"="Opaque"
		}
		LOD 200
		
		Pass
		{
			ZWrite On
			ColorMask 0
		}
		
		CGPROGRAM
		#pragma surface surf Tasharen alpha:auto
		#pragma target 3.0
		#include "Tasharen Lighting.cginc"

		struct Input
		{
			float2 uv_MainTex;
		};

		sampler2D _MainTex;
		half4 _Color;
		half4 _Specular;
		half4 _Secondary;
		half _Smoothness;

		void surf (Input IN, inout Output o)
		{
			half4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb;
			o.Specular = _Specular;
			o.Specular.a *= tex.a;
			o.Smoothness = _Smoothness;
			o.Alpha = _Color.a;
		}
		ENDCG
	} 
	Fallback "Transparent/Diffuse"
}
