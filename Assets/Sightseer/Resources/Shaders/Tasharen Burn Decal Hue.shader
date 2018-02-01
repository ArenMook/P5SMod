// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Tasharen/Decal/Burn Mark Hue"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BurnTex ("Burn (RGB)", 2D) = "white" {}
		_FalloffTex ("Falloff (Alpha)", 2D) = "white" {}
		[HDR] _Color ("Main Color", Color) = (1, 1, 1, 1)
		_Heat ("Heat Intensity", Range(0.0, 1.0)) = 1.0

		_Hue("Hue", Range(0, 1)) = 0.0
        _Sat("Saturation", Range(0, 2)) = 1.0
		_Brt("Brightness", Range(0, 10)) = 1.0
	}

	CGINCLUDE
	half3 HueShift (half3 col, half hue, half sat, half val)
	{
		half3 c;
		half vc = sat * cos(hue * 6.2831853);
		half vs = sat * sin(hue * 6.2831853);

		half3 mul;
		mul.x = 0.299 * val + 0.701 * vc + 0.168 * vs;
		mul.y = 0.587 * val - 0.587 * vc + 0.330 * vs,
		mul.z = 0.114 * val - 0.114 * vc - 0.497 * vs;

		c.x = dot(mul, col);

		mul.x = 0.299 * val - 0.299 * vc - 0.328 * vs;
		mul.y = 0.587 * val + 0.413 * vc + 0.035 * vs;
		mul.z = 0.114 * val - 0.114 * vc + 0.292 * vs;

		c.y = dot(mul, col);

		mul.x = 0.299 * val - 0.3 * vc + 1.25 * vs;
		mul.y = 0.587 * val - 0.588 * vc - 1.05 * vs;
		mul.z = 0.114 * val + 0.886 * vc - 0.203 * vs;

		c.z = dot(mul, col);
		return c;
	}
	ENDCG

	SubShader
	{
		Tags
		{
			"Queue"="Geometry+10"
			"IgnoreProjector"="True"
			"RenderType"="Opaque"
			"PreviewType" = "Plane"
		}

		LOD 200
		Cull Off
		Lighting Off
		ZWrite Off
		Fog { Mode Off }
		Blend SrcAlpha OneMinusSrcAlpha
		
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex, _BurnTex, _FalloffTex;
			half4 _Color, TOD_LightColor;
			half _Heat;
			float4x4 unity_Projector;
			float4x4 unity_ProjectorClip;
			half _Hue, _Sat, _Brt;

			struct appdata_t
			{
				float4 vertex : POSITION;
				float4 tc0 : TEXCOORD0;
				half4 color : COLOR;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 tc0 : TEXCOORD0;
				float4 tc1 : TEXCOORD1;
				half4 color : COLOR;
			};

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.tc0 = mul(unity_Projector, v.vertex);
				o.tc1 = mul(unity_ProjectorClip, v.vertex);
				o.color = v.color;
				return o;
			}

			half4 frag (v2f IN) : COLOR
			{
				half4 uv = UNITY_PROJ_COORD(IN.tc0);
				half4 tex = tex2Dproj(_MainTex, uv);
				tex.rgb *= TOD_LightColor.rgb;

				half heatAlpha = saturate(_Color.a * 2.0 - 1.0);
				half heat = _Heat * heatAlpha * heatAlpha;
				heat *= heat;
				half brightness = tex2Dproj(_BurnTex, uv).a * heat;
				tex.rgb += _Color.rgb * (brightness * brightness);
				tex.rgb = HueShift(tex.rgb, _Hue, _Sat, _Brt);

				half alpha = 1.0 - _Color.a;
				alpha *= alpha;
				alpha *= alpha;
				alpha *= alpha;
				alpha = 1.0 - alpha;

				tex.a *= tex2Dproj(_FalloffTex, UNITY_PROJ_COORD(IN.tc1)).a * alpha;
				return tex;
			}
			ENDCG
		}
	} 
	FallBack Off
}
