Shader "Chapter5/chapter5_2_regular"
{
    // 定义Shader的属性，这些属性会在材质编辑器中显示，允许用户调整。
    Properties
    {
        // 定义一个控制细分（Tessellation）程度的滑块，范围是1到32，默认值为4。
        _Tess ("Tessellation", Range(1,32)) = 4
        
        // 定义基础颜色纹理属性，默认值为白色。
        _MainTex ("Base (RGB)", 2D) = "white" {}
        
        // 定义用于位移映射的纹理属性，默认值为灰色。
        _DispTex ("Disp Texture", 2D) = "gray" {}
        
        // 定义法线贴图属性，用于控制表面细节的法线效果，默认值为bump类型。
        _NormalMap ("Normalmap", 2D) = "bump" {}
        
        // 定义位移强度的滑块，范围是0到1，默认值为0.3。
        _Displacement ("Displacement", Range(0, 1.0)) = 0.3
        
        // 定义颜色属性，用于控制整体颜色，默认值为白色。
        _Color ("Color", color) = (1,1,1,0)
        
        // 定义镜面反射颜色属性，默认值为灰色。
        _SpecColor ("Spec color", color) = (0.5,0.5,0.5,0.5)
    }

    // 定义子着色器部分，包含渲染逻辑。
    SubShader
    {
        // 定义渲染标签，标记为不透明材质。
        Tags
        {
            "RenderType"="Opaque"
        }
        // 设置着色器的LOD（细节级别）为300。
        LOD 300

        // 开始CG代码块，定义基于Surface Shader的着色逻辑。
        CGPROGRAM
        // 使用BlinnPhong光照模型，启用阴影，并添加顶点位移和细分着色。
        #pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:disp tessellate:tessFixed nolightmap
        
        // 设置目标为Shader Model 4.6（支持更高级功能，如细分着色）。
        #pragma target 4.6

        // 定义应用程序顶点数据结构。
        struct appdata
        {
            float4 vertex : POSITION;  // 顶点位置
            float4 tangent : TANGENT; // 切线，用于法线映射
            float3 normal : NORMAL;   // 法线
            float2 texcoord : TEXCOORD0; // UV坐标
        };

        // 定义细分级别变量，用于控制细分程度。
        float _Tess;

        // 固定细分级别函数，返回细分强度。
        float4 tessFixed()
        {
            return _Tess; // 由用户设置的_Tess值决定细分强度。
        }

        // 定义用于位移贴图的纹理采样器和位移强度变量。
        sampler2D _DispTex;
        float _Displacement;

        // 位移函数，对顶点位置进行调整。
        void disp(inout appdata v)
        {
            // 使用纹理采样lod方式获取位移贴图值，并乘以位移强度。
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
            // 从主纹理中采样颜色，并乘以用户设置的基础颜色。
            half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            
            // 设置漫反射颜色（Albedo）。
            o.Albedo = c.rgb;
            
            // 设置镜面反射强度为0.2。
            o.Specular = 0.2;
            
            // 设置光泽度为1.0。
            o.Gloss = 1.0;
            
            // 从法线贴图中采样法线，并解包法线数据。
            o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
        }
        ENDCG // 结束CG代码块
    }

    // 当目标设备不支持当前Shader时，回退到Diffuse着色器。
    FallBack "Diffuse"
}
