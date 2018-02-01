Shader "Tasharen/Triplanar Bumped AO"
{
	Properties
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		[NoScaleOffset] _MainTex ("Base (RGB)", 2D) = "white" {}
		[NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
		[NoScaleOffset] _OcclusionMap ("Ambient Occlusion (UV0)", 2D) = "white" {}
		_TexScale ("MainTex Scale", Float) = 1.0
		_TexScale2 ("Bump Map Scale", Float) = 1.0
		_BlendPower ("Blend Power", Float) = 64.0
		_Specular ("Specular Color", Color) = (0.15, 0.15, 0.15, 0.15)
		_Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.2
		_OcclusionStrength("Occlusion Strength", Range(0, 1)) = 1.0
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
		sampler2D _OcclusionMap;
		half4 _MainTex_ST;
		half4 _Color;
		half _TexScale, _TexScale2;
		half _BlendPower;
		half4 _Specular;
		half _Smoothness;
		half _OcclusionStrength;

		struct Input
		{
			float3 pos;
			float3 normal;
			float2 tc;
		};

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.pos = v.vertex.xyz * CalculateObjectScale();
			o.normal = v.normal;
			v.tangent = CalculateTriplanarTangent(v.normal, _BlendPower);
			o.tc = v.texcoord1.xy;
		}

		void surf (Input IN, inout Output o)
		{
			half3 signage = sign(IN.normal) * 0.5 + 0.5;
			half3 contribution = CalculateTriplanarContribution(IN.normal, _BlendPower);

			half3 pos = IN.pos;
			half4 tc0 = half4(-pos.z,  pos.y,  pos.z,  pos.y);
			half4 tc1 = half4( pos.x, -pos.z,  pos.x,  pos.z);
			half4 tc2 = half4( pos.y, -pos.x, -pos.y, -pos.x);

			half4 c = SampleTriplanar(_MainTex, tc0 * _TexScale, tc1 * _TexScale, tc2 * _TexScale, signage, contribution);

			half3 ao = lerp((1.0).xxx, tex2D(_OcclusionMap, IN.tc).rgb, _OcclusionStrength);
			o.Albedo = c.rgb * _Color.rgb * ao;
			o.Alpha = 1.0;

			o.Normal = UnpackNormal(SampleTriplanar(_BumpMap, tc0 * _TexScale2, tc1 * _TexScale2, tc2 * _TexScale2, signage, contribution));

			o.Specular = _Specular * c.a * ao.r;
			o.Smoothness = _Smoothness;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
