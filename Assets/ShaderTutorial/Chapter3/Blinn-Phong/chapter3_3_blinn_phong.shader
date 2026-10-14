Shader "Chapter3/chapter3_3_blinn_phong"
{
    Properties
    {
        // 漫反射颜色
        _Diffuse("Diffuse", Color) = (1,1,1,1)
        
        // 镜面反射颜色
        _Specular("Specular", Color) = (1, 1, 1, 1)
        
        // 光泽度（控制镜面高光的锐利程度）
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        Pass
        {
            Tags
            {
                // 设置光照模式为ForwardBase，适用于前向渲染
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            // 声明顶点着色器和片段着色器的函数
            #pragma vertex vert
            #pragma fragment frag
            
            // 引入Unity的光照计算库
            #include "Lighting.cginc"

            // 声明传递给着色器的属性
            fixed4 _Diffuse;  // 漫反射颜色
            fixed4 _Specular; // 镜面反射颜色
            float _Gloss;     // 光泽度

            // 顶点数据结构
            struct a2v
            {
                float4 vertex : POSITION;  // 顶点位置
                float3 normal : NORMAL;    // 顶点法线
            };

            // 传递给片段着色器的数据结构
            struct v2f
            {
                float4 pos : SV_POSITION;  // 顶点位置，最终转换为裁剪空间坐标
                float3 worldNormal : TEXCOORD0; // 世界空间中的法线
                float3 worldPos : TEXCOORD1;    // 世界空间中的位置
            };

            // 顶点着色器
            v2f vert(a2v v)
            {
                v2f o;
                // 将物体空间的顶点坐标转换为裁剪空间坐标
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 将物体空间中的法线转换为世界空间法线
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                
                // 获取物体在世界空间中的位置
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            // 片段着色器
            fixed4 frag(v2f i) : SV_Target
            {
                // 归一化世界空间中的法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 归一化光源方向
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                // 计算观察方向（从世界空间中的物体位置到摄像机位置）
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                // 计算半程向量（Blinn-Phong模型的关键）
                fixed3 halfDir = normalize(worldLightDir + viewDir);

                // 环境光（从Lighting.cginc中获取）
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 漫反射光照（根据法线和光源方向的点积计算）
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                // 镜面反射光照（Blinn-Phong模型，使用半程向量和法线的点积，经过光泽度指数计算）
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);

                // 返回最终的颜色，包含环境光、漫反射光和镜面反射光
                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse" // 如果无法使用此着色器，则使用内建的Diffuse着色器作为回退
}
