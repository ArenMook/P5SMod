Shader "Tasharen/Particles/Beam"
{
	Properties
	{
		_MainTex ("Base (RGBA)", 2D) = "white" {}
		_DistortTex1("Distort Texture1", 2D) = "white" {}
		_DistortTex2("Distort Texture2", 2D) = "white" {}
		[HDR] _TintColor ("Tint Color", Color) = (1,1,1,1)
		_DistortSpeed("Distort Speed Scale (xy/zw)", Vector) = (10.0, -0.05, 50.0, 0.03)
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
				sampler2D _DistortTex1;
				sampler2D _DistortTex2;
				sampler2D _CameraDepthTexture;

				float4 _MainTex_ST;
				float4 _DistortTex1_ST;
				float4 _DistortTex2_ST;
				half4 _TintColor, TOD_LightColor, _LightEffect;
				float _InvFade;
				float _FadeDistance;
				float4 _DistortSpeed;
			
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
					float4 uvDistort : TEXCOORD1;
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
					o.uvDistort.xy = TRANSFORM_TEX(v.texcoord, _DistortTex1);
					o.uvDistort.zw = TRANSFORM_TEX(v.texcoord, _DistortTex2);
					UNITY_TRANSFER_FOG(o, o.vertex);
					return o;
				}

				half4 frag (v2f i) : COLOR
				{
					half4 distort1 = tex2D(_DistortTex1, i.uvDistort.xy + _DistortSpeed.x * _Time.xx) * 2 - 1;
					half4 distort2 = tex2D(_DistortTex1, i.uvDistort.xy - _DistortSpeed.x * _Time.xx * 1.4 + float2(0.4, 0.6)) * 2 - 1;
					half4 distort3 = tex2D(_DistortTex2, i.uvDistort.zw + _DistortSpeed.z * _Time.xx) * 2 - 1;
					half4 distort4 = tex2D(_DistortTex2, i.uvDistort.zw - _DistortSpeed.z * _Time.xx * 1.25 + float2(0.3, 0.7)) * 2 - 1;
					half4 tex = tex2D(_MainTex, i.texcoord + (distort1.xy + distort2.xy) * _DistortSpeed.y + (distort3.xy + distort4.xy) * _DistortSpeed.w);

				#ifdef SOFTPARTICLES_ON
					float sceneZ = LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))));
					i.color.a *= saturate (_InvFade * (sceneZ - i.projPos.z));
				#endif
				
					half4 c = tex * i.color * _TintColor;
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
