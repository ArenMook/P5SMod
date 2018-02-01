Shader "Tasharen/Burnout"
{
	Properties
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		[HDR] _BurnColor ("Burn Color", Color) = (20.0, 1, 0, 1)
		_MainTex ("Base (RGBA)", 2D) = "white" {}
		_Specular ("Specular Color", Color) = (0.15, 0.15, 0.15, 0.15)
		_Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.2
	}

	SubShader
	{
		LOD 200

		Tags
		{

			"Queue" = "AlphaTest"
			"RenderType" = "TransparentCutout"
			"IgnoreProjector" = "True"
		}

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
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			half4 _MainTex_ST;
			half4 _Color;

			struct v2f
			{
				V2F_SHADOW_CASTER;
				half2 tc : TEXCOORD1;
				half4 color : COLOR;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert (appdata_full v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				o.tc = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.color = v.color;
				return o;
			}

			float4 frag (v2f i) : COLOR
			{
				clip(_Color.a * i.color.a - tex2D(_MainTex, i.tc).a * 0.98 - 0.01);
				SHADOW_CASTER_FRAGMENT(i);
			}
			ENDCG
		}

		CGPROGRAM
		#pragma surface surf Tasharen vertex:vert fullforwardshadows
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma target 3.0

		//#define UNITY_GI_MODEL
		//#define GI_SOURCE TOD_Reflection

		#include "Tasharen Lighting.cginc"

		sampler2D _MainTex;
		half4 _MainTex_ST;
		half4 _Color, _BurnColor, _Specular;
		half _Smoothness;

		struct Input
		{
			half2 tc : TEXCOORD0;
			half4 color : COLOR;
			V2F_DITHER_COORDS
		};

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			TRANSFER_DITHER(o, v.vertex);
			o.tc = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.color = v.color;
		}

		void surf (Input IN, inout Output o)
		{
			half4 c = tex2D(_MainTex, IN.tc);
			half burn = _Color.a * IN.color.a;
			clip(burn - c.a * 0.98 - 0.01);

			o.Albedo = c.rgb * _Color.rgb * IN.color.rgb;
			o.Alpha = 1.0;

			o.Emission = _BurnColor.rgb * saturate((c.a - burn + 0.2) * 10.0 * saturate((1.0 - burn) * 20.0));
			o.Specular = _Specular;
			o.Specular.rgb *= o.Specular.a;
			o.Smoothness = _Smoothness * (1.0 - c.a);

			APPLY_DITHER(IN);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
