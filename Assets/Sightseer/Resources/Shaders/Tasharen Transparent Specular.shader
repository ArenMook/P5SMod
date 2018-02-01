Shader "Tasharen/Transparent Specular"
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
			"RenderType" = "Transparent+1"
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
		}
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Tasharen alpha:fade
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma target 3.0
		#include "Tasharen Lighting.cginc"

		struct Input
		{
			float2 uv_MainTex;
		};

		sampler2D _MainTex;
		half4 _Color;
		half4 _Specular;
		half _Smoothness;

		void surf (Input IN, inout Output o)
		{
			half4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb;
			o.Specular = _Specular;
			o.Specular.a *= tex.a;
			o.Smoothness = _Smoothness;
#ifdef LOD_FADE_CROSSFADE
			o.Alpha = _Color.a * unity_LODFade.x;
#else
			o.Alpha = _Color.a;
#endif
		}
		ENDCG
	} 
	FallBack "Transparent"
}
