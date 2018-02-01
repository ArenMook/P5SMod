Shader "Tasharen/Masked"
{
	Properties
	{
		_MainTex ("Albedo (R), Mask (G), Emissive (B), Reflective (A)", 2D) = "black" {}
		_Color ("Color A", Color) = (1,1,1,1)
		_Secondary ("Color B", Color) = (1,1,1,1)
		_ReflectColor ("Reflection Color", Color) = (0,0,0,0)
		_Emissive ("Emissive Color", Color) = (0,0,0,1)
		_EmissionPower ("Emission Power", Range(1.0, 500.0)) = 200.0
		_Specular ("Specular Color", Color) = (0.15, 0.15, 0.15, 0.15)
		_Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Tasharen
		#pragma target 3.0
		#include "Tasharen Lighting.cginc"

		sampler2D _MainTex;

		struct Input
		{
			float2 uv_MainTex;
		};

		half4 _Color;
		half4 _Secondary;
		half4 _Emissive;
		half4 _ReflectColor;
		half4 _Specular;
		half _Smoothness;
		half _EmissionPower;

		void surf (Input IN, inout Output o)
		{
			half4 tex = tex2D(_MainTex, IN.uv_MainTex);

			o.Albedo = lerp(_Color.rgb, _Secondary.rgb, tex.g);
			o.Emission = _Emissive.rgb * (tex.b * pow(_Emissive.a, 4.0) * _EmissionPower);
			
			o.Specular = _Specular;
			o.Specular.a *= tex.a;
			o.Smoothness = _Smoothness;
			o.Alpha = 1.0;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
