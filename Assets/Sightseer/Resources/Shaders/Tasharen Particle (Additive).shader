// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Tasharen/Particles/Additive"
{
	Properties
	{
		_MainTex ("Base (RGBA)", 2D) = "white" {}
		[HDR] _TintColor ("Tint Color", Color) = (1,1,1,1)
		_InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0
		_FadeDistance ("Fade Out Distance", Range(1.0, 150.0)) = 150.0
		_LightEffect ("Light Effect (R = Day, G = Night)", Vector) = (0, 0, 0, 0)
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

		Blend SrcAlpha One
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
				//#include "Tasharen Fog.cginc"

				sampler2D _MainTex;
				sampler2D _CameraDepthTexture;

				float4 _MainTex_ST;
				half4 _TintColor, TOD_LightColor, _LightEffect;
				float _InvFade;
				float _FadeDistance;
			
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
				#ifdef SOFTPARTICLES_ON
					float4 projPos : TEXCOORD2;
				#endif
					float3 viewDir : TEXCOORD3;
				};
			
				v2f vert (appdata_t v)
				{
					v2f o;
					o.viewDir = mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos.xyz;
					o.vertex = UnityObjectToClipPos(v.vertex);
				#ifdef SOFTPARTICLES_ON
					o.projPos = ComputeScreenPos (o.vertex);
					COMPUTE_EYEDEPTH(o.projPos.z);
				#endif
					o.color = v.color;
					o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
					UNITY_TRANSFER_FOG(o, o.vertex);
					return o;
				}

				half4 frag (v2f i) : COLOR
				{
				#ifdef SOFTPARTICLES_ON
					float sceneZ = LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))));
					i.color.a *= saturate (_InvFade * (sceneZ - i.projPos.z));
				#endif
				
					half4 c = tex2D(_MainTex, i.texcoord) * i.color * _TintColor;
					c.rgb = lerp(c.rgb, c.rgb * TOD_LightColor.rgb, lerp(_LightEffect.g, _LightEffect.r, TOD_LightColor.a));

					float dist = length(i.viewDir);
					float fade = saturate(dist / _FadeDistance);
					c.a *= 1.0 - fade * fade;

					//c.rgb = ApplyFog(c.rgb, i.viewDir / dist, ComputeFogFactor(dist * 1.5));
					return c;
				}
				ENDCG 
			}
		}
	}
}
