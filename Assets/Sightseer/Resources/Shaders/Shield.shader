Shader "Game/Shield"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		[NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
		[NoScaleOffset] _Noise ("Noise", 2D) = "bump" {}
		[HDR] _Color0 ("Idle Color", Color) = (0.7, 0.7, 0.7, 1.0)
		[HDR] _Color ("Hit Color", Color) = (1.0, 0.5, 0.0, 1.0)
		_Distortion ("Distortion", Range(0.01, 0.2)) = 0.1
		_WaveSize ("Wave size", Range(0.1, 1.0)) = 0.5
		_WaveSpeed ("Wave speed", Range(0.5, 10.0)) = 2.5
		_WaveDisplacement ("Wave displacement", Range(0.01, 0.5)) = 0.1
		_ZBufferFade ("Soft Particles Factor", Range(0.01, 3.0)) = 3.0
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"DisableBatching" = "True"
		}

		LOD 100

		GrabPass
		{
			Name "BASE"
			Tags { "LightMode" = "Always" }
		}

		Pass
		{
			Cull Back
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
			#include "UnityCG.cginc"
			#include "Tasharen Dither.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
				float3 localPos : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				float4 worldTangent : TEXCOORD4;
				float4 screenPos : TEXCOORD5;
				V2F_COMMON_IDX(6)
			};

			sampler2D _MainTex;
			sampler2D _BumpMap;
			sampler2D _Noise;
			float4 _MainTex_ST;
			float4 _ShieldPoints[32];
			half4 _Color0, _Color;
			half _ZBufferFade;
			half _Distortion;
			half _WaveSize;
			half _WaveSpeed;
			half _WaveDisplacement;

			sampler2D _GrabTexture : register(s0);
			sampler2D _CameraDepthTexture;

			inline float CalculateRipple (float3 localPos)
			{
				float strength = 0.0;

				for (int i = 0; i < 32; ++i)
				{
					float4 sp = _ShieldPoints[i];
					float current = length(sp.xyz - localPos);
					float ideal = (1.0 - sp.w) * _WaveSpeed;
					float diff = saturate((ideal - current) / _WaveSize);
					if (diff < 0.5) strength += smoothstep(0.0, 1.0, diff * 2.0) * sp.w;
					else strength += smoothstep(1.0, 0.0, (diff - 0.5) * 2.0) * sp.w;
				}
				return saturate(strength);
			}

			inline half3 TransformByTBN(half3 normalMap, half3 worldNormal, half3 worldTangent)
			{
				half3 worldBinormal = cross(worldTangent, worldNormal);
				half3 tSpace0 = half3(worldTangent.x, worldBinormal.x, worldNormal.x);
				half3 tSpace1 = half3(worldTangent.y, worldBinormal.y, worldNormal.y);
				half3 tSpace2 = half3(worldTangent.z, worldBinormal.z, worldNormal.z);
				return half3(dot(tSpace0, normalMap), dot(tSpace1, normalMap), dot(tSpace2, normalMap));
			}

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float ripple = CalculateRipple(v.vertex.xyz);
				v.vertex.xyz -= v.normal * _WaveDisplacement * ripple;

				TRANSFER_DITHER(o, v.vertex);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
				COMPUTE_EYEDEPTH(o.screenPos.z);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				o.localPos = v.vertex.xyz;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent.xyz = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldTangent.w = v.tangent.w;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				APPLY_DITHER(i);

				float2 offset = half2(_Time.x * 1.34615, _Time.x * 1.27167);
				float2 noise = (tex2D(_Noise, i.uv + offset).wy * 2.0 - 1.0);
				i.uv += noise * 0.01;

				fixed4 col = tex2D(_MainTex, i.uv);
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				i.worldNormal = normalize(i.worldNormal);
				i.worldTangent.xyz = normalize(i.worldTangent.xyz);

				// Soft particles style fade should affect the shield as well
				float sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos))));
				float depthFade = clamp((_ZBufferFade * (sceneZ - i.screenPos.z)), 0.0, 1.0) * saturate((i.screenPos.z - _ProjectionParams.y) * 2.0);

				// Shield effect should fade out closer to the edges of the shield and as the dot product nears 0
				float factor = saturate(dot(viewDirection, i.worldNormal) - 0.1) * (1.0 - i.color.a);
				factor = 1.0 - factor;
				factor *= factor;
				factor *= factor;
				factor *= factor;
				factor = 1.0 - factor;
				col.a *= factor;

				// Calculate the distortion
				float2 distortion = tex2D(_BumpMap, i.uv).wy * 2.0 - 1.0;
				float alpha = CalculateRipple(i.localPos.xyz);
				distortion += noise * 0.25;

				// Recover the normal map's Z component from XY
				float3 n;
				n.xy = distortion;
				n.z = sqrt(1.0 - n.x * n.x - n.y * n.y);

				// Calculate the two sets of bump map normals -- forward and back facing ones
				float3 bentNormal = TransformByTBN(n, i.worldNormal, i.worldTangent.xyz);
				float3 bentOpposite = TransformByTBN(float3(-n.x, -n.y, n.z), i.worldNormal, i.worldTangent.xyz);

				// Use the view projection matrix to transform them to clip space
				float3x3 vp = (float3x3)UNITY_MATRIX_VP;
				bentNormal = mul(vp, bentNormal);
				bentOpposite = mul(vp, bentOpposite);
		//#if UNITY_UV_STARTS_AT_TOP
				bentNormal.y *= i.worldTangent.w;
				bentOpposite.y *= i.worldTangent.w;
		//#endif
				// Final normal is a mix of the two, effectively creating a lens bending effect
				n = lerp(bentNormal, bentOpposite, alpha * 0.75);

				// Fade out the distortion as it gets closer to the edges of the screen
				half2 pos = saturate(i.screenPos.xy / i.screenPos.w);
				pos = abs(pos * 2.0 - 1.0);
				half fade = max(pos.x, pos.y);
				fade = (1.0 - fade * fade * fade);

				// Apply the distortion
				//i.screenPos.xy += n.xy * fade;

				// Prevent objects that are in front from being in the refraction
				float4 distortedUV = i.screenPos;
				distortedUV.xy += n.xy * (fade * _Distortion);
				sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(distortedUV))));
				if (sceneZ > i.screenPos.z) i.screenPos = distortedUV;

				// Sample the grabbed screen texture
				return lerp(_Color0, _Color, alpha) * fixed4(tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(i.screenPos)).rgb, col.a * col.r * depthFade);
			}
			ENDCG
		}
	}
}
