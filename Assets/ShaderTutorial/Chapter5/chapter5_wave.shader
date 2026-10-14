Shader "Chapter5/chapter5_wave"
{
    Properties
    {
        _Color ("Color", Color) = (0,0,1,1) // 水体基础颜色
        _WaveHeight ("WaveHeight", float) = 1 // 波浪高度
        _WaveSpeed ("WaveSpeed", float) = 1 // 波浪速度
        _WaveGap ("WaveGap", float) = 1 // 波浪间隔
        _FoamTex ("FoamTex", 2D) = "white" {} // 泡沫纹理
        _NormalTex ("NormalTex", 2D) = "white" {} // 法线贴图
        _NormalScale ("NormalScale", float) = 1 // 法线强度
        _NormalSpeed ("NormalSpeed", float) = 1 // 法线贴图移动速度
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" // 渲染类型为透明
            "Queue" = "Transparent" // 渲染队列为透明
            "IgnoreProjector" = "True" // 忽略投影器
        }
        LOD 200 // 细节级别
        CGPROGRAM
        // 使用 Standard 光照模型，启用透明混合，保留透明度，启用全向阴影
        #pragma surface surf Standard alpha:fade keepalpha fullforwardshadows vertex:vertexDataFunc
        #pragma target 3.0 // 目标着色器模型为 3.0

        sampler2D _MainTex; // 主纹理（未使用）

        struct Input
        {
            float2 uv_FoamTex; // 泡沫纹理的 UV 坐标
            float4 screenPos; // 屏幕空间坐标
        };
        
        fixed4 _Color; // 水体基础颜色
        float _WaveHeight; // 波浪高度
        float _WaveSpeed; // 波浪速度
        float _WaveGap; // 波浪间隔
        sampler2D _NormalTex; // 法线贴图
        float _NormalScale; // 法线强度
        float _NormalSpeed; // 法线贴图移动速度
        

        // 顶点着色器函数
        void vertexDataFunc(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o); // 初始化输出结构
            // 计算波浪高度，使用正弦函数模拟波浪效果
            fixed height = sin(_Time.y * _WaveSpeed + v.vertex.z * _WaveGap + v.vertex.x) * _WaveHeight;
            // 根据法线方向调整顶点位置，形成波浪效果
            v.vertex.xyz += v.normal * height;
        }

        // 表面着色器函数
        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            // 法线贴图
            // 根据时间偏移法线贴图的 UV 坐标
            float2 speed = _Time.x * float2(_WaveSpeed, _WaveSpeed) * _NormalSpeed;
            // 采样法线贴图，并解包法线
            fixed3 bump1 = UnpackNormal(tex2D(_NormalTex, IN.uv_FoamTex.xy + speed)).rgb;
            fixed3 bump2 = UnpackNormal(tex2D(_NormalTex, IN.uv_FoamTex.xy - speed)).rgb;
            // 合并两个法线贴图的结果
            fixed3 bump = normalize(bump1 + bump2);
            // 调整法线强度
            bump.xy *= _NormalScale;
            bump = normalize(bump);
            // 将法线赋值给输出结构
            o.Normal = bump;
            
            // 水体颜色
            o.Albedo = _Color;
            // 设置透明度
            o.Alpha = _Color.a;
        }
        ENDCG
    }
    FallBack "Diffuse" // 回退到 Diffuse Shader
}