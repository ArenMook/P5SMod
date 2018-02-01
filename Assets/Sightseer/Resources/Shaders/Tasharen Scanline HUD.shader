// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Tasharen/Scanline HUD"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_DetailTex ("Detail Texture", 2D) = "white" {}
		_Scale ("Scale", Vector) = (1.0, 1.0, 1.0, 1.0)
	}

	SubShader
	{
		LOD 200

		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}
		
		Pass
		{
			Cull Off
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			Offset -1, -1
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _DetailTex;
			float4 _MainTex_ST;
			float4 _Scale;

			struct v2f
			{
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				float4 screenPos : TEXCOORD1;
				half4 color : COLOR;
			};
	
			v2f o;

			v2f vert (appdata_full v)
			{
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = v.texcoord;
				o.color = v.color;
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}

			half4 frag (v2f IN) : SV_Target
			{
				half4 c = tex2D(_MainTex, IN.texcoord) * IN.color;

				float2 screen = (IN.screenPos.xy / IN.screenPos.w) * _ScreenParams.xy * _Scale.xy * 0.02;
				half4 tex = lerp(
					tex2D(_DetailTex, half2(screen.x, screen.y * 10.0 + _Time.w * 0.25 * _Scale.z)),
					tex2D(_DetailTex, half2(screen.x, screen.y - _Time.w * _Scale.w)), 0.1);

				c.a = saturate(lerp(c.a, c.a * tex.r, 0.75));
				return c;
			}
			ENDCG
		}
	}
}
