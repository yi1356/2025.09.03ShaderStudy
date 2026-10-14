//作用：用于模拟波浪水面效果（性能和效果都很好，可以商用）

//思路：顶点函数中利用Sin函数结合时间和顶点位置，偏移顶点，实现波浪效果;表面函数中根据时间偏移法线贴图，取样颜色并归一化作为新法线,实现表面涟漪
Shader "ZChapter5/ZChapter5_5_Wave"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _WaveHeight("WaveHeight",float) =1 //波浪高度
        _WaveSpeed("WaveSpeed",float) = 1//波浪速度
        _WaveGap("WaveGap",float)=1 //波浪间隔(Z：控制波浪之间的距离（似乎是值越大，波浪越密集）)

        _FoamTex ("FoamTex", 2D) = "white" {} //泡沫纹理
        _NormalTex("NormalTex",2D) = "white" {} //法线贴图
        _NormalScale("NormalScale", float) = 1 //法线强度（Z：控制法线贴图的效果强度（值越大，水面的细小涟漪越明显））
        _NormalSpeed("NormalSpeed", float) = 1 //法线贴图移动速度

    }
    SubShader
    {
        Tags 
        {
             "RenderType"="Transparent"
             "Queue" = "Transparent"
             "IgnoreProjector" = "True"  //忽略投影器
             
        }
        LOD 200

        CGPROGRAM
        // 使用 Standard 光照模型，启用透明混合，保留透明度，启用全向阴影
        #pragma surface surf Standard alpha:fade keepalpha fullforwardshadows  vertex:vertexDataFunc

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        fixed4 _Color;//水体基础颜色
        float _WaveHeight;//波浪高度
        float _WaveSpeed; //波浪速度
        float _WaveGap; //波浪间隔

        sampler2D _NormalTex; // 法线贴图
        float _NormalScale; // 法线强度
        float _NormalSpeed; // 法线贴图移动速度

        struct Input
        {
             float2 uv_FoamTex; //Z：存储_FoamTex纹理的 UV 坐标
            
        };

        //顶点着色器函数（Z：控制水面的形状变化）???
        void vertexDataFunc(inout appdata_full v, out Input o)//Z：out Input o：输出参数，传递给表面着色器的输入数据（这里主要是 UV 坐标）。
        {
            UNITY_INITIALIZE_OUTPUT(Input,o); //初始化输出结构（Z：初始化Input结构体o，避免内存垃圾（Unity 推荐的安全操作））
            //计算波浪高度,   使用正弦函数模拟波浪效果??????（Z：计算每个顶点的高度偏移（核心波浪计算））****************************************************
            fixed height = sin(_Time.y * _WaveSpeed + v.vertex.z * _WaveGap + v.vertex.x)* _WaveHeight;//Z：v.vertex.z是前后，v.vertex.y才是上下
            // 根据法线方向调整顶点位置，形成波浪效果??????
            v.vertex.xyz += v.normal * height;



        }

        //Z：表面函数：控制水面的外观细节（让法线贴图随时间移动，模拟水面的微小波动）
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            //法线贴图
            //根据时间偏移法线贴图的 uv坐标？？？？？？？？？？？？？？？？？？？？*****************************************************************
            float speed = _Time.x * float2(_WaveSpeed, _WaveSpeed) * _NormalSpeed;//Z： “创建了一个 X、Y 分量值相等的二维向量”，本质还是二维数据，只是用简写方式；    _Time.x是t/20
            //采样法线贴图，并解包法线??????????????????????????????
            fixed3 bump1 = UnpackNormal(tex2D(_NormalTex, IN.uv_FoamTex.xy + speed)).rgb;//Z：计算法线贴图的移动速度，并采样，将采样到的颜色转换为法线方向********************************************************************
            fixed3 bump2 = UnpackNormal(tex2D(_NormalTex, IN.uv_FoamTex.xy - speed)).rgb;
            //Z：作用：采样法线贴图（第二个方向，与第一个方向相反），让涟漪更复杂自然；合并两个方向的法线，并归一化（确保法线方向向量长度为 1，避免光照计算错误）
            fixed3 bump = normalize(bump1 + bump2);//Z：结合两个方向的法线效果，让水面看起来更自然
            // 调整法线强度(Z：放大 X、Y 方向的法线分量)（法线是Z轴垂直于平面）
            bump.xy *= _NormalScale;
            bump = normalize(bump);
            //将法线赋值给输出结构
            o.Normal = bump;

            //水体颜色
            o.Albedo = _Color;
            //设置透明度
            o.Alpha = _Color.a;
        }
        ENDCG
    }


    FallBack "Diffuse"
}
