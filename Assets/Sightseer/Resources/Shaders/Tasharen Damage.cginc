#ifndef TASHAREN_DAMAGE_INCLUDE
#define TASHAREN_DAMAGE_INCLUDE

inline float3 GetTriplanarBias (float3 normal)
{
	float3 triplanar = pow(saturate(abs(normalize(normal))), 16.0);
	return triplanar / dot(triplanar, 1.0);
}

inline half4 SampleTriplanar (sampler2D tex, half3 uvw, half3 triplanar)
{
	return  tex2D(tex, uvw.yx) * triplanar.z +
			tex2D(tex, uvw.xz) * triplanar.y +
			tex2D(tex, uvw.yz) * triplanar.x;
}

#define V2F_TRIPLANAR(a, b) \
	float3 objPos : TEXCOORD##a; \
	float3 objNormal : TEXCOORD##b;

#define TRANSFER_TRIPLANAR(v, o) \
	o.objNormal = v.normal; \
	o.objPos = v.vertex.xyz / v.vertex.w;

#define TRIPLANAR_OVERLAY(IN, damage, condition, tintAmount, blend, ao) \
{ \
	half f = saturate(((0.55 + condition * 0.55) - (damage.a * 0.98 - 0.01)) * 10.0); \
	f = lerp(1.0, f, tintAmount) * blend; \
	o.Albedo = lerp(damage.rgb * (0.15 + 0.85 * ao), o.Albedo, f); \
	o.Specular *= f; \
	o.Emission *= f; \
}

#define SAMPLE_TRIPLANAR_OVERLAY(IN, tex, scale, condition, tintAmount, blend, ao) \
{ \
	float3 triplanar = GetTriplanarBias(IN.objNormal); \
	half4 damage = SampleTriplanar(tex, IN.objPos * scale, triplanar); \
	TRIPLANAR_OVERLAY(IN, damage, condition, tintAmount, blend, ao) \
}

#define TRIPLANAR_SAMPLE(IN, tex, scale, triplanar, damage) \
	float3 triplanar = GetTriplanarBias(IN.objNormal); \
	half4 damage = SampleTriplanar(tex, IN.objPos * scale, triplanar);

#define TRIPLANAR_SAMPLE_AND_CLIP(IN, tex, threshold, damageScale, triplanar, damage) \
	float3 triplanar = GetTriplanarBias(IN.objNormal); \
	half4 damage = SampleTriplanar(tex, IN.objPos * damageScale, triplanar); \
	clip(threshold - damage.a * 0.98 - 0.01);

#define TRIPLANAR_SAMPLE_AND_CLIP2(IN, tex, threshold, damageScale, clipScale, triplanar, damage) \
	float3 triplanar = GetTriplanarBias(IN.objNormal); \
	clip(threshold - SampleTriplanar(tex, IN.objPos * clipScale, triplanar).a * 0.98 - 0.01); \
	half4 damage = SampleTriplanar(tex, IN.objPos * damageScale, triplanar);

#define TRIPLANAR_SAMPLE_CLIP(IN, tex, threshold, clipScale) \
	clip(threshold - SampleTriplanar(tex, IN.objPos * clipScale, GetTriplanarBias(IN.objNormal)).a * 0.98 - 0.01);

#endif
