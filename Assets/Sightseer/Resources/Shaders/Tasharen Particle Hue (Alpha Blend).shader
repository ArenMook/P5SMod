Shader "Tasharen/Particles/Alpha Blended Hue"
{
	Properties
	{
		_MainTex ("Base (RGBA)", 2D) = "white" {}
		[HDR] _TintColor ("Tint Color", Color) = (1,1,1,1)

		_Hue("Hue", Range(0, 1)) = 0.0
		_Sat("Saturation", Range(0, 2)) = 1.0
		_Brt("Brightness", Range(0, 2)) = 1.0

		_InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0
		_LightEffect ("Sunlight Tint", Range(0.0, 1.0)) = 0.0
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

				sampler2D _MainTex;
				sampler2D _CameraDepthTexture;

				float4 _MainTex_ST;
				half4 _TintColor, TOD_LightColor;
				float _InvFade, _LightEffect;
				half _Hue, _Sat, _Brt;
			
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
					o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
					UNITY_TRANSFER_FOG(o, o.vertex);
					return o;
				}
			
				half4 frag (v2f i) : COLOR
				{
					#ifdef SOFTPARTICLES_ON
					float sceneZ = LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))));
					float partZ = i.projPos.z;
					float fade = saturate (_InvFade * (sceneZ - partZ));
					i.color.a *= fade;
					#endif

					half4 c = tex2D(_MainTex, i.texcoord) * i.color;
					c.rgb = HueShift(c.rgb, _Hue, _Sat, _Brt);
					c *= _TintColor;
					c.rgb = lerp(c.rgb, c.rgb * TOD_LightColor.rgb, _LightEffect);
					c.a = saturate(c.a);
					return c;
				}
				ENDCG 
			}
		}	
	}
}
