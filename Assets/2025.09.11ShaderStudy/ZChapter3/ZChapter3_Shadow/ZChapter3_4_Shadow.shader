//有阴影效果的Shader

Shader "ZChapter3/ZChapter3_4_Shadow"
{
     Properties
    {
        // 定义主颜色属性，可在材质面板中调整
        _MainColor ("Main Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        // -------- 基础Pass：处理主要光源的投影 --------           //Z：第一个 Pass：处理 "主要光源"（比如阳光），[在前向渲染中使用；应用环境光、主方向光、顶点/SH 光源和光照贴图]
        Pass
        {
            // 标签定义，用于指定此Pass的光照模式为"ForwardBase"
            Tags{"LightMode" = "ForwardBase"}  //Z：标签(自己的理解) 
                                               //1、处理最亮的那个光源
                                               //2、叠加环境光（比如阴天的散射光）
                                               //3、计算主要光源的阴影
                                               //4、顺带处理最多 4 个不产生阴影的点光源（优化性能）[Z：这个地方测试下，其实效果就是其余几个点/射灯光源对非阴影部分有点影响]

            CGPROGRAM
            // 顶点着色器和片段着色器入口
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase // 多重编译，支持不同光照模型 [Z：作用：让 Shader 自动生成 “多个适配版本”，比如：版本 1：场景 “开启阴影” 时用；版本 2：场景 “关闭阴影” 时用；版本 3：场景 “使用光照贴图” 时用；]
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

        // -------- 额外的Pass：处理其他逐像素灯光的投影 --------//Z：第二个 Pass：处理 "额外光源"（比如灯泡、火把）
         Pass
        {
            // 标签定义，此Pass用于附加光源，模式为"ForwardAdd"  //Z：在前向渲染中使用；应用附加的每像素光源
            Tags{"LightMode" = "ForwardAdd"}//Z：

            // 混合模式：相加混合
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows // 支持多重编译，包含完整阴影[Z： 是让附加光源，的光照和高质量阴影能自动适配各种场景]
            #include "UnityCG.cginc" 
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            // 定义顶点到片段的数据结构，与基础Pass一致
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD0;
                float4 vertex : TEXCOORD1;
                SHADOW_COORDS(2)//Z：使用Unity预定义宏存储阴影坐标[存储计算阴影所需的坐标信息，用于后续计算阴影]**********************************
            };

            fixed4 _MainColor;

            // 顶点着色器
            v2f vert (appdata_base v)//Z：appdata_base，Unity 默认的顶点数据，包含顶点位置、法线等
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                o.vertex = v.vertex;
                TRANSFER_SHADOW(o)//Z：计算阴影坐标并存储；Unity 的预定义宏，根据顶点信息计算 “阴影坐标”，并存在纸条o里（对应之前的SHADOW_COORDS(2)）****************************
                return o;
            }

            // 片段着色器
            fixed4 frag (v2f i) : SV_Target
            {
                // 计算法线和光照方向
                float3 n = UnityObjectToWorldNormal(i.normal);
                n = normalize(n);
                float3 l = WorldSpaceLightDir(i.vertex);//Z：光照方向计算器，对点光源和平行光都适用（物体到光源，平行光反方向）
                l = normalize(l);

                // 转换顶点到世界空间
                float4 worldPos = mul(unity_ObjectToWorld, i.vertex);

                // Lambert光照计算（Z:其实就是漫反射）
                fixed ndotl = saturate(dot(n, l));
                fixed4 color = _LightColor0 * _MainColor * ndotl;

                // 叠加点光源的光照（Z：在基础光照的基础上，给物体 “叠加最多 4 个点光源的光照效果”）
                color.rgb += Shade4PointLights(//Z：这里分别用+ 和 *的原因？①：+表示颜色叠加（常用来在不同光效果之间叠加）； ②：*表示颜色过滤（常用在物体反射光时的情况）
                    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,//Z：4 个点光源在世界空间中的位置
                    unity_LightColor[0].rgb, unity_LightColor[1].rgb,//Z：4 个点光源的颜色（比如 “第一个是红光，第二个是蓝光”）
                    unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                    unity_4LightAtten0, worldPos.rgb, //Z：4 个点光源的衰减程度（离光源越远，光越暗，比如 “火把的光只照亮 1 米内”）
                    n //Z：物体表面的法线方向（判断 “这个面是否正对光源，越正对越亮”）
                ) * _MainColor;

                //Z：与上一个Pass区别，不用叠加环境光
                // 使用阴影宏计算阴影系数（Z：判断 “物体表面某点是否处于阴影中”，然后生成一个 “阴影系数”（比如 1 表示完全没阴影，0.3 表示处于中等阴影中））******************
                UNITY_LIGHT_ATTENUATION(shadowmask, i, worldPos.rgb)

                // 应用阴影到颜色（Z：用这个 “阴影系数” 给物体 “盖章，颜色取同）
                color.rgb *= shadowmask;

                return color; // 返回最终颜色
            }
            ENDCG
        }  
    }
    // 回退着色器，定义为Diffuse
    FallBack "Diffuse"
}
