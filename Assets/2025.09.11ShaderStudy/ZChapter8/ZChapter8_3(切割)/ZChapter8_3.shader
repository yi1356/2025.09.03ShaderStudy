//作用：可以实现从 X/Y/Z 任意方向切一刀，从而只保留一部分模型

//思路：表面着色器，表面函数中根据选择的轴方向，用切割位置与顶点世界坐标比较（step函数），决定像素保留(1)/剔除(0),最终剔除标记为0的像素

Shader "ZChapter8/ZChapter8_3"
{
    Properties
    {
        // 纹理部分
        _Position("Position" , Vector) = (0,0,0)
        [Header(Textures)] [Space(10)] // 标题和空白
        [NoScaleOffset] _Albedo ("Albedo", 2D) = "white" {} // 基础颜色纹理，默认白色，无缩放偏移

        // 切割部分
        [Header(Cutting)] [Space(10)] // 标题和空白
        [KeywordEnum(X, Y, Z)] _Direction ("Cutting Direction", Float) = 1 // 切割方向枚举（X、Y、Z），默认Y轴
        [Toggle] _Invert ("Invert Direction", Float) = 0 // 是否反转切割方向，默认关闭
    }
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" } // 渲染类型为透明剪切（Z：材质要么全透，要么不透，没有半透处），队列为Alpha测试(Z：处理完不透明物体后进行alpha测试)
        Cull Off // 关闭背面剔除，渲染双面

        CGPROGRAM
        #pragma surface surf StandardSpecular addshadow fullforwardshadows // 使用StandardSpecular表面着色器，添加阴影和全向阴影
        #pragma target 3.0 // 目标着色器模型3.0

        #pragma multi_compile _DIRECTION_X _DIRECTION_Y _DIRECTION_Z // 多编译选项，支持X、Y、Z三个方向的切割 （Z：#pragma multi_compile：这是 Unity Shader 的编译指令，用于告诉编译器 “生成多个 Shader 变体”。每个变体对应一组不同的宏定义（关键字））
        
        sampler2D _Albedo; // 基础颜色纹理

        float3 _Position; // 切割位置(Z：这个变量不在 Properties 中，通常由 C# 脚本动态传入（如通过material.SetVector("_Position", position)）？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？？)
        fixed _Invert; // 是否反转切割方向

        struct Input
        {
            float2 uv_Albedo; // 基础颜色纹理的UV坐标
            float3 worldPos; // 世界空间中的顶点位置（Z：用于判断顶点在世界空间中的位置，决定是否被切割）
            fixed face : VFACE; // 判断当前渲染的是正面还是背面************************************************************************************************
        };

        void surf (Input i, inout SurfaceOutputStandardSpecular o)
        {
            // 获取基础颜色
            fixed4 col = tex2D(_Albedo, i.uv_Albedo);
            // 如果是正面，使用纹理颜色；如果是背面，使用黑色
            o.Albedo =  i.face > 0 ? col.rgb : fixed3(0,0,0);

            // 判断切割方向
            #if _DIRECTION_X
                // 如果选择X轴方向，根据世界坐标的X值与切割位置比较（Z：step函数作用：若_Position.x < i.worldPos.x则返回1）*************************************
                //Z：step(_Position.x, i.worldPos.x)：内置函数，若i.worldPos.x（顶点 X 坐标）> _Position.x（切割位置 X），返回 1，否则返回 0
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
            //Z：clip(X)：内置函数，若X < 0则丢弃当前像素（不渲染）；在这里也就是指col.a为0时像素被丢弃。*********************************************************
            clip(col.a - 0.001);
        }
        ENDCG
    }
}
