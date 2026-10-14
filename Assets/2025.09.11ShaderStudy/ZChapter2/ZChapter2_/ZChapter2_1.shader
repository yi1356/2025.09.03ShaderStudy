//主要是为了理解世界空间、模型空间等
//根据顶点的世界坐标，来为像素添加颜色




// 整体流程总结：5 个空间在代码中的对应关系
// 模型空间：appdata.vertex（输入的原始顶点坐标）。
// 世界空间：v2f.worldPosition（通过unity_ObjectToWorld矩阵转换得到）。
// 观察空间：代码中没有显式存储，但UnityObjectToClipPos内部会经过这一步（世界→观察的转换）。
// 裁剪空间：v2f.vertex（通过UnityObjectToClipPos最终得到，用于裁剪和后续屏幕映射）。
// 屏幕空间：由 GPU 自动完成（裁剪空间坐标→齐次除法→NDC→屏幕映射），最终片元着色器的输出颜色会对应到屏幕上的像素。
Shader "ZChapter2/ZChapter2_1"
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
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;//Z：模型空间的顶点坐标
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;//Z：最后存储的是存储的是顶点在世界空间的坐标（世界空间坐标本质是三维的（x,y,z），但在 Shader 中习惯用float4（四维）存储）
              
                float4 vertex : SV_POSITION;//Z:最后存储的是存储的是顶点在 裁剪空间 的坐标
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)//Z：顶点着色器，***将模型空间的顶点，换到裁剪空间（模型-> 世界->观察->裁剪）***，并传递中间数据给片元着色器
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);//Z：模型空间→裁剪空间，最后存储的是存储的是顶点在 裁剪空间 的坐标
                o.worldPosition = mul(unity_ObjectToWorld,v.vertex);//Z：unity_ObjectToWorld：Unity 提供的 “模型到世界” 变换矩阵；最后存储的是存储的是顶点在世界空间的坐标
                                                                    //Z：mul 是 Shader 中专门用于矩阵乘法的函数，核心作用是 “用转换矩阵对坐标进行变换”。
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);  
                return o;
            }

            fixed4 frag (v2f i) : SV_Target//Z：片元着色器，职责就是计算当前像素的最终颜色，不涉及任何从一个空间到另一个空间的坐标转换
            {
                // sample the texture
                //Z：用顶点的世界坐标值，来给像素上色
                fixed4 col = fixed4(i.worldPosition.x,i.worldPosition.y,i.worldPosition.z,1);
                // apply fog
               
                return col;//Z：最终输出的颜色col会被 GPU 映射到屏幕空间的对应像素上（这一步由硬件自动完成，基于裁剪空间坐标的屏幕映射）
            }
            ENDCG
        }
    }
}
