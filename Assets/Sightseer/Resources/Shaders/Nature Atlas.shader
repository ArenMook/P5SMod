Shader "Tasharen/Nature Atlas"
{
	Properties
	{
		_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
		_Cutoff ("Base Alpha cutoff", Range (0, 0.9)) = 0.5
	}

	//==============================================================================================
	CGINCLUDE
	#include "UnityPBSLighting.cginc"

	uniform float4 GameWind;
	uniform float4 GameWindOffset;
	uniform float3 _FloatingOriginOffset;
	uniform float4 _Pollution;

	inline float4 AnimateTree (float4 v, float strength)
	{
		float4 worldPos = mul(unity_ObjectToWorld, v);
		worldPos.xz += _FloatingOriginOffset.xz;

		float2 offset = float2(
			sin((worldPos.x - GameWindOffset.x) * 0.4),
			cos((worldPos.z - GameWindOffset.y) * 0.4)) * 0.5;

		float2 offset2 = float2(
			sin((worldPos.x - GameWindOffset.x * 0.2) * 10.0),
			cos((worldPos.z - GameWindOffset.y * 0.2) * 10.0));

		strength = GameWindOffset.z * 0.15 * (strength * strength + strength);
		v.xz += (offset2 * 0.15 + offset + GameWind.xy) * strength;
		return v;
	}
	ENDCG
	//==============================================================================================

	SubShader
	{
		LOD 300
		Cull Off
		ZWrite On
		ZTest LEqual

		Tags
		{
			"Queue"="AlphaTest-10"
			"IgnoreProjector"="True"
			"DisableBatching" = "True"
			"RenderType"="Nature Atlas"
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
			#include "UnityCG.cginc"
			#include "Tasharen Dither.cginc"

			sampler2D _MainTex;
			half _Cutoff;

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
				v.vertex = AnimateTree(v.vertex, v.color.a);
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER(o)
				TRANSFER_DITHER(o, v.vertex);
				o.tc = v.texcoord;
				return o;
			}

			float4 frag (v2f i) : COLOR
			{
				clip(tex2D(_MainTex, i.tc).a - _Cutoff);
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
			float2 uv_MainTex;
			half4 color;
			V2F_DITHER_COORDS
			UNITY_VERTEX_OUTPUT_STEREO
		};

		//==============================================================================================
		// Vertex color meaning:
		// R = blend colors A with B, and C with D
		// G = blend between AB and CD from the previous step
		// B = blend between G and original texture color
		// A = how much the vertex should be affected by the wind
		//==============================================================================================

		void vert (inout appdata v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			v.vertex = AnimateTree(v.vertex, v.color.a);
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
			TRANSFER_DITHER(o, v.vertex);
			o.color = v.color;
		}

		//==============================================================================================

		void surf (Input IN, inout Output o)
		{
			half4 col = tex2D(_MainTex, IN.uv_MainTex);

			// If the vertex color is pure white, it shouldn't be affected by color tinting at all
			half f = min(IN.color.r, min(IN.color.g, IN.color.b));
			f = sign(1.0 - min(1.0, 0.01 + f));

			// The more green the texture, the more it should be affected by the color tint
			f *= saturate(50.0 * (col.g - col.r));

			half saturation = 1.0 - col.g;
			saturation *= saturation;
			saturation = 1.0 - saturation;
			half3 tintedColor = lerp(IN.color.rgb, _Pollution.rgb, 0.75 * _Pollution.a) * saturation;

			saturation = dot(col.rgb, (0.3333).xxx);
			saturation *= saturation;
			tintedColor = lerp(tintedColor, half3(1.0, 1.0, 1.0), saturation);

			// Final tinted color
			o.Albedo = lerp(col.rgb, tintedColor, f);

			// Testing the tree? Uncomment this line to see its texture-specified colors.
			//o.Albedo = col.rgb;

			o.Alpha = col.a;
			APPLY_DITHER(IN);
		}
		ENDCG
	}
	Fallback off
}
