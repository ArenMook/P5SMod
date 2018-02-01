// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Tasharen/Transparent Color (Unlit)"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Color ("Main Color", Color) = (1, 1, 1, 1)
	}

	SubShader
	{
		Tags
		{
			"Queue"="Transparent-10"
			"IgnoreProjector"="True"
			"RenderType"="Transparent"
		}

		LOD 200

		Pass
		{
			Cull Off
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform half4 _Color;

			struct appdata_t
			{
				float4 vertex : POSITION;
				float4 tc0 : TEXCOORD0;
				half4 color : COLOR;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 tc0 : TEXCOORD0;
				half4 color : COLOR;
			};

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.tc0 = v.tc0;
				o.color = v.color;
				return o;
			}

			half4 frag(v2f IN) : COLOR
			{
				half4 tex = tex2D(_MainTex, IN.tc0);
				return tex * _Color * IN.color;
			}
			ENDCG
		}
	}
	FallBack "Transparent/Diffuse"
}
