Shader "Chapter5/chapter5_3_edge"
{
    // 定义材质属性，用于调整材质的外观效果。
    Properties
    {
        // 边缘长度属性，用于控制细分曲面的细化程度，范围为2到50，默认值为15。
        _EdgeLength ("Edge length", Range(2,50)) = 15
        
        // 主纹理（基础颜色纹理），用于控制物体表面的颜色显示，默认值为白色。
        _MainTex ("Base (RGB)", 2D) = "white" {}
        
        // 位移贴图属性，用于生成位移效果，默认值为灰色纹理。
        _DispTex ("Disp Texture", 2D) = "gray" {}
        
        // 法线贴图属性，用于控制表面法线的细节显示，默认值为bump类型。
        _NormalMap ("Normalmap", 2D) = "bump" {}
        
        // 位移强度属性，范围为0到1，控制位移效果的强度，默认值为0.3。
        _Displacement ("Displacement", Range(0, 1.0)) = 0.3
        
        // 基础颜色属性，用于给材质添加颜色，默认值为白色。
        _Color ("Color", color) = (1,1,1,0)
        
        // 镜面反射颜色属性，控制镜面高光的颜色，默认值为灰色。
        _SpecColor ("Spec color", color) = (0.5,0.5,0.5,0.5)
    }

    // 定义子着色器（SubShader），包含材质的具体渲染实现。
    SubShader
    {
        // 设置渲染标签，标记为不透明材质。
        Tags
        {
            "RenderType"="Opaque"
        }
        // 设置Shader的LOD（细节级别）为300，决定渲染质量和性能的平衡。
        LOD 300

        // 开始CG代码块，定义基于Surface Shader的渲染逻辑。
        CGPROGRAM
        // 使用BlinnPhong光照模型，启用阴影、全前向渲染、顶点位移函数（disp），以及边缘长度细分（tessEdge）。
        #pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:disp tessellate:tessEdge nolightmap
        
        // 设置目标为Shader Model 4.6（支持高级功能，如细分曲面）。
        #pragma target 4.6

        // 包含Unity内置的细分曲面库，提供细分算法支持。
        #include "Tessellation.cginc"

        // 定义顶点数据结构，用于从应用程序传递数据到GPU。
        struct appdata
        {
            float4 vertex : POSITION;  // 顶点位置
            float4 tangent : TANGENT; // 切线向量，用于法线贴图
            float3 normal : NORMAL;   // 法线向量
            float2 texcoord : TEXCOORD0; // UV坐标
        };

        // 定义边缘长度属性变量，用于控制细分程度。
        float _EdgeLength;

        // 边缘长度细分函数，基于三角形顶点的位置计算细分因子。
        float4 tessEdge(appdata v0, appdata v1, appdata v2)
        {
            // 使用Unity内置的基于边缘长度的细分函数。
            return UnityEdgeLengthBasedTess(v0.vertex, v1.vertex, v2.vertex, _EdgeLength);
        }

        // 位移贴图采样器和位移强度变量，用于控制顶点位移效果。
        sampler2D _DispTex;
        float _Displacement;

        // 顶点位移函数，根据法线方向和位移贴图调整顶点位置。
        void disp(inout appdata v)
        {
            // 从位移贴图中采样高度值，并乘以位移强度。
            float d = tex2Dlod(_DispTex, float4(v.texcoord.xy, 0, 0)).r * _Displacement;
            // 根据法线方向调整顶点位置，实现位移效果。
            v.vertex.xyz += v.normal * d;
        }

        // 定义输入结构体，用于传递UV坐标。
        struct Input
        {
            float2 uv_MainTex; // 主纹理的UV坐标。
        };

        // 定义其他所需变量。
        sampler2D _MainTex;    // 主纹理采样器。
        sampler2D _NormalMap;  // 法线贴图采样器。
        fixed4 _Color;         // 基础颜色。

        // Surface函数，处理表面着色逻辑。
        void surf(Input IN, inout SurfaceOutput o)
        {
            // 从主纹理中采样颜色，并乘以基础颜色。
            half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            
            // 设置材质的漫反射颜色（Albedo）。
            o.Albedo = c.rgb;
            
            // 设置材质的镜面反射强度为0.2。
            o.Specular = 0.2;
            
            // 设置材质的光泽度为1.0。
            o.Gloss = 1.0;
            
            // 从法线贴图中采样法线数据，并解包为适用的法线值。
            o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
        }
        ENDCG // 结束CG代码块
    }

    // 当目标设备不支持当前Shader时，回退到简单的Diffuse Shader。
    FallBack "Diffuse"
}
