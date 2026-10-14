Shader "Chapter8/chapter8_1"
{
    Properties
    {
        // 定义属性
        [NoScaleOffset]_Albedo("Albedo", 2D) = "white" {} // 基础颜色纹理，默认白色
        _Noise("Dissolve Noise", 2D) = "white" {} // 溶解噪声纹理，默认白色
        _Dissolve("Dissolve", Range(0, 1)) = 0 // 溶解程度，范围0到1，默认0
        [NoScaleOffset]_Gradient("Edge Gradient", 2D) = "black" {} // 边缘渐变纹理，默认黑色
        _Range("Edge Range", Range(2, 100)) = 6 // 边缘范围，范围2到100，默认6
        _Brightness("Brightness", Range(0, 10)) = 1 // 亮度，范围0到10，默认1
    }
    SubShader
    {
        Tags
        { 
            "RenderType"="TransparentCutout" "Queue" = "AlphaTest" // 渲染类型为透明剪切，队列为Alpha测试
        }

        CGPROGRAM
        #pragma surface surf StandardSpecular addshadow fullforwardshadows // 使用StandardSpecular表面着色器，并添加阴影和全向阴影

        struct Input
        {
            float2 uv_Albedo; // Albedo纹理的UV坐标
            float2 uv_Noise; // 噪声纹理的UV坐标
        };

        sampler2D _Albedo; // Albedo纹理
        sampler2D _Noise; // 噪声纹理
        fixed _Dissolve; // 溶解程度
        sampler2D _Gradient; // 边缘渐变纹理
        float _Range; // 边缘范围
        float _Brightness; // 亮度

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
            // 溶解遮罩
            fixed noise = tex2D(_Noise, IN.uv_Noise).r; // 从噪声纹理中获取红色通道值
            fixed dissolve = _Dissolve * 2 - 1; // 将溶解程度从0-1映射到-1到1
            fixed mask = saturate(noise - dissolve); // 计算遮罩值，限制在0到1之间
            clip(mask - 0.5); // 根据遮罩值进行剪切，小于0.5的部分将被剔除

            //燃烧效果
            fixed texcoord = saturate(mask * _Range - 0.5 * _Range); // 计算纹理坐标，用于边缘渐变
            o.Emission = tex2D(_Gradient, fixed2(texcoord, 0.5)) * _Brightness; // 根据渐变纹理和亮度计算自发光

            
            fixed4 c = tex2D (_Albedo, IN.uv_Albedo); // 从Albedo纹理中获取颜色
            o.Albedo = c.rgb; // 设置表面颜色
        }
        ENDCG
    }
}