Shader "Tasharen/Particles/Simple"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (1,1,1,1)
		_Brightness ("Brightness", Range(0.0, 10.0)) = 1.0
		_InvFade ("Soft Particles Factor", Range(0.01, 3.0)) = 1.0
	}
	
	Category
	{
		Tags
		{
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
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
float _InvFade, _Brightness;

struct appdata_t
{
	float4 vertex : POSITION;
	half4 color : COLOR;
	float2 texcoord : TEXCOORD0;
};

struct v2f
{
	float4 vertex : SV_POSITION;
	half4 color : COLOR;
	float2 texcoord : TEXCOORD0;
	UNITY_FOG_COORDS(1)
#ifdef SOFTPARTICLES_ON
	float4 projPos : TEXCOORD2;
#endif
};
			
v2f vert (appdata_t v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);

#ifdef SOFTPARTICLES_ON
	o.projPos = ComputeScreenPos (o.vertex);
	COMPUTE_EYEDEPTH(o.projPos.z);
#endif

	o.color = v.color;
	o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
	UNITY_TRANSFER_FOG(o, o.vertex);
	return o;
}

half4 frag (v2f i) : SV_Target
{
#ifdef SOFTPARTICLES_ON
	float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
	i.color.a *= saturate (_InvFade * (sceneZ - i.projPos.z));
#endif
				
	half4 col = i.color * _Color * tex2D(_MainTex, i.texcoord);
	col.rgb *= (unity_AmbientSky.rgb + _LightColor0.rgb);
	col.rgb *= _Brightness;
	UNITY_APPLY_FOG(i.fogCoord, col);
	return col;
}
ENDCG
			}
		}
	}
	FallBack "Transparent"
}
