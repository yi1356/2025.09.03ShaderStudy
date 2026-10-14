Shader "Chapter1/Test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}  // 定义一个2D纹理属性，默认为白色
        [Header(Color)]
        _Red("Red",Range(0,1)) = 1
        _Green("Green",Range(0,1)) = 1
        _Blue("Blue",Range(0,1)) = 1
        _Alpha("Alpha",Range(0,1)) = 1
    }
    SubShader
    {
        Tags {
            "Queue"="Transparent" // 设置渲染队列为透明队列，表示该对象会在不透明对象后渲染
            "RenderType"="Transparent" // 设置渲染类型为透明类型
        }

        Blend SrcAlpha OneMinusSrcAlpha // 设置混合模式，表示使用源的Alpha值和目标的Alpha值进行混合
        LOD 100 // 设置Shader的细节层次，其实就是多个SubShader里设置不同的这个值，因为高中低端机不一样
        //lod 越大的对应性能越好，越低的性能越差

        Pass
        {
            CGPROGRAM
            #pragma vertex vert  // 使用自定义的顶点着色器函数vert
            #pragma fragment frag  // 使用自定义的片段着色器函数frag
            // 使得雾效能够生效
            #pragma multi_compile_fog  // 允许多个雾效变种

            #include "UnityCG.cginc"  // 引入Unity内置的CG库，提供各种常用函数

            struct appdata
            {
                float4 vertex : POSITION;  // 顶点位置
                float2 uv : TEXCOORD0;     // 顶点的纹理坐标
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;      // 传递给片段着色器的纹理坐标
                UNITY_FOG_COORDS(1)         // Unity的雾效坐标
                float4 vertex : SV_POSITION;  // 传递给片段着色器的裁剪空间位置
            };

            sampler2D _MainTex;  // 定义纹理采样器
            float4 _MainTex_ST;  // 纹理的平移、缩放和旋转参数
            float _Red;
            float _Green;
            float _Blue;
            float _Alpha;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);  // 将顶点从模型空间转换为裁剪空间
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);  // 转换纹理坐标
                UNITY_TRANSFER_FOG(o, o.vertex);  // 传递雾效坐标
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 使用纹理坐标采样纹理颜色
                fixed4 col = tex2D(_MainTex, i.uv);
                // 应用雾效
                UNITY_APPLY_FOG(i.fogCoord, col);  // 根据雾效坐标调整颜色
                //return col;  // 返回最终颜色
                return half4(_Red,_Green,_Blue,_Alpha);  // 返回最终颜色
            }
            ENDCG
        }
    }
}
