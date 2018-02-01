// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Tasharen/Particles/Unlit"
{
	Properties
	{
		_MainTex("Particle Texture", 2D) = "white" {}
		_Color ("Color", Color) = (1,1,1,1)
		_Brightness ("Brightness", Range(0.0, 10.0)) = 1.0
		_InvFade("Soft Particles Factor", Range(0.01, 3.0)) = 1.0
		_FadeDistance("Fade Start Distance", Range(0.01, 10.0)) = 0.5
	}

	Category
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
		}

		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
		Lighting Off 
		ZWrite Off

		SubShader
		{
			Pass
			{
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_particles
#pragma multi_compile_fog

#include "UnityCG.cginc"
#include "Lighting.cginc"

sampler2D _MainTex;
sampler2D_float _CameraDepthTexture;
float4 _MainTex_ST;
half4 _Color;
half _Brightness;
float _InvFade;
float _FadeDistance;

struct appdata_t
{
	float4 vertex	: POSITION;
	float2 texcoord	: TEXCOORD0;
	half4 color		: COLOR;
};

struct v2f
{
	float4 vertex	: SV_POSITION;
	float2 texcoord	: TEXCOORD0;
	half4 color		: COLOR;
#ifdef SOFTPARTICLES_ON
	float4 projPos  : TEXCOORD1;
#endif
};

v2f vert (appdata_t v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);

#ifdef SOFTPARTICLES_ON
	o.projPos = ComputeScreenPos(o.vertex);
	COMPUTE_EYEDEPTH(o.projPos.z);
#endif

	o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
	o.color = v.color;

	// Fade out the closer it is to the near clip plane.
	o.color.a *= min(1.0, (-UnityObjectToViewPos(v.vertex).z - _ProjectionParams.y) / _FadeDistance);
	return o;
}

half4 frag (v2f i) : SV_Target
{
	half4 c = tex2D(_MainTex, i.texcoord) * _Color * i.color;
	c.rgb *= _Brightness;
#ifdef SOFTPARTICLES_ON				
	float sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))));
	c.a *= clamp((_InvFade * (sceneZ - i.projPos.z)), 0.0, 1.0);
#endif
	return c;
}
ENDCG
			}
		}
	}
}
