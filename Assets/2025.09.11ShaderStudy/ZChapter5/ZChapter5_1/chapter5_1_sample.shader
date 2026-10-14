//作用：展示一个最简单的表面着色器

//思路：
//分三部分：属性、子着色器、表面函数


Shader "Chapter5/chapter5_1_sample"
{
    //一、属性
    // 定义Shader的属性（Properties），这些属性会显示在材质面板中，允许用户进行调整。
    Properties
    {
        // 定义一个颜色属性，默认值为白色 (1,1,1,1)。
        _Color ("Color", Color) = (1,1,1,1)        
        // 定义一个2D纹理属性，表示材质的基础颜色贴图（Albedo），默认值为白色纹理。
        _MainTex ("Albedo (RGB)", 2D) = "white" {}        
        // 定义光滑度（Smoothness）的滑块，范围是0到1，默认值为0.5。
        _Glossiness ("Smoothness", Range(0,1)) = 0.5        
        // 定义金属度（Metallic）的滑块，范围是0到1，默认值为0.0。
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }

    //二、子着色器
    // 定义子着色器（SubShader），包含材质的具体渲染代码。
    SubShader
    {
        // 设置渲染标签，标记为不透明材质（Opaque）。
        Tags { "RenderType"="Opaque" }
        // 定义细节级别（Level of Detail，LOD），值为200。
        LOD 200
        // 开始CG代码块，定义基于Surface Shader的着色代码。
        CGPROGRAM
        // 使用标准物理光照模型（Standard lighting model），并启用所有光源的阴影。
        #pragma surface surf Standard fullforwardshadows
        // 设置Shader的目标为3.0（Shader Model 3.0），以获得更好的光照效果。
        #pragma target 3.0
        // 定义2D纹理采样器变量，用于采样_MainTex纹理。
        sampler2D _MainTex;
        // 定义输入结构体（Input），用于传递顶点的UV坐标等数据[Z：负责把模型表面的关键信息（比如纹理坐标、视角方向等）传递给着色器的核心计算部分（surf 函数）]
        struct Input
        {
            float2 uv_MainTex; // 接收_MainTex的UV坐标
        };
        // 定义变量，用于接收材质属性。
        half _Glossiness; // 光滑度
        half _Metallic;   // 金属度
        fixed4 _Color;    // 颜色
        // 添加实例化支持的缓冲区，用于GPU实例化技术。
        UNITY_INSTANCING_BUFFER_START(Props)
            // 可以在此处添加更多的每实例属性。
        UNITY_INSTANCING_BUFFER_END(Props)

        //三、表面函数
        // 定义Surface函数，负责实现表面着色逻辑。
        void surf (Input IN, inout SurfaceOutputStandard o)//Z：函数定义
        {
            // 从_MainTex纹理采样颜色，并乘以用户定义的颜色（_Color）。
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;//Z：纹理采样            
            // 设置材质的Albedo颜色（反射漫射颜色）。
            o.Albedo = c.rgb; //Z： 设置基础颜色（就是漫反射颜色） ，这里是前面计算好的  过滤好的纹理颜色         
            // 使用滑块变量设置材质的金属度（Metallic）和光滑度（Smoothness）。
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;            
            // 设置材质的透明度（Alpha值）。
            o.Alpha = c.a;
        }
        ENDCG // 结束CG代码块
    }
    // 定义备用Shader，当目标设备不支持当前Shader时使用。
    FallBack "Diffuse"
}