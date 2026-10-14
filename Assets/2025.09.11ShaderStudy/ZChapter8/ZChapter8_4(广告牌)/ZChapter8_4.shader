//Z：作用：广告牌效果”（Billboard）**—— 简单说就是让 2D 图片（比如游戏里的树木、云朵、公告牌等）始终 “面向” 摄像机

//Z：思路：在顶点着色器中计算模型朝向摄像机的向量forward[模型空间中的]，根据这个forward计算新的坐标系[朝向摄像机的][左手坐标系]，移动顶点位置；在片元着色器中采样纹理即可

Shader "ZChapter8/ZChapter8_4"
{
      Properties
    {
        [NoScaleOffset] _Tex ("Texture", 2D) = "white" {}
        [KeywordEnum(Spherical, Cylindrical)] _Type ("Type", float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "DisableBatching" = "True"
        }

        //Blend OneMinusDstColor One
        ZWrite Off//Z：透明物体需要关闭深度写入

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Z：声明枚举的关键词：根据_Type的选择，编译对应的Shader版本
            #pragma shader_feature _TYPE_SPHERICAL _TYPE_CYLINDRICAL
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
            };

            sampler2D _Tex;

            //Z：顶点函数的作用是调整顶点位置，让物体（2D 面片）始终面向摄像机，是广告牌效果的核心
            v2f vert (appdata v)
            {
                v2f o;

                // Z：计算摄像机在模型空间中的位置，并得到面片指向摄像机的方向向量（思路：通过计算得到模型空间中摄像机的位置，即模型原点到摄像机的方向向量[模型空间中的]）
                float3 forward = mul(unity_WorldToObject,
                                     float4(_WorldSpaceCameraPos, 1)).xyz;

                // 判断广告牌类型：如果是圆柱形模式，冻结Y轴（上下方向）的旋转
                #if _TYPE_CYLINDRICAL
                forward.y = 0;// Z：Y分量设为0，意味着只在XZ平面（水平方向）旋转，不上下转动
                #endif

                forward = normalize(forward);


                //Z：根据forward向量计算新的面朝向摄像机的 坐标系（左手），（注意在圆柱形旋转时摄像机在正上/下的情况）****************************************
                // 当摄像机完全在面片正上方或者正下方的时候，旋转临时的上方向量
                float3 up = abs(forward.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);

                float3 right = normalize(cross(forward, up));
                up = normalize(cross(right, forward));

                // 将顶点在新的坐标系上移动位置（Z：计算得出面片旋转后，顶点的新位置）******************************************
                float3 vertex = v.vertex.x * right + v.vertex.y * up;

                o.vertex = UnityObjectToClipPos(vertex);//Z： 将新的顶点位置从模型空间转换到裁剪空间（供GPU渲染）
                o.texcoord = v.texcoord;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // 采样纹理：根据传递的texcoord（UV坐标）从_Tex中获取颜色
                // tex2D是HLSL中的纹理采样函数，返回值为float4（RGBA）
                return tex2D(_Tex, i.texcoord);
            }
            ENDCG
        }
    }
}