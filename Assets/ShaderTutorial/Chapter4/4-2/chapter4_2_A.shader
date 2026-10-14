Shader "Chapter4/chapter4_2_A"
{
    SubShader
    {
        // 设置渲染队列，优先于普通几何体进行渲染
        Tags {"Queue" = "Geometry-1"}

        Pass
        {
            // 设置模板测试的状态
            Stencil
            {
                Ref 1                 // 模板参考值为1
                Comp Always           // 始终通过模板测试
                Pass Replace          // 如果通过模板测试，则将模板缓冲值替换为参考值
            }

            // 禁止绘制任何色彩到渲染目标
            ColorMask 0              // 禁用颜色通道的写入
            ZWrite Off               // 禁用深度写入

            // 开始编写CG代码
            CGPROGRAM
            #pragma vertex vert       // 顶点着色器
            #pragma fragment frag     // 片段着色器

            // 顶点着色器
            float4 vert (in float4 vertex : POSITION) : SV_POSITION
            {
                float4 pos = UnityObjectToClipPos(vertex); // 将模型空间的顶点位置转换到裁剪空间
                return pos;                                // 返回裁剪空间的顶点位置
            }

            // 片段着色器
            void frag (out fixed4 color : SV_Target)
            {
                color = fixed4(0, 0, 0, 0); // 输出透明的颜色（完全不可见）
            }
            ENDCG
        }
    }
}
