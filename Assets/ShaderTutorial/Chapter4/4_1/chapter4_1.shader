Shader "Chapter4/chapter4_1"
{
    Properties
    {
        // _MainTex: 纹理贴图，默认值为白色纹理
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor ("MainColor", Color) = (1,1,1,1)
    }
    SubShader
    {
        // 设置渲染类型为“不透明”，并指定光照模式为“ForwardBase”。
        Tags {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "LightMode"="ForwardBase"
        }
        LOD 100 // 设置最低的细节等级（LOD）

        // Pass阶段定义了渲染的一次完整过程。每个Pass包含顶点着色器和片段着色器的执行。
        Pass
        {
            Cull Front
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            // 声明顶点着色器和片段着色器
            #pragma vertex vert
            #pragma fragment frag

            // 引入Unity的常用着色器代码库
            #include "UnityCG.cginc"
            // 引入Unity的光照模型代码库
            #include "Lighting.cginc"

            // 顶点输入结构体，包含从模型传入的顶点数据
            struct appdata
            {
                // uv：纹理坐标
                float2 uv : TEXCOORD0;
                // vertex：物体空间中的顶点位置
                float4 vertex : POSITION;
                // normal：物体空间中的法线
                float3 normal : NORMAL;
            };

            // 顶点输出结构体，将数据传递到片段着色器
            struct v2f
            {
                // uv：纹理坐标
                float2 uv : TEXCOORD0;
                // vertex：裁剪空间中的顶点位置
                float4 vertex : SV_POSITION;
                // worldNormal：转换到世界空间的法线
                float3 worldNormal : TEXCOORD1;
            };

            // uniform变量：用于从外部传入的数据
            uniform sampler2D _MainTex; // 纹理采样器
            uniform float4 _MainTex_ST; // 纹理的平移和缩放参数
            fixed4 _MainColor;

            // 顶点着色器：将顶点从物体空间转换到裁剪空间，并计算法线的世界空间表示
            v2f vert(appdata v)
            {
                v2f o;
                // 将物体空间的顶点转换为裁剪空间
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 变换纹理坐标
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 将法线从物体空间转换到世界空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            // 片段着色器：根据纹理和光照计算每个像素的最终颜色
            fixed4 frag(v2f i) : SV_Target
            {
                // 从纹理中采样颜色
                fixed4 color = tex2D(_MainTex, i.uv);

                // 规范化法线（确保长度为1）
                fixed3 worldNormal = normalize(i.worldNormal);
                // 获取世界空间的光源方向并规范化
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                // 计算漫反射光照强度：点积计算法线与光源方向的夹角
                fixed3 diffuse = _LightColor0.rgb * saturate(dot(worldNormal, worldLight));

                // 将纹理颜色与漫反射光照强度相乘，得到最终颜色
                color.rgb *= diffuse;
                color.a *= _MainColor.a;

                // 返回最终颜色
                return color;
            }
            ENDCG
        }

        Pass
        {
            Cull Back
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            // 声明顶点着色器和片段着色器
            #pragma vertex vert
            #pragma fragment frag

            // 引入Unity的常用着色器代码库
            #include "UnityCG.cginc"
            // 引入Unity的光照模型代码库
            #include "Lighting.cginc"

            // 顶点输入结构体，包含从模型传入的顶点数据
            struct appdata
            {
                // uv：纹理坐标
                float2 uv : TEXCOORD0;
                // vertex：物体空间中的顶点位置
                float4 vertex : POSITION;
                // normal：物体空间中的法线
                float3 normal : NORMAL;
            };

            // 顶点输出结构体，将数据传递到片段着色器
            struct v2f
            {
                // uv：纹理坐标
                float2 uv : TEXCOORD0;
                // vertex：裁剪空间中的顶点位置
                float4 vertex : SV_POSITION;
                // worldNormal：转换到世界空间的法线
                float3 worldNormal : TEXCOORD1;
            };

            // uniform变量：用于从外部传入的数据
            uniform sampler2D _MainTex; // 纹理采样器
            uniform float4 _MainTex_ST; // 纹理的平移和缩放参数
            fixed4 _MainColor;

            // 顶点着色器：将顶点从物体空间转换到裁剪空间，并计算法线的世界空间表示
            v2f vert(appdata v)
            {
                v2f o;
                // 将物体空间的顶点转换为裁剪空间
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 变换纹理坐标
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 将法线从物体空间转换到世界空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            // 片段着色器：根据纹理和光照计算每个像素的最终颜色
            fixed4 frag(v2f i) : SV_Target
            {
                // 从纹理中采样颜色
                fixed4 color = tex2D(_MainTex, i.uv);

                // 规范化法线（确保长度为1）
                fixed3 worldNormal = normalize(i.worldNormal);
                // 获取世界空间的光源方向并规范化
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                // 计算漫反射光照强度：点积计算法线与光源方向的夹角
                fixed3 diffuse = _LightColor0.rgb * saturate(dot(worldNormal, worldLight));

                // 将纹理颜色与漫反射光照强度相乘，得到最终颜色
                color.rgb *= diffuse;
                color.a *= _MainColor.a;

                // 返回最终颜色
                return color;
            }
            ENDCG
        }
    }
}
