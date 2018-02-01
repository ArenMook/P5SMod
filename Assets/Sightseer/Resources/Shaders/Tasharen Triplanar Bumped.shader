Shader "Tasharen/Triplanar Bumped"
{
	Properties
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		[NoScaleOffset] _MainTex ("Base (RGB)", 2D) = "white" {}
		[NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
		_TexScale ("Texture Scale", Float) = 1.0
		_BlendPower ("Blend Power", Float) = 64.0
		_Specular ("Specular Color", Color) = (0.15, 0.15, 0.15, 0.15)
		_Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.2
	}

	SubShader
	{
		LOD 300
		Tags { "RenderType" = "Opaque" }

		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Tasharen vertex:vert fullforwardshadows
		#include "Tasharen Lighting.cginc"
		#include "Tasharen Math.cginc"

		sampler2D _MainTex;
		sampler2D _BumpMap;
		half4 _MainTex_ST;
		half4 _Color;
		half _TexScale;
		half _BlendPower;
		half _Specular;
		half _Smoothness;

		struct Input
		{
			float3 pos;
			float3 normal;
		};

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.pos = v.vertex.xyz * CalculateObjectScale();
			o.normal = v.normal;
			v.tangent = CalculateTriplanarTangent(v.normal, _BlendPower);
		}

		void surf (Input IN, inout Output o)
		{
			half3 signage = sign(IN.normal) * 0.5 + 0.5;
			half3 contribution = CalculateTriplanarContribution(IN.normal, _BlendPower);

			half3 pos = IN.pos * _TexScale;
			half4 tc0 = half4(-pos.z,  pos.y,  pos.z,  pos.y);
			half4 tc1 = half4( pos.x, -pos.z,  pos.x,  pos.z);
			half4 tc2 = half4( pos.y, -pos.x, -pos.y, -pos.x);

			half4 c = SampleTriplanar(_MainTex, tc0, tc1, tc2, signage, contribution);

			o.Albedo = c.rgb * _Color.rgb;
			o.Alpha = 1.0;

			o.Normal = UnpackNormal(SampleTriplanar(_BumpMap, tc0, tc1, tc2, signage, contribution));

			o.Specular = _Specular * c.a;
			o.Smoothness = _Smoothness;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
