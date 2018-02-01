// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Tasharen/Scanline HUD B"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_DetailTex ("Detail Texture", 2D) = "white" {}
		_Contrast ("Contrast", Range(0, 1)) = 0.5
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
			half _Contrast;

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
				half4 tex = tex2D(_MainTex, IN.texcoord);
				tex.a *= IN.color.a;

				half4 c = half4(0.0, 0.0, 0.0, tex.a * IN.color.a * 0.9);

				float screenY = (IN.screenPos.y / IN.screenPos.w) * _ScreenParams.y;
				half4 detail = lerp(
					tex2D(_DetailTex, half2(0.5, screenY * 0.2 + _Time.w * 0.25)),
					tex2D(_DetailTex, half2(0.5, screenY * 0.02 - _Time.w)), 0.1);
				
				detail.rgb = (1.0 - _Contrast).xxx + detail.rgb * _Contrast;

				c.rgb += lerp(c.rgb, detail.rgb * IN.color.rgb, tex.r);
				return c;
			}
			ENDCG
		}
	}
}
