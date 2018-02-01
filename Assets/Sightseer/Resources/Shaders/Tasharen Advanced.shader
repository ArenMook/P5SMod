Shader "Tasharen/Advanced"
{
	Properties
	{
		_MainTex ("Texture (RGB), Specular (A)", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_GlowMap ("Glow Map (RGB), Tint Amount (A)", 2D) = "black" {}
		_ColorMask ("Color Mask (RGBA)", 2D) = "black" {}
		_Color0 ("Color R", Color) = (1,1,1,1)
		_Color1 ("Color G", Color) = (1,1,1,1)
		_Color2 ("Color B", Color) = (1,1,1,1)
		_Color3 ("Color A", Color) = (1,1,1,1)
		[Space] _Metallic ("Metallic (for each color, 0-1 range)", Vector) = (0, 0, 0, 0)
		[Space] _Smoothness ("Smoothness (for each color, 0-1 range)", Vector) = (0.81, 0.81, 0.81, 0.81)
		[Space][HDR] _Glow ("Glow Color", Color) = (1,1,1,1)
		[HideInInspector] _GlowBrightness ("Glow Brightness", Range(0,1)) = 1.0
	}

	SubShader
	{
		LOD 200
		Tags { "RenderType" = "Tasharen" }
		Cull Back

		CGPROGRAM
		#pragma surface surf Tasharen vertex:vert fullforwardshadows
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma target 3.0

		//#define UNITY_GI_MODEL
		//#define GI_SOURCE TOD_Reflection

		#include "Tasharen Lighting.cginc"

		struct Input
		{
			float2 uv_MainTex;
			V2F_DITHER_COORDS
		};

		sampler2D _MainTex, _BumpMap, _ColorMask, _GlowMap;
		half4 _Color0, _Color1, _Color2, _Color3, _Glow;
		half4 _Metallic, _Smoothness;
		half _GlowBrightness;

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			TRANSFER_DITHER(o, v.vertex);
		}

		void surf (Input IN, inout Output o)
		{
			half4 tex = tex2D(_MainTex, IN.uv_MainTex);
			half4 mask = tex2D(_ColorMask, IN.uv_MainTex);
			half4 glow = tex2D(_GlowMap, IN.uv_MainTex);

			// To make the texture easier to work with, the 4th color contribution is (1 - (r+g+b))
			half tintAmount = mask.a;
			half sum = dot(mask.rgb, (1.0).xxx);
			mask.a = saturate(1.0 - sum);

			// Final mask color is simply a combination of all 4 using the texture mask
			half4 tint = _Color0 * mask.r + _Color1 * mask.g + _Color2 * mask.b + _Color3 * mask.a;

			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));

			// Certain parts of the texture are masked out, so keep their color intact
			o.Albedo = lerp(tex.rgb, tint.rgb * tex.rgb, tintAmount);

			// Adding the mask's RGB to specular gives the material the look of metallic paint
			o.Specular.rgb = tint.rgb * (dot(_Metallic, mask) * tintAmount);

			// Specular component resides in the main texture's alpha channel. The dot product with the texture's RGB makes the details come out and
			// The value is actually 3 times higher than normal because the texture's RGB is so dark...
			o.Specular.a = dot(tex.rgb, (0.333).xxx) * tex.a;

			// Color tint's alpha channel currently adjusts the entire specular component
			o.Specular *= tint.a;

			// Glow mask should be adjusted by the glow color
			o.Emission = glow.rgb * _Glow.rgb * (_Glow.a * _GlowBrightness);

			// Combine all 4 smoothness values using the previously calculated mask
			o.Smoothness = dot(_Smoothness, mask);

			APPLY_DITHER(IN);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
