Shader "Tasharen/Reflective"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_ReflectColor ("Reflection Color", Color) = (0,0,0,0)
		_MainTex ("Texture", 2D) = "white" {}
		_Cube ("Reflection Cubemap", Cube) = "_Skybox" {}
		_Specular ("Specular Color", Color) = (0.15, 0.15, 0.15, 0.15)
		_Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.0
		_Bias ("Reflection Bias", Range(0,1)) = 0.0
		_Blur ("Blur", Range(0,1)) = 0.5
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#pragma surface surf Tasharen vertex:vert
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma target 4.0
		#include "Tasharen Lighting.cginc"

		sampler2D _MainTex;
		UNITY_DECLARE_TEXCUBE(_Cube);

		struct Input
		{
			float2 uv_MainTex;
			float3 worldRefl;
			V2F_DITHER_COORDS
		};

		half4 _Color;
		half4 _ReflectColor;
		half4 _Specular;
		half _Smoothness;
		half _Bias;
		half _Blur;

		void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            TRANSFER_DITHER(o, v.vertex);
        }

		void surf (Input IN, inout Output o)
		{
			half4 tex = tex2D(_MainTex, IN.uv_MainTex);
			half4 rc = UNITY_SAMPLE_TEXCUBE_LOD(_Cube, IN.worldRefl, _Blur * UNITY_SPECCUBE_LOD_STEPS) * _ReflectColor * tex.a;

			o.Albedo = lerp(tex.rgb * _Color.rgb, rc.rgb, _Bias);
			o.Emission = rc.rgb * rc.a;
			o.Specular = _Specular;
			o.Specular.rgb *= o.Specular.a;
			o.Smoothness = _Smoothness * tex.a;
			o.Alpha = 1.0;
			APPLY_DITHER(IN);
		}
		ENDCG
	}
	FallBack "Tasharen/Diffuse"
}
