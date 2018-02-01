// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Tasharen/Particles/Round"
{
	Properties
	{
		_MainTex("Particle Texture", 2D) = "white" {}
		_Color ("Color", Color) = (1,1,1,1)
		_Brightness ("Brightness", Range(0.0, 10.0)) = 1.0
		_InvFade("Soft Particles Factor", Range(0.01, 3.0)) = 1.0
		_FadeDistance("Fade Start Distance", Range(0.01, 10.0)) = 0.5
		_Thickness ("Thickness", Range(0.0, 2.0)) = 0.5
	}

	Category
	{
		Tags
		{
			"Queue"="Transparent"
			"IgnoreProjector"="True"
			"RenderType"="Transparent"
			"PreviewType" = "Plane"
		}

		Blend SrcAlpha OneMinusSrcAlpha
		Cull Back
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
#pragma target 4.0

#define GI_INTENSITY 2.0

#include "Tasharen Lighting.cginc"
#include "Tasharen Math.cginc"

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D_float _CameraDepthTexture;
half4 _Color;
half _Brightness;
float _InvFade;
float _FadeDistance;
float _Thickness;

struct appdata_t 
{
	float4 vertex   : POSITION;
	half4 color		: COLOR;
	float2 uv 		: TEXCOORD0;
	float3 normal   : NORMAL;
	float4 tangent  : TANGENT;
};

struct v2f 
{
	float4 vertex   : SV_POSITION;
	half4 color		: COLOR;
	float2 uv 		: TEXCOORD0;
	float3 worldPos : TEXCOORD1;
	float3 normal	: TEXCOORD2;
#ifdef SOFTPARTICLES_ON
	float4 projPos  : TEXCOORD3;
#endif
	UNITY_FOG_COORDS(4)				
};

v2f vert (appdata_t v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);

#ifdef SOFTPARTICLES_ON
	o.projPos = ComputeScreenPos(o.vertex);
	COMPUTE_EYEDEPTH(o.projPos.z);
#endif

	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.color = v.color;
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	o.normal = v.normal;

	// Fade out the closer it is to the near clip plane.
	float3 viewPos = UnityObjectToViewPos(v.vertex);
	o.color.a *= min(1.0, (-viewPos.z - _ProjectionParams.y) / _FadeDistance);

	UNITY_TRANSFER_FOG(o, o.vertex);
	return o;
}

half4 frag (v2f i) : SV_Target
{
	half4 tex = tex2D(_MainTex, i.uv);
	half4 c = i.color * _Color;
	c.a *= tex.a;
	c.rgb *= _Brightness;
	
	// Spherical base normal
	float3 localNormal = float3(i.uv.xy * 2.0 - 1.0, 0.0);
	localNormal.z = (1.0 - saturate(dot(localNormal.xy, localNormal.xy)));
	c.a *= localNormal.z;
	
	// Commenting this out gives softer edges
	//localNormal.z = sqrt(localNormal.z);
	
	// Determine the spherical normal
	half3 worldNormal = normalize(TransformByTBN2(localNormal, i.normal, i.worldPos, i.uv));
	
	// Dot product between the normal and the light directions
	half NdotL = dot(worldNormal, _WorldSpaceLightPos0.xyz);
	half range180 = NdotL * 0.5 + 0.5;
	half saturated = saturate(NdotL);
	half diffuse = lerp(range180, saturated, _Thickness * lerp(1.0 - tex.a, tex.a, range180));

	// Only the side facing towards the light should have its texture-based definition
	// This approach will cause the texture to softly darken the face facing the light,
	// while the side facing away from the light will be lit using "ambient" lighting.
	c.rgb *= lerp(c.rgb, c.rgb * tex.rgb, saturated);

	// Attenuate by light
	//c.rgb *= UNITY_LIGHTMODEL_AMBIENT.rgb + _LightColor0.rgb * diffuse;
	c.rgb = lerp(c.rgb, c.rgb *  saturate(diffuse), 0.9965);

#ifdef SOFTPARTICLES_ON
	float sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))));
	c.a *= clamp((_InvFade * (sceneZ - i.projPos.z)), 0.0, 1.0);
#endif

	//UNITY_APPLY_FOG(i.fogCoord, col);
	return c;
}
ENDCG
			}
		}
	}
}
