// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Tasharen/Scanline (Secondary Material)"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (1,1,1,1)
	}

	SubShader
	{
		Tags
		{
			"RenderType" = "Transparent"
			"Queue" = "Transparent+1"
			"IgnoreProjector" = "True"
		}

		Offset -1, -1

		// Depth fail
		Pass
		{
			Cull Back
			ZTest Greater
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			half4 _Color;

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
			};

			v2f vert (appdata_full v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = mul(unity_ObjectToWorld, half4(v.normal, 0.0)).xyz;
				return o;
			}

			half4 frag (v2f IN) : COLOR
			{
				float3 dir = normalize(IN.worldPos - _WorldSpaceCameraPos);
				float dp = 1.0 - saturate(-dot(normalize(IN.worldNormal), dir));
				dp = 1.0 - dp * dp;

				float screenY = (IN.screenPos.y / IN.screenPos.w) * _ScreenParams.y;
				half4 tex = lerp(
					tex2D(_MainTex, half2(0.5, screenY * 0.2 + _Time.w)),
					tex2D(_MainTex, half2(0.5, screenY * 0.02 - _Time.w)), 0.2);

				half4 c;
				c.rgb = lerp(half3(0.25 + _Color.g * 0.75, 0.0, 0.0), _Color.rgb * tex.rgb, tex.r);
				c.a = dp * _Color.a * 0.1;
				return c;
			}
			ENDCG
		}

		// Depth pass
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
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			half4 _Color;

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD0;
			};

			v2f vert (appdata_full v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}

			half4 frag (v2f IN) : COLOR
			{
				float screenY = (IN.screenPos.y / IN.screenPos.w) * _ScreenParams.y;
				half4 tex = lerp(
					tex2D(_MainTex, half2(0.5, screenY * 0.2 + _Time.w)),
					tex2D(_MainTex, half2(0.5, screenY * 0.02 - _Time.w)), 0.2);

				half4 c;
				c.rgb = _Color.rgb * tex.rgb;
				c.a = _Color.a * 0.35;
				return c;
			}
			ENDCG
		}
	}
	FallBack Off
}
