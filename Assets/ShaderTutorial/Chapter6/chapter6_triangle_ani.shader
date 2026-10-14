Shader "Chapter6/chapter6_triangle_ani"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} // 主纹理
        _BottomColor ("Bottom Color", Color) = (0, 0, 0, 1) // 底部颜色
        _TopColor ("Top Color", Color) = (1, 1, 1, 1) // 顶部颜色
        _ExtrudeMaxValue ("Extrude Max Value", Range(0, 1)) = 1 // 最大挤出值
        _ExtrudeRandomValue ("Extrude Random Value", Range(0, 1)) = 1 // 随机挤出值
        _ExtrudeSpeed ("Extrude Speed", Float) = 1 // 挤出速度
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        } // 渲染类型为不透明
        LOD 100 // 细节级别

        Pass
        {
            Cull Off // 关闭背面剔除

            CGPROGRAM
            #pragma vertex vert  // 顶点着色器
            #pragma geometry geom  // 几何着色器
            #pragma fragment frag  // 片段着色器

            #include "UnityCG.cginc"  // 包含Unity的CG库

            // 顶点着色器输入结构
            struct a2v
            {
                float4 vertex : POSITION; // 顶点位置
                float2 uv : TEXCOORD0; // 纹理坐标
            };

            // 顶点着色器输出结构
            struct v2g
            {
                float4 vertex : POSITION; // 顶点位置
                float2 uv : TEXCOORD0; // 纹理坐标
            };

            // 几何着色器输出结构
            struct g2f
            {
                float4 vertex : SV_POSITION; // 裁剪空间中的顶点位置
                float2 uv : TEXCOORD0; // 纹理坐标
                float4 color : COLOR; // 顶点颜色
            };

            sampler2D _MainTex; // 主纹理
            float4 _MainTex_ST; // 主纹理的缩放和偏移
            float4 _BottomColor; // 底部颜色
            float4 _TopColor; // 顶部颜色
            float _ExtrudeMaxValue; // 最大挤出值
            float _ExtrudeRandomValue; // 随机挤出值
            float _ExtrudeSpeed; // 挤出速度

            // 顶点着色器
            v2g vert(a2v v)
            {
                v2g o;
                o.vertex = v.vertex; // 传递顶点位置
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); // 转换纹理坐标
                return o;
            }

            // 计算法线
            float3 ConstructNormal(float3 v1, float3 v2, float3 v3)
            {
                return normalize(cross(v2 - v1, v3 - v1)); // 通过叉积计算法线
            }

            // 几何着色器
            [maxvertexcount(21)] // 最大顶点数
            void geom(triangle v2g input[3], uint pid : SV_PrimitiveID, inout TriangleStream<g2f> outStream)
            {
                // 计算挤出量，基于时间和速度
                // 计算基础挤出量：基于时间的周期性变化
                float baseExtrude = cos(_Time.y * 2 * UNITY_PI * _ExtrudeSpeed); // 范围 [-1, 1]
                baseExtrude = baseExtrude * 0.5 + 0.5; // 映射到 [0, 1]
                baseExtrude *= _ExtrudeMaxValue; // 控制挤出量的最大幅度

                // 计算随机挤出量：基于时间和图元 ID 的随机变化
                float randomSeed = pid * 853.8425415; // 使用图元 ID 作为随机种子
                float randomExtrude = sin(randomSeed + _Time.y * 2 * UNITY_PI * _ExtrudeSpeed); // 范围 [-1, 1]
                randomExtrude = randomExtrude * 0.5 + 0.5; // 映射到 [0, 1]
                randomExtrude *= _ExtrudeRandomValue; // 控制随机挤出量的强度

                // 最终挤出量 = 基础挤出量 + 随机挤出量
                float extrudeAmount = baseExtrude + randomExtrude;
                // 计算法线并乘以挤出量
                float3 normal = ConstructNormal(input[0].vertex, input[1].vertex, input[2].vertex);
                normal = normal * extrudeAmount;

                g2f o;

                // 生成三角形的侧面
                for (int i = 0; i < 3; i++)
                {
                    int index = (i + 1) % 3;

                    // 底部顶点
                    o.vertex = input[i].vertex;
                    o.vertex = UnityObjectToClipPos(o.vertex);
                    o.uv = input[i].uv;
                    o.color = _BottomColor;
                    outStream.Append(o);

                    // 顶部顶点
                    o.vertex = input[i].vertex;
                    o.vertex.xyz += normal;
                    o.vertex = UnityObjectToClipPos(o.vertex);
                    o.uv = input[i].uv;
                    o.color = _TopColor;
                    outStream.Append(o);

                    // 下一个底部顶点
                    o.vertex = input[index].vertex;
                    o.vertex = UnityObjectToClipPos(o.vertex);
                    o.uv = input[index].uv;
                    o.color = _BottomColor;
                    outStream.Append(o);

                    outStream.RestartStrip(); // 结束当前三角形带

                    // 顶部顶点
                    o.vertex = input[i].vertex;
                    o.vertex.xyz += normal;
                    o.vertex = UnityObjectToClipPos(o.vertex);
                    o.uv = input[i].uv;
                    o.color = _TopColor;
                    outStream.Append(o);

                    // 下一个底部顶点
                    o.vertex = input[index].vertex;
                    o.vertex = UnityObjectToClipPos(o.vertex);
                    o.uv = input[index].uv;
                    o.color = _BottomColor;
                    outStream.Append(o);

                    // 下一个顶部顶点
                    o.vertex = input[index].vertex;
                    o.vertex.xyz += normal;
                    o.vertex = UnityObjectToClipPos(o.vertex);
                    o.uv = input[index].uv;
                    o.color = _TopColor;
                    outStream.Append(o);

                    outStream.RestartStrip(); // 结束当前三角形带
                }

                // 生成顶部三角形
                for (int i = 0; i < 3; i++)
                {
                    o.vertex = input[i].vertex;
                    o.vertex.xyz += normal;
                    o.vertex = UnityObjectToClipPos(o.vertex);
                    o.uv = input[i].uv;
                    o.color = _TopColor;
                    outStream.Append(o);
                }

                outStream.RestartStrip(); // 结束当前三角形带
            }

            // 片段着色器
            fixed4 frag(g2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * i.color; // 采样纹理并乘以颜色
                return col;
            }
            ENDCG
        }
    }
}