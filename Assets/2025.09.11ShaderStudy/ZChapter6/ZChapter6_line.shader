//作用：将三角形以线的形式，来显示模型

//思路：设置好顶点着色器、几何着色器、片元着色器需要的数据结构；在几何着色器中计算三角形三个顶点并连接成线，并append到结果流中；

Shader "ZChapter6/ZChapter6_line"
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
            [maxvertexcount(6)]   //最大顶点输出数是6个(因为每条边输出2个顶点 ， 共3条边)
            void geom(triangle v2g input[3], inout LineStream<g2f> outStream)//Z：triangle v2g input[3]：输入是三角形图元，包含 3 个顶点数据（input[0]、input[1]、input[2]对应三角形的 3 个顶点）
                                                                              //Z：区别——————inout LineStream<g2f> outStream 表示输出的是线图元流（Line Stream），即几何着色器最终会生成线段，而非原始的三角形。，表示输出的是点图元，g2f是输出数据的结构
            {
                //Z：循环执行 3 次（对应三角形的 3 条边），每次循环处理一条边
                //Z：每次循环中，outStream.Append(o) 连续添加两个顶点，而LineStream 会自动将每两个连续的顶点组成一条线段
                for(int i=0; i<3; i++)
                {
                // 输出到片元着色器的数据
                g2f o;
                //处理当前顶点，将其转换为剪裁空间坐标并设置纹理坐标
                o.vertex = UnityObjectToClipPos(input[i].vertex); //将顶点位置从对象空间转换到剪裁空间
                o.uv = input[i].uv; // 传递纹理坐标
                //将当前顶点添加到输出流
                outStream.Append(o);   

                //处理下一个顶点
                int next=(i+1)%3;
                o.vertex = UnityObjectToClipPos(input[next].vertex);
                o.uv = input[next].uv;
                outStream.Append(o);  

                }

               
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
