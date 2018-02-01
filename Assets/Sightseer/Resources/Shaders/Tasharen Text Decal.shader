Shader "Tasharen/Text Decal"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		[NoScaleOffset] _MainTex ("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset] _BlendTex0 ("Detail 0 (RGB), Smoothness (A)", 2D) = "white" {}
		_Cutoff ("Base Alpha cutoff", Range (0, 0.9)) = 0.5
		_Specular ("Specular", Color) = (0.2,0.2,0.2,1)
		_Smoothness ("Smoothness", Range(0,1)) = 0.81
		_BlendScale ("Blend Scale", Range(0, 4)) = 1.0
		_BlendAlpha ("Blend Alpha", Range(0, 1)) = 0.5
	}
	SubShader
	{
		Tags
		{
			"Queue" = "AlphaTest+20"
			"RenderType" = "Opaque"
		}

		LOD 200
		Offset -1, -1
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
		ZWrite Off

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
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"
			#include "Tasharen Dither.cginc"

			sampler2D _MainTex;
			half _Cutoff;
			half4 _Color;

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color: COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				V2F_SHADOW_CASTER;
				UNITY_VERTEX_OUTPUT_STEREO
				half2 uv : TEXCOORD1;
				half4 color : TEXCOORD2;
				V2F_DITHER_COORDS_IDX(3)
			};

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_DITHER(o, v.vertex);
				TRANSFER_SHADOW_CASTER(o)
				o.uv = v.texcoord;
				o.color = v.color;
				return o;
			}

			float4 frag (v2f i) : COLOR
			{
				half4 c = i.color * _Color;
				c.a *= tex2D(_MainTex, i.uv).a;
				APPLY_DITHER(i);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Tasharen vertex:vert fullforwardshadows
		#pragma target 4.0
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE

		#include "Tasharen Lighting.cginc"

		sampler2D _MainTex, _BlendTex0;

		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
			float2 texcoord1 : TEXCOORD1;
			fixed4 color: COLOR;
		};

		struct Input
		{
			half2 uv_MainTex : TEXCOORD0;
			float2 tc2 : TEXCOORD1;
			half4 color : COLOR;
			V2F_DITHER_COORDS_IDX(2)
		};

		half4 _Color, _Specular;
		half _Smoothness, _Cutoff;
		half _BlendScale, _BlendAlpha;

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			TRANSFER_DITHER(o, v.vertex);
			o.color = v.color;
			o.tc2 = v.texcoord1 * _BlendScale;
		}

		void surf (Input IN, inout Output o)
		{
			// Albedo comes from a texture tinted by color
			half4 tex = tex2D(_MainTex, IN.uv_MainTex);
			half4 c = IN.color * _Color;
			c.a *= max(tex.r, max(tex.g, tex.b)) * tex.a;
			clip(c.a - _Cutoff);

			half4 tc2 = tex2D(_BlendTex0, IN.tc2);
			c.rgb *= lerp((1.0).xxx, tc2.rgb, _BlendAlpha);

			o.Albedo = c.rgb;
			o.Smoothness = _Smoothness;
			o.Specular = _Specular;
			o.Alpha = c.a;

			APPLY_DITHER(IN);
		}
		ENDCG
	}
	FallBack Off
}
