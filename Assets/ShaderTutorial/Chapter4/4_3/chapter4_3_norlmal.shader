Shader "Chapter4/chapter4_3_normal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} // 主纹理，默认是白色
        _MainColor("Main Color", Color) = (1, 1, 1, 1) // 主颜色，默认是白色
        
        [Header(Normal Map)]
        _NormalMap ("Normal Map", 2D) = "bump" {} // 法线贴图，默认是bump（凹凸贴图）
        _NormalMapIntensity ("Normal Map Intensity", Float) = 1 // 法线贴图强度，默认值为1
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" } // 渲染类型是Opaque（不透明）

        Pass
        {
            Tags{"LightMode" = "ForwardBase"} // 渲染模式为ForwardBase
            CGPROGRAM
            #pragma multi_compile_fwdbase // 编译时包含前向渲染的基础代码
            
            #pragma vertex vert // 使用顶点着色器函数vert
            #pragma fragment frag // 使用片段着色器函数frag

            #include "UnityCG.cginc" // 引入Unity的CG库
            #include "Lighting.cginc" // 引入Unity的光照计算库
            #include "AutoLight.cginc" // 引入自动光照库

            struct appdata
            {
                float4 vertex : POSITION; // 顶点位置
                float2 uv : TEXCOORD0; // 顶点UV坐标
                float3 normal : NORMAL; // 顶点法线
                float3 color : COLOR; // 顶点颜色
                float4 tangent : TANGENT; // 顶点切线
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0; // UV坐标
                float4 pos : SV_POSITION; // 顶点的裁剪空间位置
                float4 worldPos : TEXCOORD1; // 顶点的世界空间位置
                float3 normal : TEXCOORD2; // 顶点的法线
                float4 objectPos : TEXCOORD3; // 顶点的对象空间位置
                float4 tangent : TEXCOORD4; // 顶点的切线
            };

            // 定义sampler2D变量，用于存储纹理
            sampler2D _MainTex;
            sampler2D _NormalMap;
            float4 _MainTex_ST;
            half4 _MainColor;

            // 法线贴图强度
            half _NormalMapIntensity;

            // 顶点着色器：计算顶点的裁剪空间位置，传递必要的参数到片段着色器
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // 计算顶点的裁剪空间位置
                o.uv = v.uv; // 将UV坐标传递给片段着色器
                o.worldPos = mul(unity_ObjectToWorld, v.vertex); // 计算顶点的世界空间位置
                o.normal = UnityObjectToWorldNormal(v.normal); // 将对象空间法线转化为世界空间法线
                o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w); // 将对象空间切线转化为世界空间切线
                o.objectPos = v.vertex; // 将对象空间位置传递给片段着色器
                return o;
            }

            // 获取法线贴图，并根据强度和Y轴反转选项计算新的法线
            half3 GetNormalMap(float3 normal, float4 tangent, float2 uv, float intensity)
            {
                // 计算副切线（副切线是切线和法线的叉积）
                float3 bitangent = cross(normal, tangent) * tangent.w;
                
                // 从法线贴图中取出数据并解包
                float3 normalMap = UnpackScaleNormal(tex2D(_NormalMap, uv.xy), intensity);
                
                // 计算新的法线，按照切线空间变换
                float3 newNormal = normalize(
                    normalMap.x * tangent + // 沿切线方向的分量
                    normalMap.y * bitangent + // 沿副切线方向的分量（如果需要反转Y轴）
                    normalMap.z * normal // 沿法线方向的分量
                );
                return newNormal;
            }

            // 片段着色器：计算每个像素的最终颜色
            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = GetNormalMap(i.normal, i.tangent, i.uv, _NormalMapIntensity);
                // 计算光照方向
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 漫反射光照计算
                half4 albedo = tex2D(_MainTex, i.uv) * _MainColor; // 获取主纹理颜色
                half diffuse = saturate(dot(normal, lightDir)); // 计算漫反射分量
                half3 diffuseFinal = diffuse * albedo * _LightColor0.rgb; // 将漫反射分量与纹理颜色和光源颜色相乘

                return half4(diffuseFinal, 1); // 输出最终的颜色值
            }
            ENDCG
        }
    }
}
