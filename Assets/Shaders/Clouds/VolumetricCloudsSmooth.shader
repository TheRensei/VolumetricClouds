Shader "Custom/Volumetric Clouds Smooth" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		[NoScaleOffset] _NoiseTex("Noise Texture", 2D) = "white" {}
		_MaskTex("Mask Texture", 2D) = "white" {}
		_TexScale("Texture Scale", Float) = 1
		_ScrollSpeed("Scroll Speed", Float) = 1
		_CutOff("CutOff", Range(0,1)) = 0.1
		_Cutout("Cutout", Range(0,1)) = 0.1
		_CloudSoftness("Cloud Softness", Range(0,3)) = 0.01
		_SSSPower("SSS Power", Range(0,50)) = 4.5
		_SSSStrength("SSS Strength", Float) = 0.22
		_TaperPower("Taper Power", Float) = 1
		_CurvatureStrength("Curvature Strength", Float) = 1
		_FlatThreshold("Flat Threshold", Float) = 1
	}

		SubShader{
			Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "LightMode" = "ForwardBase"  }

			// Render both front and back facing polygons.
			Cull Off
				Blend SrcAlpha OneMinusSrcAlpha

		Pass {
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_instancing

				#include "UnityCG.cginc"
			 #include "UnityLightingCommon.cginc"
			#include "AutoLight.cginc"

				struct appdata_t {
			UNITY_VERTEX_INPUT_INSTANCE_ID
					float4 vertex : POSITION;
					float3 Normal : NORMAL;
					float4 color : COLOR;
					float2 uv : TEXCOORD2;
				};

				struct v2f {
					float4 vertex : POSITION;
					half4 color : COLOR;
					float3 worldPos : TEXCOORD0;
					float3 worldNormal :  TEXCOORD1;
					float2 uv : TEXCOORD2;
				};

				fixed4 _Color;
				sampler2D _NoiseTex;
				sampler2D _MaskTex;
				float4 _MaskTex_ST;
				half _ScrollSpeed;
				half _TexScale;
				half _CutOff;
				half _Cutout;
				half _CloudSoftness;
				half _TaperPower;
				half _SSSPower;
				half _SSSStrength;

				float _midYValue;
				half _cloudHeight;

				half3 _Origin;
				half _CurvatureStrength;
				half _FlatThreshold;

				half4 Bend(half4 v)
				{
					half4 wpos = mul(unity_ObjectToWorld, v);
					half2 xzDist = (wpos.xz - _Origin.xz);
					half dist = length(xzDist);

					dist = max(0, dist - _FlatThreshold); // Add a threshold so you can have a flat surface near origin
					wpos.y -= dist * dist * _CurvatureStrength; // multiply dist with itself so it has a more pronounced curvature
					wpos = mul(unity_WorldToObject, wpos);

					return wpos;
				}

				//runs for every vertex
				v2f vert(appdata_t v)
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);

					o.worldPos = mul(unity_ObjectToWorld, v.vertex);
					//Bend The vertex around the point
					v.vertex = Bend(v.vertex);

					o.vertex = UnityObjectToClipPos(v.vertex);
					o.worldNormal = UnityObjectToWorldNormal(v.Normal);
					o.uv = TRANSFORM_TEX(v.uv, _MaskTex);

					//Define variable that will keep color of the light
					half4 c;

					half nl = max(0, dot(o.worldNormal, _WorldSpaceLightPos0.xyz));
					// factor in the light color
					c = nl * _LightColor0;
					//Add ambient color
					c.rgb += ShadeSH9(half4(o.worldNormal, 1));
					o.color = c;

					TRANSFER_VERTEX_TO_FRAGMENT(o);
					return o;
				}


				void Unity_Remap_float4(half4 In, half2 InMinMax, half2 OutMinMax, out half4 Out)
				{
					Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
				}

				//runs for every pixel
				half4 frag(v2f i) : SV_Target
				{

					//Calculate the view Direction
					half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
					//Calculate the light direction
					half3 lightDir = _WorldSpaceLightPos0;
					//Calculate the subscattering color
					half4 subScatter = pow(saturate(dot(viewDir, -lightDir)), _SSSPower) * _LightColor0 * _SSSStrength;

					half worldY = i.worldPos.y;
					half satHeight = saturate(abs(_midYValue - worldY) / (_cloudHeight *0.25));
					half verticalGradient = 1 - pow(satHeight, _TaperPower);

					//Noise texture uv in worldspace
					half2 uv = i.worldPos.xz;
					if (abs(i.worldNormal.x) > 0.5)
					{
						uv = i.worldPos.yz;
					}
					else if (abs(i.worldNormal.z) > 0.5)
					{
						uv = i.worldPos.xy;
					}

					//Scroll noise tex 1 with time
					uv += _ScrollSpeed * _Time.y;
					fixed4 noiseBig = tex2D(_NoiseTex, uv * _TexScale);

					//Scroll noise tex 2 with time
					uv -= _ScrollSpeed * _Time.y;
					fixed4 smallNoise = tex2D(_NoiseTex, uv * (_TexScale *0.5));

					//Create noise by combining the two noise textures and a spherical mask
					half4 noise = (noiseBig.r * smallNoise.r * tex2D(_MaskTex, i.uv));

					//Subscatter color masked by noise
					//Highlight the edges mostly and leaves the inside of the cloud (depending on thickness) darker
					subScatter = half4((abs(1 - (noise.rgb * 2)) - 0.1) * subScatter.rgb,0);
					
					//Apply noise based on the height of the cloud
					noise *= verticalGradient;

					//Calculate ambient color of the clouds based on the stack height
					//lerp ambient ground and sky color based on this value
					half temp = saturate((_midYValue - worldY) / (_cloudHeight * 0.25));
					half4 ambientCol = (unity_AmbientGround * satHeight) + (unity_AmbientSky * (1 - temp));

					//remap min cutoff cloud
					//Basically makes the clouds fluffy
					Unity_Remap_float4(noise, half2(0,1), half2(_CutOff,1),noise);
					noise = pow(saturate(noise), _CloudSoftness);

					//Cut out not wanted pixels
					clip(noise - _Cutout);
					
					//SSS color * ambient color of the sky and the ground * color
					half4 col = i.color * ambientCol * _Color + subScatter;

					//Set alpha to the alpha value from the noise 
					col.a = noise.a;
					return col;
				}
			ENDCG
		}
		}
}