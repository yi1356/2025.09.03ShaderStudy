Shader "Chapter3/chapter3_2_vertex_half"
{
    Properties
    {
        // _MainTex：纹理属性，默认值为白色纹理
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // Tags：设置渲染类型为“Opaque”（不透明），光照模式为“ForwardBase”（前向渲染基础光照）
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
        LOD 100 // 设置最低的细节等级（LOD）

        // Pass阶段定义了渲染的一次完整过程。每个Pass包含顶点着色器和片段着色器的执行
        Pass
        {
            CGPROGRAM
            // 声明顶点着色器和片段着色器
            #pragma vertex vert
            #pragma fragment frag

            // 引入Unity常用的着色器代码库
            #include "UnityCG.cginc"
            // 引入Unity光照模型代码库
            #include "Lighting.cginc"

            // 顶点输入结构体：传入从模型中来的数据
            struct appdata
            {
                // uv：纹理坐标
                float2 uv : TEXCOORD0;
                // vertex：物体空间中的顶点位置
                float4 vertex : POSITION;
                // normal：物体空间中的法线
                float3 normal : NORMAL;
            };

            // 顶点输出结构体：传递数据给片段着色器
            struct v2f
            {
                // uv：纹理坐标
                float2 uv : TEXCOORD0;
                // vertex：裁剪空间中的顶点位置
                float4 vertex : SV_POSITION;
                // color：在顶点着色器中计算的颜色，传递给片段着色器
                fixed3 color : COLOR;
            };

            // uniform变量：用于从外部传入的数据
            uniform sampler2D _MainTex; // 纹理采样器
            uniform float4 _MainTex_ST; // 纹理的平移和缩放参数

            // 顶点着色器：将顶点从物体空间转换为裁剪空间，并计算颜色
            v2f vert(appdata v)
            {
                v2f o;
                // 将物体空间中的顶点转换为裁剪空间中的顶点
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 将纹理坐标进行变换
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 将法线从物体空间转换到世界空间，并规范化（使长度为1）
                fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                // 获取光源的世界空间位置并规范化
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                // 计算漫反射光照：将法线与光源的方向计算点积，并进行平滑处理
                // (dot(worldNormal, worldLight) * 0.5 + 0.5) 用于让点积的范围变为 [0, 1]，以适应颜色计算
                fixed3 diffuse = _LightColor0.rgb * (dot(worldNormal, worldLight) * 0.5 + 0.5);
                // 将计算出的颜色传递给输出结构体
                o.color = diffuse;
                return o;
            }

            // 片段着色器：根据纹理和计算的光照颜色来生成最终像素的颜色
            fixed4 frag(v2f i) : SV_Target
            {
                // 从纹理中采样颜色
                fixed4 color = tex2D(_MainTex, i.uv);
                // 将采样到的颜色与漫反射光照强度相乘，得到最终的颜色
                color.rgb = color.rgb * i.color;
                // 返回最终颜色
                return color;
            }
            ENDCG
        }
    }
}
