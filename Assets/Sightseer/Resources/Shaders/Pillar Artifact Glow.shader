Shader "Tasharen/Pillar Artifact Glow"
{
	Properties
	{
		[HDR] _Color ("Color", Color) = (1,1,1,1)
		[HideInInspector] _GlowBrightness ("Glow Brightness", Range(0,1)) = 1.0
	}

	SubShader
	{
		LOD 200
		Tags
		{
			"Queue"="Transparent"
			"IgnoreProjector"="True"
			"RenderType"="Transparent"
		}

		Offset -0.1, -1
		Cull Back
		Blend SrcAlpha One
		ZWrite Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_particles
			#pragma multi_compile_fog
			#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
			#include "UnityCG.cginc"
			#include "Tasharen Dither.cginc"

			half4 _Color;
			half _GlowBrightness;
			
			struct appdata_t
			{
				float4 vertex : POSITION;
				half4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				half4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				V2F_DITHER_COORDS_IDX(1)
			};
			
			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				o.texcoord = v.texcoord;
				TRANSFER_DITHER(o, v.vertex);
				return o;
			}
			
			half4 frag (v2f i) : COLOR
			{
				APPLY_DITHER(i);
				half4 c = i.color * _Color;
				clip(_GlowBrightness * c.a - i.texcoord.x);
				c.a = 1.0;
				return c;
			}
			ENDCG 
		}
	}
	FallBack "Diffuse"
}
