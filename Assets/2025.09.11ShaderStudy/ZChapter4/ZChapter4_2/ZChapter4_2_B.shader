Shader "ZChapter4/ZChapter4_2_B"
{

     Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
         Tags { "Queue" = "Geometry" }//Z： Geometry是普通不透明物体*****************************************************
        LOD 100

        Pass
        {

            // 设置光照模式为前向渲染的 基础通道
            Tags {"LightMode" = "ForwardBase"}

            //Z：设置模板测试的状态，让深度缓冲值不等于1的继续保持（Z：为了筛选出球形部分，也就是深度缓冲值为1的部分）*********************************
            Stencil
            {
                Ref 1
                Comp NotEqual     // 如果模板缓冲值  不等于 参考值， 则通过测试（Z：实现的用 B“只在标记的区域外显示内容）*******************************
                Pass Keep         // 如果通过测试，保持模板缓冲区的值不变（Z：就是为了让球区域的像素，模板缓冲值为1）

            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
             //包含Unity 的光照模型
             #include "UnityLightingCommon.cginc" // 引入Unity光照相关的工具函数（Z：相比Lighting.cginc要精简一些）

            struct appdata
            {
                 float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                //normal: 物体空间中的法线
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                //worldNormal：转换到世界空间中的法线（Z：因为逐像素的方式，需要在片元着色器中计算漫反射光，所以需要用到法线，需要在这里接收下）
                float3 worldNormal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //Z：即便是逐像素，法向量的计算仍要在顶点着色器中得到****************
                o.worldNormal = UnityObjectToWorldNormal(v.normal);//Z：接收世界空间下法线
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
               
                fixed3 worldNormal =normalize(i.worldNormal);
                //Z：逐顶点 与 逐像素 最大的区别在下面，worldLight的计算与漫反射光的计算要在片元着色器中进行
                 //计算世界空间的光照方向，根据光源的方向并标准化（入射光方向）
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                //计算漫反光照强度：点积计算法线与光源方向的夹角
                fixed3 diffus=_LightColor0.rgb * saturate(dot(worldLight,worldNormal)*0.5+0.5);

               //将纹理颜色与漫反射光相乘，得到最终颜色
                col.rgb *= diffus;
                return col;
            }
            ENDCG
        }
    }
}
