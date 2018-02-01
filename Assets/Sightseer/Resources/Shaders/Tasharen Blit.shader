// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Tasharen/Blit"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "black" {}
	}

	SubShader
	{
		ZTest Off
		Cull Off
		ZWrite Off
		Fog { Mode Off }

		Pass
		{
CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"

uniform sampler2D _MainTex;
uniform float4 _MainTex_TexelSize;

struct v2f
{
	float4 pos : SV_POSITION;
	float4 uv : TEXCOORD0;
};

v2f vert (appdata_img v)
{
	v2f o;
	half index = v.vertex.z;
	v.vertex.z = 0.0;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.texcoord.xyxy;

#if UNITY_UV_STARTS_AT_TOP
	if (_MainTex_TexelSize.y < 0.0) o.uv.y = 1.0 - o.uv.y;
#endif
	return o;
}

half4 frag (v2f i) : SV_Target
{
	return tex2D(_MainTex, i.uv.xy);
}
ENDCG
		}
	}
	Fallback off
}
