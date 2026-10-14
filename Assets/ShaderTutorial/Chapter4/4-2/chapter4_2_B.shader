Shader "Chapter4/chapter4_2_B"
{
    Properties
    {
        // 定义一个主颜色属性，默认值为白色
        _MainColor ("Main Color", Color) = (1, 1, 1, 1)
        
        // 定义一个主纹理属性，默认值为白色纹理
        _MainTex ("Main Tex", 2D) = "white" {}
    }
    SubShader
    {
        // 设置渲染队列为普通几何体
        Tags {"Queue" = "Geometry"}

        Pass
        {
            // 设置光照模式为前向渲染的基础通道
            Tags {"LightMode" = "ForwardBase"}

            // 设置模板测试的状态
            Stencil
            {
                Ref 1                 // 模板参考值为1
                Comp NotEqual         // 如果模板缓冲值不等于参考值，则通过测试
                Pass Keep             // 如果通过测试，保持模板缓冲区的值不变
            }
            
            // 开始编写CG代码
            CGPROGRAM
            #pragma vertex vert       // 指定顶点着色器函数
            #pragma fragment frag     // 指定片段着色器函数
            #include "UnityCG.cginc" // 引入Unity的通用着色器工具函数
            #include "UnityLightingCommon.cginc" // 引入Unity光照相关的工具函数

            // 自定义的结构体，用于在顶点和片段着色器之间传递数据
            struct v2f
            {
                float4 pos : SV_POSITION;       // 裁剪空间位置
                float4 worldPos : TEXCOORD0;    // 世界空间位置
                float3 worldNormal : TEXCOORD1; // 世界法线
                float2 texcoord : TEXCOORD2;    // 纹理坐标
            };

            sampler2D _MainTex;       // 主纹理采样器
            float4 _MainTex_ST;       // 主纹理的平移缩放参数
            fixed4 _MainColor;        // 主颜色属性

            // 顶点着色器
            v2f vert (appdata_base v)
            {
                v2f o;
                // 将顶点位置从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // 将顶点位置从模型空间转换到世界空间
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                // 计算世界空间法线并归一化
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldNormal = normalize(worldNormal);

                // 应用纹理的平移和缩放变换
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                return o;
            }

            // 片段着色器
            fixed4 frag (v2f i) : SV_Target
            {
                // 计算从当前像素到光源的世界空间光照方向
                float3 worldLight = UnityWorldSpaceLightDir(i.worldPos.xyz);
                worldLight = normalize(worldLight);

                // 计算法线和光照方向的点积，并将结果限制在0到1之间
                fixed n = saturate(dot(i.worldNormal, worldLight));
                
                // 从主纹理采样颜色
                fixed4 color = tex2D(_MainTex, i.texcoord);

                // 计算光照效果，乘以主颜色、光照强度和光源颜色
                color.rgb *= _MainColor * n * _LightColor0.rgb;

                // 添加环境光的影响
                color.rgb += unity_AmbientSky.rgb;
                
                return color; // 返回最终颜色
            }
            ENDCG
        }
    }
}
