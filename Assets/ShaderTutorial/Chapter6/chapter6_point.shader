Shader "Chapter6/chapter6_point"
{
Properties
    {
        _MainTex ("Texture", 2D) = "white" {}  // 声明一个名为_MainTex的2D纹理属性，默认值为白色纹理
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }  // 设置渲染类型为Opaque（不透明）
        LOD 100  // 设置LOD（Level of Detail）为100，表示较低的细节级别

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
                float4 vertex : POSITION;  // 顶点位置
                float2 uv : TEXCOORD0;     // 顶点纹理坐标
            };

            // 顶点着色器到几何着色器之间的中间结构体
            struct v2g
            {
                float4 vertex : POSITION;  // 顶点位置
                float2 uv : TEXCOORD0;     // 顶点纹理坐标
            };

            // 从几何着色器到片段着色器之间的数据结构
            struct g2f
            {
                float4 vertex : SV_POSITION;  // 变换后的顶点位置
                float2 uv : TEXCOORD0;        // 纹理坐标
            };

            // 声明_MainTex纹理采样器和ST变换矩阵
            sampler2D _MainTex;
            float4 _MainTex_ST;

            // 顶点着色器函数
            v2g vert (a2v v)
            {
                v2g o;
                o.vertex = v.vertex;  // 传递顶点位置
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);  // 变换纹理坐标
                return o;
            }

            // 几何着色器函数
            [maxvertexcount(1)]  // 每个几何着色器输出1个顶点
            void geom(triangle v2g input[3], inout PointStream<g2f> outStream)
            {
                // 计算输入的3个顶点的平均位置和纹理坐标
                float4 vertex = float4(0, 0, 0, 0);
                float2 uv = float2(0, 0);

                vertex = (input[0].vertex + input[1].vertex + input[2].vertex) / 3;  // 计算平均顶点位置
                uv = (input[0].uv + input[1].uv + input[2].uv) / 3;  // 计算平均纹理坐标

                // 输出到片段着色器的数据
                g2f o;
                o.vertex = UnityObjectToClipPos(vertex);  // 将顶点位置转换为裁剪空间
                o.uv = uv;  // 设置纹理坐标

                outStream.Append(o);  // 将输出数据加入到流中
            }

            // 片段着色器函数
            fixed4 frag (g2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);  // 从_MainTex纹理中采样颜色
                return col;  // 返回采样的颜色
            }
            ENDCG
        }
    }

}