//Z：作用：让模型以一种不规则的形式溶解消失

//Z：思路：使用表面着色器，属性中设置好噪声纹理+高光纹理；表面函数中设置遮罩值（Mask）=采样噪声图纹理红色通道值 - 溶解程度值，小于0.5的用Cip函数剔除像素;溶解边缘的高光原理大概是筛选出Mask稍微大于0.5的像素（边缘处），采样高光纹理；

Shader "ZChapter8/ZChapter8_1"
{
    Properties
    {
        // 定义属性
        [NoScaleOffset]_Albedo("Albedo", 2D) = "white" {} // 基础颜色纹理，默认白色
        _Noise("Dissolve Noise", 2D) = "white" {} // 溶解噪声纹理，默认白色（Z：这是一张黑白随机图案的纹理（类似电视雪花），用来控制溶解的 “形状”）
        _Dissolve("Dissolve", Range(0, 1)) = 0 // 溶解程度，范围0到1，默认0
        [NoScaleOffset]_Gradient("Edge Gradient", 2D) = "black" {} // 边缘渐变纹理，默认黑色
        _Range("Edge Range", Range(2, 100)) = 6 // 边缘范围，范围2到100，默认6（Z：值越大范围越小）
        _Brightness("Brightness", Range(0, 10)) = 1 // 亮度，范围0到10，默认1
    }
    SubShader
    {
        Tags
        { 
            //Z："RenderType"="TransparentCutout"：渲染类型为 “透明剪切”，表示模型有部分像素会被完全剔除（不是半透明，而是直接消失）
            //Z：确保 Unity 先渲染不透明物体，再渲染这类带剪切效果的物体
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
            // 溶解遮罩（Z：取样噪声纹理红色值，结合_Dissolve，确定范围；最后用Clip剔除）*******************************************************************
            fixed noise = tex2D(_Noise, IN.uv_Noise).r; // 从噪声纹理中获取红色通道值（Z：噪声纹理采样,红色通道值）[Z：tex2D是一个非常核心的纹理采样函数，作用是 “从 2D 纹理中读取指定位置的颜色值”，第二个参数：纹理坐标（float2 类型）范围通常是[0, 1]]
            fixed dissolve = _Dissolve * 2 - 1; // 将溶解程度从0-1映射到-1到1
            fixed mask = saturate(noise - dissolve); // 计算遮罩值，限制在0到1之间**********
            clip(mask - 0.5); // 根据遮罩值进行剪切，小于0.5的部分将被剔除******

            // 燃烧效果
            // fixed texcoord = saturate(mask * _Range - 0.5 * _Range); // 计算纹理坐标，用于边缘渐变（Z：作用：计算溶解边缘的 “纹理坐标”（0 到 1），用来采样_Gradient纹理（mask接近 0.5 的区域是边缘，对应texcoord的中间值））
            // o.Emission = tex2D(_Gradient, fixed2(texcoord, 0.5)) * _Brightness; // 根据渐变纹理和亮度计算自发光

            //Z：改良后的边缘发光效果*************************************************************
            fixed texcoord = saturate( _Range * (mask - 0.5) );//Z：这里比较有意思，当_Range越大时所有还在显示的顶点的texcoord值都会增大基本都是1了;但是注意在mask - 0.5的顶点处，这样计算出的texcoord值可能<0.3,能符合下面的要求
            // 只让texcoord在[0, 0.3]范围内发光（超出部分设为黑色）  [Z：这里通过动态计算的texcoord（范围[0,1]）来取样渐变纹理，实现边缘颜色的过渡效果]
            o.Emission = tex2D(_Gradient, fixed2(texcoord, 0.5)) * _Brightness * step(texcoord, 0.3);//Z：这里会筛选texcoord值 <0.3 的采样才有效，会发光，最终实现边缘发光效果


            fixed4 c = tex2D (_Albedo, IN.uv_Albedo); // 从Albedo纹理中获取颜色
            o.Albedo = c.rgb; // 设置表面颜色
        }
        ENDCG
    }
}
