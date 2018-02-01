Shader "Tasharen/Wind Animation"
{
	Properties
	{
		[NoScaleOffset] _MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
		_Color0 ("Albedo Color", Color) = (1, 1, 1, 1)
		_Spec0 ("Specular Color", Color) = (1, 1, 1, 1)
		[HDR] _Emission ("Emission Color", Color) = (1, 1, 1, 1)
		_Metallic ("Metallic", Range(0, 1)) = 0.5
		_Smoothness ("Smoothness", Range(0, 1)) = 0.9
		_Cutoff ("Base Alpha cutoff", Range (0, 0.9)) = 0.5
		_Strength ("Wind Effect", Range(0, 1)) = 0.45

		[Space][NoScaleOffset] _OcclusionMap ("Ambient Occlusion (using UV2)", 2D) = "white" {}
		_OcclusionStrength ("Occlusion Strength", Range(0, 1)) = 1.0

		[Space][NoScaleOffset] _DamageTex ("Damage texture", 2D) = "white" {}
		[Space][NoScaleOffset] _BlendTex0 ("Detail (RGB), Smoothness (A)", 2D) = "white" {}
		_BlendScale ("Detail Scale", Range(0.2, 2.0)) = 1.0
		_BlendStrength ("Detail Strength", Range(0, 1)) = 1.0
		_BlendAlpha ("Blend Alpha", Range(0, 1)) = 0.2
		_FadeOut ("Fade out", Range(0, 1)) = 1
	}

	//==============================================================================================
	CGINCLUDE
	#include "UnityPBSLighting.cginc"

	float4 GameWind;
	float4 GameWindOffset;
	float3 _FloatingOriginOffset;
	float _Strength;

	inline float4 Animate (float4 v, float strength)
	{
		float4 worldPos = mul(unity_ObjectToWorld, v);
		worldPos.xz += _FloatingOriginOffset.xz;

		float2 offset = float2(
			sin((worldPos.x - GameWindOffset.x) * 0.4),
			cos((worldPos.z - GameWindOffset.y) * 0.4)) * 0.5;

		float2 offset2 = float2(
			sin((worldPos.x - GameWindOffset.x * 0.2) * 5.0),
			cos((worldPos.z - GameWindOffset.y * 0.2) * 5.0));

		strength = GameWindOffset.z * _Strength * (strength * strength + strength);
		float2 temp = (offset2 * 0.15 + offset + GameWind.xy) * strength;
		v.xyz += normalize(v.xyz) * 0.5 * temp.x;
		v.xz += temp * 0.5;
		return v;
	}
	ENDCG
	//==============================================================================================

	SubShader
	{
		LOD 300
		Cull Back
		ZWrite On
		ZTest LEqual

		Tags
		{
			"Queue"="AlphaTest-5"
			"IgnoreProjector"="True"
			"DisableBatching" = "True"
			"RenderType"="Wind"
		}

		//==============================================================================================

		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			Fog { Mode Off }
			Offset [_ShadowBias], [_ShadowBiasSlope]

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
			#include "Tasharen Dither.cginc"

			sampler2D _MainTex, _DamageTex;
			half _Cutoff;
			half _FadeOut;

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color: COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				V2F_SHADOW_CASTER;
				half2 tc : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
				V2F_DITHER_COORDS_IDX(2)
			};

			v2f vert (appdata v)
			{
				v2f o;
				v.vertex = Animate(v.vertex, v.color.r);
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER(o)
				TRANSFER_DITHER(o, v.vertex);
				o.tc = v.texcoord;
				return o;
			}

			float4 frag (v2f i) : COLOR
			{
				clip(min(_FadeOut - tex2D(_DamageTex, i.tc).a * 0.98 - 0.01, tex2D(_MainTex, i.tc).a - _Cutoff));
				APPLY_DITHER(i);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}

		//==============================================================================================

		CGPROGRAM
		#pragma target 4.0
		#pragma surface surf Tasharen vertex:vert alphatest:_Cutoff fullforwardshadows
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma multi_compile_instancing
		#include "Tasharen Lighting.cginc"

		sampler2D _MainTex;
		sampler2D _OcclusionMap;
		sampler2D _BlendTex0;
		sampler2D _DamageTex;
		half _OcclusionStrength;
		half _BlendScale, _BlendStrength, _BlendAlpha;
		half4 _Color0, _Spec0, _Emission;
		half _Metallic, _Smoothness;
		half _FadeOut;

		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
			float2 texcoord1 : TEXCOORD1;
			float2 texcoord2 : TEXCOORD2;
			fixed4 color: COLOR;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		struct Input
		{
			float2 tc0;
			float2 tc1;
			V2F_DITHER_COORDS
			UNITY_VERTEX_OUTPUT_STEREO
		};

		void vert (inout appdata v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			v.vertex = Animate(v.vertex, v.color.r);
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
			TRANSFER_DITHER(o, v.vertex);
			o.tc0 = v.texcoord;
			o.tc1 = v.texcoord1;
		}

		//==============================================================================================

		void surf (Input IN, inout Output o)
		{
			clip(_FadeOut - tex2D(_DamageTex, IN.tc0).a * 0.98 - 0.01);

			half4 mainTex = tex2D(_MainTex, IN.tc0);
			half4 ao = tex2D(_OcclusionMap, IN.tc1);
			half4 blend = tex2D(_BlendTex0, IN.tc0 * _BlendScale);

			ao = lerp(half4(1.0, 1.0, 1.0, 1.0), ao, _OcclusionStrength);
			blend.rgb = lerp(half3(1, 1, 1), blend.rgb, _BlendStrength);
			//blend.rgb *= mainTex.rgb;

			o.Specular.rgb = lerp(_Color0.rgb, _Spec0.rgb, _Spec0.a) * _Metallic;

			// Treat the diffuse channel as the source of specular intensity. Ideally we'd have the specular in the alpha channel instead.
			o.Specular.a = dot(blend.rgb, (0.333).xxx);
			blend.rgb *= mainTex.rgb;

			// Detail textures' alpha channel adjust the specularity and smoothness
			half blendA = lerp(1.0, blend.a, _BlendAlpha);
			o.Specular *= _Color0.a * blendA;
			o.Smoothness = _Smoothness * (0.75 + 0.25 * blendA);

			// Apply the AO
			o.Specular *= mainTex.r * ao.r;
			o.Albedo = _Color0.rgb * blend.rgb * ao.rgb;
			o.Alpha = mainTex.a;
			o.Emission = _Emission;

			APPLY_DITHER(IN);
		}
		ENDCG
	}
	Fallback off
}
