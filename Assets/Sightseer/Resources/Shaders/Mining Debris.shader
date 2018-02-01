Shader "Game/Mining Debris"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_SpecTex ("Specular", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		[NoScaleOffset] _DamageTex ("Damage Texture (RGBA)", 2D) = "black" {}
		_Color ("Color", Color) = (1,1,1,1)
		_Specular ("Specular Color", Color) = (0.0664, 0.0664, 0.0664, 0.64)
		_Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.665
		_TriplanarScale ("Triplanar Scale", Vector) = (0.5, 0.25, 1, 1)
		_Iron0 ("Iron hue 0", Color) = (1, 1, 1, 1)
		_Iron1 ("Iron hue 1", Color) = (1, 1, 1, 1)
		_Ice0 ("Ice hue 0", Color) = (1, 1, 1, 1)
		_Ice1 ("Ice hue 1", Color) = (1, 1, 1, 1)
	}

	SubShader
	{
		LOD 200
		Cull Back

		Tags
		{

			"Queue" = "AlphaTest"
			"RenderType" = "Tasharen Dissolve Alpha"
			"IgnoreProjector" = "True"
		}

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
			#include "Tasharen Damage.cginc"

			sampler2D _MainTex, _DamageTex;
			half4 _TriplanarScale;
			half4 _Color;

			struct v2f
			{
				V2F_SHADOW_CASTER;
				half4 color : TEXCOORD1;
				V2F_TRIPLANAR(2, 3)
				UNITY_VERTEX_OUTPUT_STEREO
				V2F_DITHER_COORDS_IDX(4)
			};

			v2f vert (appdata_full v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_DITHER(o, v.vertex);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				TRANSFER_TRIPLANAR(v, o);
				o.color = v.color;
				return o;
			}

			float4 frag (v2f i) : COLOR
			{
				TRIPLANAR_SAMPLE_CLIP(i, _DamageTex, _Color.a * i.color.a, _TriplanarScale.y);
				APPLY_DITHER(i);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}

		CGPROGRAM
		#pragma surface surf Tasharen vertex:vert fullforwardshadows
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma multi_compile_instancing
		#pragma target 4.0

		//#define UNITY_GI_MODEL
		//#define GI_SOURCE TOD_Reflection

		#include "Tasharen Lighting.cginc"
		#include "Tasharen Damage.cginc"

		sampler2D _MainTex;
		sampler2D _SpecTex;
		sampler2D _BumpMap;
		sampler2D _DamageTex;
		half4 _Color;
		half4 _Specular;
		half _Smoothness;
		half4 _TriplanarScale;
		fixed4 _Iron0, _Iron1, _Ice0, _Ice1;

		struct Input
		{
			float2 uv_MainTex : TEXCOORD0;
			float2 uv_SpecTex : TEXCOORD1;
			float2 uv_BumpMap : TEXCOORD2;
			fixed4 color : COLOR;
			V2F_COMMON_IDX(3)
			V2F_TRIPLANAR(4, 5)
		};

		void vert (inout appdata_full v, out Input o)
		{
			INITIALIZE_VERTEX(Input, v, o);
			TRANSFER_TRIPLANAR(v, o);
		}

		void surf (Input IN, inout Output o)
		{
			TRIPLANAR_SAMPLE_CLIP(IN, _DamageTex, _Color.a * IN.color.a, _TriplanarScale.y);

			half ctrl = IN.color.r * 2.0 - 1.0;
			half4 tex = tex2D(_MainTex, IN.uv_MainTex);
			half invSlopeR = 1.0 - tex.r;
			invSlopeR *= invSlopeR;
			invSlopeR *= invSlopeR;
			invSlopeR *= invSlopeR;
			half3 ironColorTint = lerp(_Iron0.rgb, _Iron1.rgb, invSlopeR);
			half3 rockColorTint = lerp(ironColorTint, lerp(_Ice0.rgb, _Ice1.rgb, invSlopeR), max(0.0, ctrl));
			rockColorTint = lerp(tex.rgb, rockColorTint, 0.5 * abs(ctrl));

			half4 spec = tex2D(_SpecTex, IN.uv_SpecTex);
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			o.Albedo = rockColorTint.rgb * _Color.rgb;
			o.Specular = _Specular * spec;
			o.Specular.rgb *= o.Specular.a;
			o.Smoothness = _Smoothness;
			o.Alpha = _Color.a;
			APPLY_DITHER(IN);
		}
		ENDCG
	}
	FallBack "Tasharen/Diffuse"
}
