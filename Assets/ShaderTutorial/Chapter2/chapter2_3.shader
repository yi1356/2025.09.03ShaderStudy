Shader "Chapter2/chapter2_3"
{
    Properties
    {
        // 定义一个纹理属性，名为 _MainTex，类型为 2D，默认值为白色纹理
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        // 定义渲染标签，标识此 Shader 属于不透明（Opaque）类型
        Tags { "RenderType"="Opaque" }
        // 设置 LOD（细节等级），数字越大LOD越低，性能开销越小
        LOD 100

        Pass
        {
            // 开始CG程序部分，声明顶点着色器（vert）和片段着色器（frag）
            CGPROGRAM
            #pragma vertex vert  // 指定顶点着色器函数
            #pragma fragment frag // 指定片段着色器函数
            // 启用雾效支持，处理场景中的雾效
            #pragma multi_compile_fog

            // 引入Unity内置的CG库，提供常用函数和宏
            #include "UnityCG.cginc"

            // 定义顶点输入结构体，包含顶点位置和纹理坐标
            struct appdata
            {
                float4 vertex : POSITION; // 顶点位置
                float2 uv : TEXCOORD0;    // 纹理坐标
            };

            // 定义顶点输出结构体，包含纹理坐标、雾效坐标、世界空间位置和裁剪空间顶点位置
            struct v2f
            {
                float2 uv : TEXCOORD0;           // 纹理坐标
                UNITY_FOG_COORDS(1)              // 雾效坐标
                float4 worldPosition : TEXCOORD1; // 世界空间位置
                float4 vertex : SV_POSITION;     // 裁剪空间中的顶点位置
            };

            // 声明材质的纹理变量
            sampler2D _MainTex;
            // 声明纹理的缩放和平移信息
            float4 _MainTex_ST;

            // 顶点着色器函数，将顶点从对象空间转换到裁剪空间，并计算纹理坐标和世界空间位置
            v2f vert (appdata v)
            {
                v2f o;
                // 将顶点从对象空间转换到裁剪空间
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 计算纹理坐标，并根据 _MainTex 进行缩放和平移
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 计算顶点的世界空间位置
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                // 传递顶点位置给雾效计算函数
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            // 片段着色器函数，计算每个像素的颜色
            fixed4 frag (v2f i) : SV_Target
            {
                // 计算（0, 0, 0）位置的顶点，转换到裁剪空间
                float4 pos = UnityObjectToClipPos(float4(0, 0, 0, 1));
                // 计算水平和垂直方向上的平滑过渡效果
                // 使用 smoothstep 生成平滑的渐变效果，基于绝对值计算
                float4 col = smoothstep(1, 0, abs(pos.x / pos.w)) * smoothstep(1, 0, abs(pos.y / pos.w));
                
                // 返回计算出的颜色
                return col;
            }
            ENDCG
        }
    }
}
