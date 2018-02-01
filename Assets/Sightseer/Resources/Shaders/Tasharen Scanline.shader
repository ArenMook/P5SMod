Shader "Tasharen/Scanline"
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
			"RenderType" = "Transparent"
			"Queue" = "Transparent+1"
			"IgnoreProjector" = "True"
		}
		LOD 200
		
		Pass
		{
			ZWrite On
			ColorMask 0
		}
		
		CGPROGRAM
		#pragma surface surf Tasharen vertex:vert alpha:auto
		#pragma target 4.0
		#include "UnityCG.cginc"
		#include "Tasharen Lighting.cginc"

		struct Input
		{
			float4 screenPos : TEXCOORD0;
			float3 worldPos : TEXCOORD1;
			float3 worldNormal : TEXCOORD2;
		};

		sampler2D _MainTex;
		half4 _Color;
		half4 _Specular;
		half _Smoothness;
		
		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.worldNormal = mul(unity_ObjectToWorld, half4(v.normal, 0.0)).xyz;
		}

		void surf (Input IN, inout Output o)
		{
			float3 dir = normalize(IN.worldPos - _WorldSpaceCameraPos);
			float dp = 1.0 - saturate(-dot(normalize(IN.worldNormal), dir));
			dp = 1.0 - dp * dp;

			float screenY = (IN.screenPos.y / IN.screenPos.w) * _ScreenParams.y;
			half4 tex = lerp(
				tex2D(_MainTex, half2(0.5, screenY * 0.2 + _Time.w)),
				tex2D(_MainTex, half2(0.5, screenY * 0.02 - _Time.w)), 0.2);

			o.Albedo = _Color.rgb * 0.25 * dp;
			o.Emission = _Color.rgb * tex.rgb * 0.5 * dp;
			o.Specular = _Specular;
			o.Specular.a *= tex.a;
			o.Smoothness = _Smoothness;
			o.Alpha = dp * _Color.a;
		}
		ENDCG
	}
	FallBack "Transparent"
}
