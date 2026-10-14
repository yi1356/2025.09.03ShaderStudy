//冯光照模型：包括环境光、漫反射光、镜面反射光，是这三部分的加权和
//公式：C=C_ambient + C_diffuse + C_Specular
//C_ambient(环境光)：=UNITY_LIGHTMODEL_AMBIENT.xyz[常量]
//C_diffuse(漫反射光)：= (C_light * M_diffuse)max(0,n * I)[]???
//C_Specular(镜面反射光)：=C_specular = (C_light * M_specular)max(0,n * h)^ M_gloss[半程向量 与 法线的点积，经过光泽度指数计算的值]**********************************************


//思路：其实就是环境光+漫反射光+镜面反射光；环境光可以理解为是常量；  ******************************************** 
//漫反射光是材质颜色*入射光颜色*[入射光方向与顶点法向量的cos值]；  
//镜面反射光是反射光颜色*[反射方向与视线方向的点积，经过光泽度指数计算的值]




Shader "ZChapter3/ZChapter3_3_Blinn_Phong"
{
    Properties
    {
        //漫反射颜色
        _Diffuse("Diffuse", Color)=(1,1,1,1)

        //镜面反射
        _Specular("Specular", Color)=(1,1,1,1)

        //光泽度（控制镜面高光的锐利程度）
        _Gloss("Gloss",Range(8.0,256))=20
    }
    SubShader
    {
        Tags { 
            //设置 光照模式为ForwardBase, 适用于向前渲染
            //Z：是 Shader 对自身的 “功能声明”，告诉引擎：“我负责计算前向渲染中的基础光源组（最亮平行光 + 逐顶点光源 + SH 光源）的光照效果”。它和灯光设置是配合关系 —— 灯光设置决定 “选哪些光源”，ForwardBase决定 “如何计算这些被选中的基础光源”，最终共同实现前向渲染的分层光照逻辑
            //Z：在前向渲染中使用；应用环境光、主方向光、顶点/SH 光源和光照贴图
            "LightMode" = "ForwardBase"

        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
           

            #include "UnityCG.cginc"
            //引入Unity的光照计算库
             #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;// 顶点法线
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0; //世界空间中的法线
                float3 worldPos : TEXCOORD1;    //世界空间中的位置
            };

           //声明传递给着色器的属性
           fixed4 _Diffuse; //漫反射颜色
           fixed4 _Specular; //镜面反射颜色
           float _Gloss;    //光泽度



            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //将物体空间中的法线 转换为 世界空间法线
                o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
                //获取物体在世界空间中的位置
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //归一化世界空间中的法线
                fixed3 worldNormal = normalize(i.worldNormal);
                //归一化光源方向（Z：平行光的方向，的反向量）
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                //计算观察方向（从世界空间中的物体位置到摄像机位置）
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                //计算半程向量************************************************************
                fixed3 halfDir = normalize(worldLightDir + viewDir);

                //环境光（可以在Lighting.cginc中找到计算）
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                 // 漫反射光照（根据法线和光源方向的点积计算）
                 //(Z：_LightColor0是光的颜色 和 强度信息)
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                // 镜面反射光照（，经过光泽度指数计算）
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir, worldNormal)), _Gloss);


                //返回最终颜色，包含环境光、漫反射光、镜面反射光
                return fixed4(ambient + diffuse + specular,1.0);
            }
            ENDCG
        }
    }
}
