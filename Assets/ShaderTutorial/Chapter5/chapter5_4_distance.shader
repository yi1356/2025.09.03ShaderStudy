Shader "Chapter5/chapter5_4_distance"
{
    // 定义材质属性，供用户在编辑器中调整材质的参数。
    Properties
    {
        // 控制细分曲面因子的强度，范围是1到32，默认值为4。
        _Tess ("Tessellation", Range(1,32)) = 4
        
        // 最大距离。
        _MaxDis ("MaxDis", Range(1,100)) = 50
        
        // 最小距离。
        _MinDis ("MinDis", Range(1,100)) = 20

        // 主纹理，用于显示基础颜色纹理，默认值为白色。
        _MainTex ("Base (RGB)", 2D) = "white" {}

        // 位移贴图，用于生成位移效果，默认值为灰色纹理。
        _DispTex ("Disp Texture", 2D) = "gray" {}

        // 法线贴图，用于控制材质表面法线的细节显示，默认值为bump类型。
        _NormalMap ("Normalmap", 2D) = "bump" {}

        // 位移强度，用于调整顶点位移效果的强度，范围为0到1，默认值为0.3。
        _Displacement ("Displacement", Range(0, 1.0)) = 0.3

        // 基础颜色，用于调整材质的颜色，默认值为白色。
        _Color ("Color", color) = (1,1,1,0)

        // 镜面高光颜色，用于调整材质的镜面反射颜色，默认值为中灰色。
        _SpecColor ("Spec color", color) = (0.5,0.5,0.5,0.5)
    }

    // 定义子着色器，用于实现材质的具体渲染效果。
    SubShader
    {
        // 设置渲染类型标签，将材质标记为不透明（Opaque）。
        Tags
        {
            "RenderType"="Opaque"
        }
        // 设置细节级别（LOD），用于控制渲染质量与性能的平衡。
        LOD 300

        // 开始CG代码块，定义Shader的具体实现逻辑。
        CGPROGRAM
        // 使用Blinn-Phong光照模型，支持阴影、前向渲染和顶点位移（disp），并启用基于距离的细分曲面（tessDistance）。
        #pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:disp tessellate:tessDistance nolightmap
        
        // 设置目标Shader模型版本为4.6，支持高级图形功能（如细分曲面）。
        #pragma target 4.6

        // 包含Unity内置的细分曲面库文件，提供相关算法和工具。
        #include "Tessellation.cginc"

        // 定义顶点数据结构，用于传递顶点信息。
        struct appdata
        {
            float4 vertex : POSITION;  // 顶点位置。
            float4 tangent : TANGENT; // 切线向量，用于法线贴图。
            float3 normal : NORMAL;   // 法线向量。
            float2 texcoord : TEXCOORD0; // UV纹理坐标。
        };

        // 定义细分曲面强度属性。
        float _Tess;
        float _MaxDis;
        float _MinDis;

        // 基于距离的细分曲面函数，使用Unity内置的算法。
        float4 tessDistance(appdata v0, appdata v1, appdata v2)
        {
            // 设置最小和最大细分距离。
            float minDist = _MinDis; // 最小距离，细分强度较大。
            float maxDist = _MaxDis; // 最大距离，细分强度较小。

            // 调用Unity的内置函数，根据顶点与相机的距离计算细分因子。
            return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
        }

        // 位移贴图采样器和位移强度变量，用于生成顶点位移效果。
        sampler2D _DispTex;
        float _Displacement;

        // 顶点位移函数，通过位移贴图调整顶点位置。
        void disp(inout appdata v)
        {
            // 从位移贴图中采样位移值（高度值），并根据位移强度调整。
            float d = tex2Dlod(_DispTex, float4(v.texcoord.xy, 0, 0)).r * _Displacement;

            // 根据顶点法线方向对顶点进行偏移，实现位移效果。
            v.vertex.xyz += v.normal * d;
        }

        // 定义输入结构体，用于传递UV坐标等信息。
        struct Input
        {
            float2 uv_MainTex; // 主纹理的UV坐标。
        };

        // 定义所需的采样器和颜色变量。
        sampler2D _MainTex;    // 主纹理采样器。
        sampler2D _NormalMap;  // 法线贴图采样器。
        fixed4 _Color;         // 基础颜色。

        // Surface函数，用于处理材质的表面着色逻辑。
        void surf(Input IN, inout SurfaceOutput o)
        {
            // 从主纹理中采样颜色，并与基础颜色相乘。
            half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;

            // 设置材质的漫反射颜色（Albedo）。
            o.Albedo = c.rgb;

            // 设置材质的镜面反射强度。
            o.Specular = 0.2;

            // 设置材质的光泽度（Gloss）。
            o.Gloss = 1.0;

            // 从法线贴图中采样法线数据，并解包为适用的法线值。
            o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
        }
        ENDCG // 结束CG代码块
    }

    // 设置回退着色器。当目标设备不支持当前Shader时，使用简单的Diffuse Shader。
    FallBack "Diffuse"
}
