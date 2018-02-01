// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Tasharen/Scanline HUD (Sharp)"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_DetailTex ("Detail Texture", 2D) = "white" {}
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

			inline half ExagerrateAround05Mini (half textureBlend)
			{
				textureBlend = (textureBlend * 2.0 - 1.0);
				half blendSign = sign(textureBlend);
				textureBlend = abs(textureBlend);
				textureBlend = 1.0 - textureBlend;
				textureBlend *= textureBlend;
				textureBlend *= textureBlend;
				textureBlend = 1.0 - textureBlend;
				textureBlend *= blendSign;
				return textureBlend * 0.5 + 0.5;
			}
				
			half4 frag (v2f IN) : SV_Target
			{
				half4 c = tex2D(_MainTex, IN.texcoord) * IN.color;

				c.a = ExagerrateAround05Mini(c.a);

				float screenY = (IN.screenPos.y / IN.screenPos.w) * _ScreenParams.y;
				half4 tex = lerp(
					tex2D(_DetailTex, half2(0.5, screenY * 0.2 + _Time.w * 0.25)),
					tex2D(_DetailTex, half2(0.5, screenY * 0.02 - _Time.w)), 0.1);

				c.a = lerp(c.a, c.a * tex.r, 0.5);
				return c;
			}
			ENDCG
		}
	}
}
