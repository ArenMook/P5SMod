#ifndef TASHAREN_ADVANCED_AO
#define TASHAREN_ADVANCED_AO

#ifndef CLIP
  #define CLIP
  #define CLIP_TEST
#else
  half CLIP;
  #define CLIP_TEST clip(mainTex.a - CLIP);
#endif

#ifndef MASK
#define MASK rgba
#endif

sampler2D _MainTex, _BumpMap, _OcclusionMap, _ColorMask, _BlendTex0, _BlendTex1;
half4 _Color0, _Color1, _Color2, _Color3;
half4 _Spec0, _Spec1, _Spec2, _Spec3;
half4 _TexBlend, _BlendScale, _BlendAlpha, _Metallic, _Smoothness;
half _OcclusionStrength;
fixed4 _Weather;

inline void CommonVertexShader (inout appdata_full v, out Input o)
{
	INITIALIZE_VERTEX(Input, v, o);
	o.tc.xy = v.texcoord.xy;
	o.tc.zw = v.texcoord1.xy;
	o.color = v.color;
}

inline void CommonSurfaceShader (Input IN, inout Output o, out half4 mainTex, out half4 mask, out half4 blend, out half4 ao, out half tintAmount)
{
	mainTex = tex2D(_MainTex, IN.tc.xy);

	CLIP_TEST

	mask = tex2D(_ColorMask, IN.tc.xy).MASK;
	ao = tex2D(_OcclusionMap, IN.tc.zw);
	ao = lerp(half4(1.0, 1.0, 1.0, 1.0), ao, _OcclusionStrength);

	// To make the texture easier to work with, the 4th color contribution is (1 - (r+g+b))
	tintAmount = mask.a;
	mask.a = saturate(1.0 - dot(mask.rgb, (1.0).xxx));

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

	// Rain makes everything shinier
	half wetness = _Weather.y * 0.95;
	o.Smoothness = lerp(o.Smoothness, 1.0, wetness);

	// Apply the AO. Main texture is expected to contain AO from Surforge.
	o.Specular *= lerp(1.0, mainTex.r * ao.r, tintAmount);
	o.Albedo *= ao.rgb;

	APPLY_DITHER(IN)
}

#endif
