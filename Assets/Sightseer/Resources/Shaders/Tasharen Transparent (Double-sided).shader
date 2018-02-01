Shader "Tasharen/Transparent (Double-sided)"
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
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
		}

		LOD 200
		Cull Off
		
		CGPROGRAM
		#pragma surface surf Tasharen vertex:vert alpha:fade
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma target 3.0
		#include "Tasharen Lighting.cginc"

		struct Input
		{
			float2 uv_MainTex : TEXCOORD0;
			half4 color : COLOR;
			half side : VFACE;
		};

		sampler2D _MainTex;
		half4 _Color;

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.color = v.color;
		}

		void surf (Input IN, inout Output o)
		{
			half4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb * IN.color.rgb;

			o.Normal = float3(0.0, 0.0, 1.0);
			o.Normal *= IN.side; // Flip the normal if it's facing away from the camera (double-sided shader)

#ifdef LOD_FADE_CROSSFADE
			o.Alpha = IN.color.a * _Color.a * tex.a * unity_LODFade.x;
#else
			o.Alpha = IN.color.a * _Color.a * tex.a;
#endif
		}
		ENDCG
	} 
}
