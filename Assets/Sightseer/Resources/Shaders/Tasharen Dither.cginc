#ifndef TASHAREN_DITHER_CGINC
#define TASHAREN_DITHER_CGINC

#if TASHAREN_DITHER
	#ifndef DITHER
		#define DITHER _Dither
		float2 DITHER;
		
		#ifdef DITHER_MULT
		#define CLIP_DITHER \
			half dither = DITHER.x * DITHER_MULT - (projUV.y + projUV.x) * 0.25; \
			clip(lerp(dither, -dither, DITHER.y))
		#else
		#define CLIP_DITHER \
			half dither = DITHER.x - (projUV.y + projUV.x) * 0.25; \
			clip(lerp(dither, -dither, DITHER.y))
		#endif
	#else
		#ifndef CLIP_DITHER
			#ifdef DITHER_MULT
			#define CLIP_DITHER clip(DITHER * DITHER_MULT - (projUV.y + projUV.x) * 0.25)
			#else
			#define CLIP_DITHER clip(DITHER - (projUV.y + projUV.x) * 0.25)
			#endif
		#endif
	#endif

	inline half3 ComputeDitherScreenPos (float4 clipPos)
	{
		half3 screenPos = ComputeScreenPos(clipPos).xyw;
		screenPos.xy *= _ScreenParams.xy * 0.25;
		return screenPos;
	}

	inline void DitherCrossFade (half3 ditherScreenPos)
	{
		half2 projUV = ditherScreenPos.xy / ditherScreenPos.z;
		projUV = frac(projUV + 0.001) + frac(projUV * 2.0 + 0.001);
		CLIP_DITHER;
	}

	#define V2F_DITHER_COORDS half3 ditherScreenPos;
	#define V2F_DITHER_COORDS_IDX(idx) half3 ditherScreenPos : TEXCOORD##idx;
	#define TRANSFER_DITHER(o, pos) o.ditherScreenPos = ComputeDitherScreenPos(UnityObjectToClipPos(pos));
	#define APPLY_DITHER(IN) DitherCrossFade(IN.ditherScreenPos);
#else
	#define V2F_DITHER_COORDS UNITY_DITHER_CROSSFADE_COORDS
	#define V2F_DITHER_COORDS_IDX(idx) UNITY_DITHER_CROSSFADE_COORDS_IDX(idx)
	#define TRANSFER_DITHER(o, pos) UNITY_TRANSFER_DITHER_CROSSFADE(o, pos)
	#define APPLY_DITHER(IN) UNITY_APPLY_DITHER_CROSSFADE(IN)
#endif

#define V2F_COMMON \
	UNITY_VERTEX_OUTPUT_STEREO \
	V2F_DITHER_COORDS

#define V2F_COMMON_IDX(num) \
	UNITY_VERTEX_OUTPUT_STEREO \
	V2F_DITHER_COORDS_IDX(num)

#define INITIALIZE_VERTEX(Input, v, o) \
	UNITY_INITIALIZE_OUTPUT(Input, o); \
	UNITY_SETUP_INSTANCE_ID(v); \
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); \
	TRANSFER_DITHER(o, v.vertex);

#endif