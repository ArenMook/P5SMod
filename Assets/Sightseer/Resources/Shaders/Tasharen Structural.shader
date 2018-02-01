Shader "Tasharen/Structural"
{
	Properties
	{
		[NoScaleOffset] _MainTex ("AO from Surforge (RGB), Glass (black A)", 2D) = "white" {}
		[NoScaleOffset] _ColorMask ("Color Mask (RGB), Tint Amount (A)", 2D) = "black" {}
		[NoScaleOffset][Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
		[NoScaleOffset] _OcclusionMap ("Ambient Occlusion (using UV2)", 2D) = "white" {}
		[NoScaleOffset] _BlendTex0 ("Detail 0 (RGB), Smoothness (A)", 2D) = "white" {}
		[NoScaleOffset] _BlendTex1 ("Detail 1 (RGB), Smoothness (A)", 2D) = "white" {}
		[NoScaleOffset] _DamageTex ("Damage Texture (RGBA)", 2D) = "black" {}
		[NoScaleOffset] _NoiseTex ("Noise Texture (RGBA)", 2D) = "white" {}

		_Color0 ("Color Mask's Red Color", Color) = (1, 1, 1, 1)
		_Color1 ("Color Mask's Green Color", Color) = (0.1, 0.1, 0.1, 1)
		_Color2 ("Color Mask's Blue Color", Color) = (0.353, 0, 0, 1)
		_Color3 ("Color Mask's Black Color", Color) = (0.2, 0.2, 0.2, 0.2)

		_Spec0 ("Color Mask's Red Specular", Color) = (0,0,0,0)
		_Spec1 ("Color Mask's Green Specular", Color) = (0,0,0,0)
		_Spec2 ("Color Mask's Blue Specular", Color) = (0,0,0,0)
		_Spec3 ("Color Mask's Black Specular", Color) = (0,0,0,0)

		[Space] _TexBlend ("Detail Blend (for each color, 0-1 range)", Vector) = (0, 0, 0, 0)
		_BlendScale ("Detail UV Scale (for each color)", Vector) = (2, 2, 2, 2)
		_BlendAlpha ("Detail Blend Alpha (for each color, 0-1)", Vector) = (0.5, 0.5, 0.5, 0.5)
		_Metallic ("Metallic (for each color, 0-1 range)", Vector) = (0.2, 0.9, 0.9, 0)
		_Smoothness ("Smoothness (for each color, 0-1 range)", Vector) = (0.8, 0.9, 0.9, 0.2)
		_OcclusionStrength ("Occlusion Strength", Range(0, 1)) = 1.0
		_TriplanarScale ("Triplanar Scale", Vector) = (0.5, 0.25, 1, 1)

		_Condition ("Condition", Range(0, 1)) = 1.0
	}

	SubShader
	{
		LOD 200
		Tags { "RenderType" = "Tasharen" }
		Cull Back

		CGPROGRAM
		#pragma surface surf Tasharen vertex:vert fullforwardshadows
		#pragma multi_compile __ TASHAREN_DITHER LOD_FADE_CROSSFADE
		#pragma multi_compile_instancing
		#pragma target 4.0

		//#define UNITY_GI_MODEL
		//#define GI_SOURCE TOD_Reflection

		#include "Tasharen Lighting.cginc"
		#include "Tasharen Damage.cginc"

		struct Input
		{
			half4 tc : TEXCOORD0;
			half4 color : COLOR;
			V2F_COMMON_IDX(1)
			V2F_TRIPLANAR(2, 3)
			float4 wp;
		};

		#include "Tasharen Advanced AO.cginc"

		sampler2D _DamageTex;
		half4 _TriplanarScale;
		half _Condition;

		sampler2D _NoiseTex;
		sampler2D _GrassTexColor;
		float4 _GrassTexParams;
		float3 _GrassOrigin;
		half4 _GrassFadeDistance;
		float4 _TerrainSize;
		float3 _FloatingOriginOffset;

		void vert (inout appdata_full v, out Input o)
		{
			CommonVertexShader(v, o);
			TRANSFER_TRIPLANAR(v, o);

			o.wp.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
			o.wp.w = min(length(o.wp.xyz - _WorldSpaceCameraPos.xyz), length(o.wp.xyz - _GrassOrigin));
		}

		void CustomSurfaceShader (Input IN, inout Output o, out half4 mainTex, out half4 mask, out half4 blend, out half4 ao, out half tintAmount)
		{
			mainTex = tex2D(_MainTex, IN.tc.xy);

			mask = tex2D(_ColorMask, IN.tc.xy).MASK;
			ao = tex2D(_OcclusionMap, IN.tc.zw);
			ao = lerp(half4(1.0, 1.0, 1.0, 1.0), ao, _OcclusionStrength);

			// To make the texture easier to work with, the 4th color contribution is (1 - (r+g+b))
			tintAmount = mask.a;
			half sum = dot(mask.rgb, (1.0).xxx);
			mask.a = saturate(1.0 - sum);

			// Final mask color is simply a combination of all 4 using the texture mask
			half4 tint = _Color0 * mask.r + _Color1 * mask.g + _Color2 * mask.b + _Color3 * mask.a;
			half2 uv = IN.tc.xy * dot(_BlendScale, mask);
			half4 blend0 = tex2D(_BlendTex0, uv);
			half4 blend1 = tex2D(_BlendTex1, uv);
			blend = lerp(blend0, blend1, dot(_TexBlend, mask));
			blend.rgb = lerp(mainTex.rgb, mainTex.rgb * blend.rgb, tintAmount * dot(_BlendAlpha, mask));

			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.tc.xy));

			// Certain parts of the texture are masked out, so keep their color intact
			o.Albedo = lerp(blend.rgb, blend.rgb * tint.rgb, tintAmount) * IN.color.rgb;

			// Adding the mask's RGB to specular gives the material the look of metallic paint
			half4 spec = _Spec0 * mask.r + _Spec1 * mask.g + _Spec2 * mask.b + _Spec3 * mask.a;
			tint.rgb = lerp(tint.rgb, spec.rgb, spec.a);
			o.Specular.rgb = tint.rgb * (dot(_Metallic, mask) * tintAmount);

			// Treat the diffuse channel as the source of specular intensity. Ideally we'd have the specular in the alpha channel instead.
			o.Specular.a = dot(blend.rgb, (0.333).xxx);

			// Rain makes everything shinier
			o.Specular.rgb = lerp(o.Specular.rgb, (1.0).xxx, _Weather.y * 0.15);
			o.Specular.a = lerp(o.Specular.a, 1.0, _Weather.y * 0.25);

			// Detail textures' alpha channel adjust the specularity and smoothness
			o.Specular *= tint.a * (0.8 + 0.2 * blend.a);
			o.Smoothness = dot(_Smoothness, mask) * (0.95 + 0.05 * blend.a);

			// Glass is specified in the diffuse texture's alpha channel as black
			o.Albedo *= mainTex.a;
			o.Specular = lerp(half4(1.0, 1.0, 1.0, 0.1), o.Specular, mainTex.a);
			o.Smoothness = lerp(0.99, o.Smoothness, mainTex.a);

			// Apply the terrain color tint to make transition lines less noticeable
			float2 distort = tex2D(_NoiseTex, (IN.wp.xz + _FloatingOriginOffset.xz) * 0.025).xy - 0.5;
			float2 grassColorUV = (IN.wp.xz + distort - _GrassTexParams.xy) / _GrassTexParams.z;
			grassColorUV = grassColorUV * 0.5 + 0.5;
			half4 grassColor = tex2D(_GrassTexColor, grassColorUV);
			float height = grassColor.a / _TerrainSize.w + _TerrainSize.x;
			float diff = 1.0 - saturate(IN.wp.y - height);
			diff *= diff * diff;

			half fadeAlpha = 1.0 - saturate((IN.wp.w - _GrassFadeDistance.x) * _GrassFadeDistance.w);
			diff *= fadeAlpha;

			o.Albedo = lerp(o.Albedo, grassColor.rgb * blend0.r, diff);
			diff = 1.0 - diff;
			o.Specular *= diff;
			o.Smoothness *= diff;
			
			// Rain makes everything shinier
			half wetness = _Weather.y * 0.95;
			o.Smoothness = lerp(o.Smoothness, 1.0, wetness);

			// Apply the AO. Main texture is expected to contain AO from Surforge.
			o.Specular *= lerp(1.0, mainTex.r * ao.r, tintAmount);
			o.Albedo *= ao.rgb;

			APPLY_DITHER(IN)
		}

		void surf (Input IN, inout Output o)
		{
			half4 mainTex, mask, blend, ao;
			half tintAmount;
			CustomSurfaceShader(IN, o, mainTex, mask, blend, ao, tintAmount);
			SAMPLE_TRIPLANAR_OVERLAY(IN, _DamageTex, _TriplanarScale.x, _Condition, tintAmount * mainTex.a, IN.color.a, ao.r);
		}
		ENDCG
	}
	FallBack "Tasharen/Diffuse"
}
