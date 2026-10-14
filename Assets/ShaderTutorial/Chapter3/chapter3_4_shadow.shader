Shader "Chapter3/chapter3_3_shadow"
{
    Properties
    {
        // 定义主颜色属性，可在材质面板中调整
        _MainColor ("Main Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        // -------- 基础Pass：处理主要光源的投影 --------
        Pass
        {
            // 标签定义，用于指定此Pass的光照模式为"ForwardBase"
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM
            // 顶点着色器和片段着色器入口
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase // 多重编译，支持不同光照模型
            #include "UnityCG.cginc"      // 包含Unity常用工具函数和宏
            #include "Lighting.cginc"    // 包含Unity光照计算函数
            #include "AutoLight.cginc"   // 包含Unity自动化光照相关代码

            // 定义顶点到片段的数据结构
            struct v2f
            {
                float4 pos : SV_POSITION;   // 裁剪空间的顶点位置
                float3 normal : TEXCOORD0; // 法线，用于光照计算
                float4 vertex : TEXCOORD1; // 模型空间的顶点位置
                SHADOW_COORDS(2)           // 使用Unity预定义宏存储阴影坐标
            };

            fixed4 _MainColor; // 主颜色变量

            // 顶点着色器
            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // 转换顶点到裁剪空间
                o.normal = v.normal;                   // 传递法线信息
                o.vertex = v.vertex;                   // 传递顶点位置
                TRANSFER_SHADOW(o)                     // 计算阴影坐标并存储
                return o;
            }

            // 片段着色器
            fixed4 frag (v2f i) : SV_Target
            {
                // 计算法线方向
                float3 n = UnityObjectToWorldNormal(i.normal);
                n = normalize(n);

                // 计算世界空间中的光源方向
                float3 l = WorldSpaceLightDir(i.vertex);
                l = normalize(l);

                // 将顶点从模型空间转换到世界空间
                float4 worldPos = mul(unity_ObjectToWorld, i.vertex);

                // Lambert光照模型：计算法线与光线夹角的点积
                fixed ndotl = saturate(dot(n, l));
                fixed4 color = _LightColor0 * _MainColor * ndotl;

                // 叠加4个点光源的光照
                color.rgb += Shade4PointLights(
                    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0, // 点光源位置
                    unity_LightColor[0].rgb, unity_LightColor[1].rgb, 
                    unity_LightColor[2].rgb, unity_LightColor[3].rgb,       // 点光源颜色
                    unity_4LightAtten0, worldPos.rgb, n                     // 衰减和位置
                ) * _MainColor;

                // 叠加环境光照
                color += unity_AmbientSky;

                // 使用Unity宏计算阴影衰减系数
                UNITY_LIGHT_ATTENUATION(shadowmask, i, worldPos.rgb)

                // 将阴影系数与颜色相乘，应用阴影效果
                color.rgb *= shadowmask;

                return color; // 返回最终颜色
            }
            ENDCG
        }

        // -------- 额外的Pass：处理其他逐像素灯光的投影 --------
        Pass
        {
            // 标签定义，此Pass用于附加光源，模式为"ForwardAdd"
            Tags{"LightMode" = "ForwardAdd"}

            // 混合模式：相加混合
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows // 支持多重编译，包含完整阴影
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            // 定义顶点到片段的数据结构，与基础Pass一致
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD0;
                float4 vertex : TEXCOORD1;
                SHADOW_COORDS(2)
            };

            fixed4 _MainColor;

            // 顶点着色器
            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                o.vertex = v.vertex;
                TRANSFER_SHADOW(o)
                return o;
            }

            // 片段着色器
            fixed4 frag (v2f i) : SV_Target
            {
                // 计算法线和光照方向
                float3 n = UnityObjectToWorldNormal(i.normal);
                n = normalize(n);
                float3 l = WorldSpaceLightDir(i.vertex);
                l = normalize(l);

                // 转换顶点到世界空间
                float4 worldPos = mul(unity_ObjectToWorld, i.vertex);

                // Lambert光照计算
                fixed ndotl = saturate(dot(n, l));
                fixed4 color = _LightColor0 * _MainColor * ndotl;

                // 叠加点光源的光照
                color.rgb += Shade4PointLights(
                    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                    unity_LightColor[0].rgb, unity_LightColor[1].rgb,
                    unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                    unity_4LightAtten0, worldPos.rgb, n
                ) * _MainColor;

                // 使用阴影宏计算阴影系数
                UNITY_LIGHT_ATTENUATION(shadowmask, i, worldPos.rgb)

                // 应用阴影到颜色
                color.rgb *= shadowmask;

                return color; // 返回最终颜色
            }
            ENDCG
        }
    }
    // 回退着色器，定义为Diffuse
    FallBack "Diffuse"
}
