Shader "Tasharen/Grass Atlas"
{
	Properties
	{
		_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
		_ColorMask ("Color mask (A)", 2D) = "black" {}
		//_Hue ("Base hue", Range(0, 1)) = 0.0
		_Brightness ("Brightness", Range(0.5, 2.0)) = 1.0
		_Cutoff ("Base Alpha cutoff", Range (0, 0.9)) = 0.5

		//[HideInInspector] _GrassTexColor ("Grass mask", 2D) = "white" {}
	}

	//==============================================================================================
	CGINCLUDE
	#include "UnityPBSLighting.cginc"

	uniform float4 GameWind;
	uniform float4 GameWindOffset;
	uniform float3 _FloatingOriginOffset;

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
			"Queue"="AlphaTest-5"
			"IgnoreProjector"="True"
			"DisableBatching" = "True"
			"RenderType"="Tasharen Grass"
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
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			half _Cutoff;
			half4 _GrassFadeDistance;
			float3 _GrassOrigin;

			struct v2f
			{
				V2F_SHADOW_CASTER;
				half3 data : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert (appdata_full v)
			{
				v2f o;
				v.vertex = AnimateTree(v.vertex, v.color.a);
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				o.data.xy = v.texcoord;

				float4 wp = mul(unity_ObjectToWorld, v.vertex);
				o.data.z = min(length(wp.xyz - _WorldSpaceCameraPos.xyz), length(wp.xyz - _GrassOrigin));
				return o;
			}

			float4 frag (v2f i) : COLOR
			{
				half fadeAlpha = 1.0 - saturate((i.data.z - _GrassFadeDistance.x) * _GrassFadeDistance.w);
				clip(tex2D(_MainTex, i.data.xy).a * fadeAlpha - _Cutoff);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}

		//==============================================================================================

		CGPROGRAM
		#pragma target 4.0
		#pragma surface surf Tasharen vertex:vert fullforwardshadows
		#pragma multi_compile_instancing
		#include "Tasharen Lighting.cginc"

		sampler2D _MainTex, _ColorMask;
		sampler2D _GrassTexColor;
		float4 _GrassTexParams;
		//half _Hue;
		half _Brightness;
		half _Cutoff;
		half4 _GrassFadeDistance;
		float3 _GrassOrigin;
		//fixed4 _Weather;

		struct Input
		{
			half4 color;
			float4 wp;
			float distance;
			UNITY_VERTEX_OUTPUT_STEREO
		};

		//==============================================================================================

		inline half3 HueShift (half3 col, half hue, half sat)
		{
			half3 c;
			half vc = sat * cos(hue * 6.2831853);
			half vs = sat * sin(hue * 6.2831853);

			half3 mul;
			mul.x = 0.299 + 0.701 * vc + 0.168 * vs;
			mul.y = 0.587 - 0.587 * vc + 0.330 * vs,
			mul.z = 0.114 - 0.114 * vc - 0.497 * vs;

			c.x = dot(mul, col);

			mul.x = 0.299 - 0.299 * vc - 0.328 * vs;
			mul.y = 0.587 + 0.413 * vc + 0.035 * vs;
			mul.z = 0.114 - 0.114 * vc + 0.292 * vs;

			c.y = dot(mul, col);

			mul.x = 0.299 - 0.3 * vc + 1.25 * vs;
			mul.y = 0.587 - 0.588 * vc - 1.05 * vs;
			mul.z = 0.114 + 0.886 * vc - 0.203 * vs;

			c.z = dot(mul, col);
			return c;
		}

		//==============================================================================================

		/*inline half3 HueShift (half hue, half sat)
		{
			half3 c;
			half vc = sat * cos(hue * 6.2831853);
			half vs = sat * sin(hue * 6.2831853);

			half3 mul;
			c.x = 0.299 + 0.701 * vc + 0.168 * vs;
			c.y = 0.299 - 0.299 * vc - 0.328 * vs;
			c.z = 0.299 - 0.3 * vc + 1.25 * vs;
			return c;
		}*/

		//==============================================================================================

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			v.vertex = AnimateTree(v.vertex, v.color.a);
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

			float4 wp = mul(unity_ObjectToWorld, v.vertex);

			o.color = v.color;
			o.wp.xy = wp.xz;
			o.wp.zw = v.texcoord.xy;
			o.distance = min(length(wp.xyz - _WorldSpaceCameraPos.xyz), length(wp.xyz - _GrassOrigin));
		}

		//==============================================================================================

		void surf (Input IN, inout Output o)
		{
			half fadeAlpha = 1.0 - saturate((IN.distance - _GrassFadeDistance.x) * _GrassFadeDistance.w);
			half4 tex = tex2D(_MainTex, IN.wp.zw);
			clip(tex.a * fadeAlpha - _Cutoff);

			half4 mask = tex2D(_ColorMask, IN.wp.zw);

			float2 grassColorUV = (IN.wp.xy - _GrassTexParams.xy) / _GrassTexParams.z;
			grassColorUV = grassColorUV * 0.5 + 0.5;

			// Multiplying color by 2.2 compensates for the loss of brightness due to multiplication
			half4 grassColor = tex2D(_GrassTexColor, grassColorUV);
			o.Albedo = lerp(saturate(tex.ggg * grassColor.rgb * 2.2 * _Brightness), tex.rgb, mask.a);
			o.Alpha = tex.a;

			// Weather makes everything shinier
			//half wetness = _Weather.y * 0.95;
			//o.Smoothness = lerp(o.Smoothness, 1.0, wetness);
			//o.Specular.a = lerp(o.Specular.a, 0.7, wetness);
			//o.Specular.rgb = (_Weather.y * 0.05).xxx;
		}
		ENDCG
	}
	Fallback off
}
