Shader "Chapter3/chapter3_1_vertex"
{
    // Shader 属性（Properties）部分：定义了外部可以调整的参数。
    Properties
    {
        // _MainTex：纹理贴图，默认值为白色纹理
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // SubShader 标签（Tags）：定义了渲染模式与渲染顺序
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
        LOD 100 // 设置最低的细节等级（LOD）

        // Pass 说明渲染过程的一个阶段。每个 Pass 都会执行顶点着色器和片段着色器。
        Pass
        {
            CGPROGRAM
            // 声明使用的着色器语言
            #pragma vertex vert
            #pragma fragment frag

            // 包含 Unity 的常用着色器代码库
            #include "UnityCG.cginc"
            // 包含 Unity 的光照模型代码库
            #include "Lighting.cginc"

            // 定义输入结构体，传入顶点着色器的数据
            struct appdata
            {
                // uv：纹理坐标
                float2 uv : TEXCOORD0;
                // vertex：顶点位置
                float4 vertex : POSITION;
                // normal：表面法线
                float3 normal : NORMAL;
            };

            // 定义输出结构体，传递数据到片段着色器
            struct v2f
            {
                // uv：纹理坐标
                float2 uv : TEXCOORD0;
                // vertex：变换后的顶点位置（裁剪空间位置）
                float4 vertex : SV_POSITION;
                // color：计算得到的漫反射光照颜色
                fixed3 color : COLOR;
            };

            // 定义 uniform 变量，用于存储外部传入的数据
            uniform sampler2D _MainTex; // 纹理采样器
            uniform float4 _MainTex_ST; // 纹理的平移和缩放参数

            // 顶点着色器：负责处理顶点数据并进行必要的变换
            v2f vert(appdata v)
            {
                v2f o;
                // 将物体空间的顶点转换为裁剪空间的顶点
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 变换纹理坐标
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // 计算世界空间的法线：将物体空间法线转换为世界空间
                fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                // 计算世界空间的光照方向：获取光源方向并标准化
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                // 计算漫反射光照强度（Dot product）：计算法线与光源方向的点积并应用光源的颜色
                fixed3 diffuse = _LightColor0.rgb * saturate(dot(worldNormal, worldLight));

                // 将计算的漫反射颜色传递给输出
                o.color = diffuse;

                // 返回处理后的数据
                return o;
            }

            // 片段着色器：负责计算每个像素的颜色
            fixed4 frag(v2f i) : SV_Target
            {
                // 采样纹理颜色
                fixed4 color = tex2D(_MainTex, i.uv);
                // 将纹理颜色与漫反射光照强度相乘，得到最终的颜色
                color.rgb = color.rgb * i.color;
                // 返回最终颜色
                return color;
            }

            ENDCG
        }
    }
}
