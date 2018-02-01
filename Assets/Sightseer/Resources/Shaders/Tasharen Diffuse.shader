Shader "Tasharen/Diffuse"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
	}

	SubShader
	{
		LOD 200
		Tags { "RenderType" = "Tasharen" }
		Cull Back

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

			struct v2f
			{
				V2F_SHADOW_CASTER;
				half3 tc : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
				V2F_DITHER_COORDS_IDX(2)
			};

			v2f vert (appdata_full v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				TRANSFER_DITHER(o, v.vertex);
				o.tc = v.texcoord;
				return o;
			}

			float4 frag (v2f i) : COLOR
			{
				APPLY_DITHER(i);
				SHADOW_CASTER_FRAGMENT(i);
			}
			ENDCG
		}

		CGPROGRAM
		#pragma surface surf Tasharen vertex:vert fullforwardshadows
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma target 3.0

		#include "Tasharen Lighting.cginc"

		sampler2D _MainTex;
		half4 _Color;

		struct Input
		{
			float2 uv_MainTex;
			V2F_DITHER_COORDS
		};

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			TRANSFER_DITHER(o, v.vertex)
		}

		void surf (Input IN, inout Output o)
		{
			half4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb;
			o.Alpha = _Color.a;
			APPLY_DITHER(IN)
		}
		ENDCG
	}
	Fallback "Diffuse"
}
