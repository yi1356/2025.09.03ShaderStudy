Shader "Chapter6/chapter6_line"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} // 声明一个名为_MainTex的2D纹理属性，默认值为白色纹理
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        } // 设置渲染类型为Opaque（不透明）
        LOD 100 // 设置LOD（Level of Detail）为100，表示较低的细节级别

        Pass
        {
            CGPROGRAM
            #pragma vertex vert  // 使用名为vert的顶点着色器
            #pragma geometry geom  // 使用名为geom的几何着色器
            #pragma fragment frag  // 使用名为frag的片段着色器

            #include "UnityCG.cginc"  // 引入UnityCG常用的着色器库

            // 输入顶点结构体，包含顶点位置和纹理坐标
            struct a2v
            {
                float4 vertex : POSITION; // 顶点位置
                float2 uv : TEXCOORD0; // 顶点纹理坐标
            };

            // 顶点着色器到几何着色器之间的中间结构体
            struct v2g
            {
                float4 vertex : POSITION; // 顶点位置
                float2 uv : TEXCOORD0; // 顶点纹理坐标
            };

            // 从几何着色器到片段着色器之间的数据结构
            struct g2f
            {
                float4 vertex : SV_POSITION; // 变换后的顶点位置
                float2 uv : TEXCOORD0; // 纹理坐标
            };

            // 声明_MainTex纹理采样器和ST变换矩阵
            sampler2D _MainTex;
            float4 _MainTex_ST;

            // 顶点着色器函数
            v2g vert(a2v v)
            {
                v2g o;
                o.vertex = v.vertex; // 传递顶点位置
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); // 变换纹理坐标
                return o;
            }

            // 几何着色器函数
            [maxvertexcount(6)] // 最大顶点输出数为6个（因为每条边输出2个顶点，总共3条边）
            void geom(triangle v2g input[3], inout LineStream<g2f> outStream)
            {
                // 遍历三角形的3个顶点
                for (int i = 0; i < 3; i++)
                {
                    g2f o;

                    // 处理当前顶点，将其转换为裁剪空间坐标并设置纹理坐标
                    o.vertex = UnityObjectToClipPos(input[i].vertex); // 将顶点位置从对象空间转换到裁剪空间
                    o.uv = input[i].uv; // 传递纹理坐标

                    // 将当前顶点添加到输出流
                    outStream.Append(o);

                    // 计算当前顶点的下一个顶点（形成边）
                    int next = (i + 1) % 3; // 使用环形索引来获得下一个顶点

                    // 处理下一个顶点
                    o.vertex = UnityObjectToClipPos(input[next].vertex); // 将下一个顶点的位置转换到裁剪空间
                    o.uv = input[next].uv; // 传递下一个顶点的纹理坐标

                    // 将下一个顶点添加到输出流
                    outStream.Append(o);
                }
            }


            // 片段着色器函数
            fixed4 frag(g2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv); // 从_MainTex纹理中采样颜色
                return col; // 返回采样的颜色
            }
            ENDCG
        }
    }

}