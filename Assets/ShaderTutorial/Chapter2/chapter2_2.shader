Shader "Chapter2/chapter2_2"
{
    Properties
    {
        // 定义一个纹理属性，名为 _MainTex，类型为 2D，默认值是白色纹理
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        // 定义渲染标签，标识这个shader属于“Opaque”类型，即不透明的物体
        Tags { "RenderType"="Opaque" }
        // 设置LOD（Level Of Detail，细节等级），数字越大LOD越低，性能开销越小
        LOD 100

        Pass
        {
            // 定义Shader的程序部分，使用CG语言编写
            CGPROGRAM
            // 声明顶点着色器（vert）和片段着色器（frag）
            #pragma vertex vert
            #pragma fragment frag
            // 启用雾效（Fog）支持，便于处理场景中的雾效
            #pragma multi_compile_fog

            // 引入Unity内置的CG库，包含一些常用函数和宏
            #include "UnityCG.cginc"

            // 顶点输入结构体，包含顶点位置和纹理坐标
            struct appdata
            {
                float4 vertex : POSITION; // 顶点位置
                float2 uv : TEXCOORD0;    // 纹理坐标
            };

            // 顶点输出结构体，包含纹理坐标、雾效坐标、世界位置以及裁剪后的顶点位置
            struct v2f
            {
                float2 uv : TEXCOORD0;          // 纹理坐标
                UNITY_FOG_COORDS(1)             // 雾效坐标
                float4 worldPosition : TEXCOORD1; // 世界空间中的顶点位置
                float4 vertex : SV_POSITION;     // 裁剪后的顶点位置
            };

            // 声明材质的纹理变量
            sampler2D _MainTex;
            // 声明纹理的缩放和平移信息
            float4 _MainTex_ST;

            // 顶点着色器函数，将顶点位置转为裁剪空间，计算纹理坐标和世界空间位置
            v2f vert (appdata v)
            {
                v2f o;
                // 使用Unity内置函数将对象空间的顶点位置转化为裁剪空间
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 使用内置宏将纹理坐标进行缩放和偏移处理
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 计算顶点的世界空间位置
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                // 处理雾效，传递顶点位置给雾效计算函数
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            // 片段着色器函数，计算每个像素的颜色
            fixed4 frag (v2f i) : SV_Target
            {
                // 计算水平线的世界坐标位置（这里的水平线是Y=0的位置）
                half4 horLine = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
                // 计算当前片段与水平线（Y=0）之间的偏移量
                half yOffset = horLine.y - i.worldPosition.y;
                // 使用smoothstep函数生成平滑的颜色过渡，yOffset决定过渡的范围
                half4 col = smoothstep(0, 0.3, yOffset);
                
                // 返回计算出来的颜色
                return col;
            }
            ENDCG
        }
    }
}
