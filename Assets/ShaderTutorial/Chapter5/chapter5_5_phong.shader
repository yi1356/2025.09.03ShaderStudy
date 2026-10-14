Shader "Chapter5/chapter5_5_phong"
{
    Properties
    {
        _EdgeLength ("边缘长度", Range(2,50)) = 5   // 边缘长度，控制细分的精度
        _Phong ("Phong 强度", Range(0,1)) = 0.5    // Phong高光强度
        _MainTex ("基础纹理 (RGB)", 2D) = "white" {} // 基础纹理，默认为白色
        _Color ("颜色", color) = (1,1,1,0)            // 颜色，默认为白色
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" // 渲染类型为不透明
        }
        LOD 300 // 设置细节等级

        CGPROGRAM
        #pragma surface surf Lambert vertex:dispNone tessellate:tessEdge tessphong:_Phong nolightmap
        #include "Tessellation.cginc"  // 引入细分曲面相关函数

        // 顶点数据结构
        struct appdata
        {
            float4 vertex : POSITION;  // 顶点位置
            float3 normal : NORMAL;    // 法线向量
            float2 texcoord : TEXCOORD0; // 纹理坐标
        };

        // 顶点处理函数，空函数，不做操作
        void dispNone(inout appdata v)
        {
        }

        // Phong高光强度和边缘长度
        float _Phong;
        float _EdgeLength;

        // 细分计算函数，基于边缘长度来决定细分的精度
        float4 tessEdge(appdata v0, appdata v1, appdata v2)
        {
            return UnityEdgeLengthBasedTess(v0.vertex, v1.vertex, v2.vertex, _EdgeLength);
        }

        // 输入结构体，包含纹理坐标
        struct Input
        {
            float2 uv_MainTex; // 纹理坐标
        };

        // 颜色和纹理采样器
        fixed4 _Color;
        sampler2D _MainTex;

        // 表面函数，定义了如何从纹理获取颜色并应用
        void surf(Input IN, inout SurfaceOutput o)
        {
            half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color; // 从纹理获取颜色并乘以颜色属性
            o.Albedo = c.rgb;  // 将RGB颜色设置为Albedo
            o.Alpha = c.a;     // 将Alpha通道设置为透明度
        }
        ENDCG
    }
    FallBack "Diffuse"  // 如果此Shader不可用，则回退使用“Diffuse”Shader
}
