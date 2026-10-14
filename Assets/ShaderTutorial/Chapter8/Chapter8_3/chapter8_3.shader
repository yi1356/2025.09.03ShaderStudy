//作用：模型溶解效果，消失边缘会有发光过渡效果，常用于道具销毁等

//思路：

Shader "Chapter8/chapter8_3"
{
    Properties
    {
        // 纹理部分
        [Header(Textures)] [Space(10)] // 标题和空白
        [NoScaleOffset] _Albedo ("Albedo", 2D) = "white" {} // 基础颜色纹理，默认白色，无缩放偏移

        // 切割部分
        [Header(Cutting)] [Space(10)] // 标题和空白
        [KeywordEnum(X, Y, Z)] _Direction ("Cutting Direction", Float) = 1 // 切割方向枚举（X、Y、Z），默认Y轴
        [Toggle] _Invert ("Invert Direction", Float) = 0 // 是否反转切割方向，默认关闭
    }
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" } // 渲染类型为透明剪切，队列为Alpha测试
        Cull Off // 关闭背面剔除，渲染双面

        CGPROGRAM
        #pragma surface surf StandardSpecular addshadow fullforwardshadows // 使用StandardSpecular表面着色器，添加阴影和全向阴影
        #pragma target 3.0 // 目标着色器模型3.0

        #pragma multi_compile _DIRECTION_X _DIRECTION_Y _DIRECTION_Z // 多编译选项，支持X、Y、Z三个方向的切割
        
        sampler2D _Albedo; // 基础颜色纹理

        float3 _Position; // 切割位置
        fixed _Invert; // 是否反转切割方向

        struct Input
        {
            float2 uv_Albedo; // 基础颜色纹理的UV坐标
            float3 worldPos; // 世界空间中的顶点位置
            fixed face : VFACE; // 判断当前渲染的是正面还是背面
        };

        void surf (Input i, inout SurfaceOutputStandardSpecular o)
        {
            // 获取基础颜色
            fixed4 col = tex2D(_Albedo, i.uv_Albedo);
            // 如果是正面，使用纹理颜色；如果是背面，使用黑色
            o.Albedo =  i.face > 0 ? col.rgb : fixed3(0,0,0);

            // 判断切割方向
            #if _DIRECTION_X
                // 如果选择X轴方向，根据世界坐标的X值与切割位置比较
                col.a = step(_Position.x, i.worldPos.x);
            #elif _DIRECTION_Y
                // 如果选择Y轴方向，根据世界坐标的Y值与切割位置比较
                col.a = step(_Position.y, i.worldPos.y);
            #else 
                // 如果选择Z轴方向，根据世界坐标的Z值与切割位置比较
                col.a = step(_Position.z, i.worldPos.z);
            #endif

            // 判断是否反转切割方向
            col.a = _Invert? 1 - col.a : col.a;

            // 根据透明度进行剪切，小于0.001的部分将被剔除
            clip(col.a - 0.001);
        }
        ENDCG
    }
}