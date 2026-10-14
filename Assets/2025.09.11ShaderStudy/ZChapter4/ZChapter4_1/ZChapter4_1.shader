//半透明效果，且能看到模型背面
Shader "ZChapter4/ZChapter4_1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor("MainColor",Color)=(1,1,1,1)
    }
    SubShader
    {
        // 设置渲染类型是不透明 ，并指定光照模式为ForwardBase（Z：感觉这里写错了应该是半透明类型）
        Tags {
             "Queue"="Transparent"//Z：设置渲染队列为透明物体，透明物体通常会在不透明物体之后渲染
             "RenderType"="Transparent"  //Z：帮助 Unity 识别这个 Shader 属于透明类型，用于特定的渲染处理
             "LightMode"="ForwardBase"

            }
        LOD 100
        //Z：我们需要两个Pass一个渲染背面 一个 渲染正面，两个代码差不多，但还是有点区别的（顺序好像还不能颠倒？？？）
        //Z：用两个应该只是为了更清楚表示， Cull不写的话默认剔除背面

        

        //Z：渲染背面的Pass
        Pass
        {
            Cull Front//Z：剔除正面
            ZWrite Off //Z：关闭深度写入
            Blend SrcAlpha OneMinusSrcAlpha //Z：传统透明度
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog 

            #include "UnityCG.cginc"

             //包含Unity 的光照模型
            #include "Lighting.cginc"

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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                 //worldNormal：转换到世界空间中的法线（Z：因为逐像素的方式，需要在片元着色器中计算漫反射光，所以需要用到法线，需要在这里接收下）
                float3 worldNormal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _MainColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                 //Z：即便是逐像素，法向量的计算仍要在顶点着色器中得到****************
                o.worldNormal = UnityObjectToWorldNormal(v.normal);//Z：接收世界空间下法线
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                  // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                 // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
               
                fixed3 worldNormal =normalize(i.worldNormal);
                //Z：逐顶点 与 逐像素 最大的区别在下面，worldLight的计算与漫反射光的计算要在片元着色器中进行
                 //计算世界空间的光照方向，根据光源的方向并标准化（入射光方向）
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                //计算漫反光照强度：点积计算法线与光源方向的夹角
                fixed3 diffus=_LightColor0.rgb * saturate(dot(worldLight,worldNormal)*0.5+0.5);

               //将纹理颜色与漫反射光相乘，得到最终颜色
                col.rgb *= diffus;
                col.a*=_MainColor.a;
                return col;
            }
            ENDCG
        }

        
        //Z：渲染正面
        Pass  
        {
            Cull Back//Z：剔除背面
            ZWrite Off //Z：关闭深度写入
            Blend SrcAlpha OneMinusSrcAlpha //Z：传统透明度
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog 

            #include "UnityCG.cginc"

             //包含Unity 的光照模型
            #include "Lighting.cginc"

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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                 //worldNormal：转换到世界空间中的法线（Z：因为逐像素的方式，需要在片元着色器中计算漫反射光，所以需要用到法线，需要在这里接收下）
                float3 worldNormal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _MainColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                 //Z：即便是逐像素，法向量的计算仍要在顶点着色器中得到****************
                o.worldNormal = UnityObjectToWorldNormal(v.normal);//Z：接收世界空间下法线
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                  // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                 // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
               
                fixed3 worldNormal =normalize(i.worldNormal);
                //Z：逐顶点 与 逐像素 最大的区别在下面，worldLight的计算与漫反射光的计算要在片元着色器中进行
                 //计算世界空间的光照方向，根据光源的方向并标准化（入射光方向）
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                //计算漫反光照强度：点积计算法线与光源方向的夹角
                fixed3 diffus=_LightColor0.rgb * saturate(dot(worldLight,worldNormal)*0.5+0.5);

               //将纹理颜色与漫反射光相乘，得到最终颜色
                col.rgb *= diffus;
                col.a*=_MainColor.a;
                return col;
            }
            ENDCG
        }
    }
}
