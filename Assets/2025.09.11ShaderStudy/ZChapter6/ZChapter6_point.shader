//作用：将三角形变化为点，来显示模型

//思路：设置好顶点着色器、几何着色器、片元着色器需要的数据结构；在几何着色器中计算三角形三个顶点位置的平均值和三个uv的平均值，并append到结果流中；

Shader "ZChapter6/ZChapter6_point"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom  // 使用名为geom的几何着色器
            #pragma fragment frag


            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            //Z: 顶点着色器 到 几何着色器之间的中间结构体********************************
            struct v2g
            {
                float4 vertex : POSITION; // 顶点位置
                float2 uv : TEXCOORD0;    // 顶点纹理坐标
            };
            

            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2g vert (a2v v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            //Z：几何着色器函数***********************************************************
            [maxvertexcount(1)]   //每个几何着色器输出1个顶点
            void geom(triangle v2g input[3], inout PointStream<g2f> outStream)//Z：triangle v2g input[3]：输入是三角形图元，包含 3 个顶点数据（input[0]、input[1]、input[2]对应三角形的 3 个顶点）
                                                                              //Z：inout PointStream<g2f> outStream：输出流，类型为PointStream（点流），表示输出的是点图元，g2f是输出数据的结构
            {
                //计算输入的3个顶点的平均位置 和 纹理坐标
                float4 vertex = (input[0].vertex + input[1].vertex + input[2].vertex) / 3;
                float2 uv = (input[0].uv + input[1].uv + input[2].uv) / 3;

                // 输出到片元着色器的数据
                g2f o;
                o.vertex = UnityObjectToClipPos(vertex);
                o.uv = uv;

                outStream.Append(o);   //Z：将输出数据加入到流中 (将计算好的点数据添加到输出流，最终会被传递给片元着色器)
            }

            fixed4 frag (g2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
