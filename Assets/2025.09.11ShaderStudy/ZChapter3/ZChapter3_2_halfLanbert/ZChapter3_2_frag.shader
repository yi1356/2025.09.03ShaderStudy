//兰伯特光照模型，逐像素
//公式diffus=光线颜色*材质颜色*max(0,（n*l）*0.5+0.5)
//思路：其实就是  在兰伯特基础上，更亮一些，对夹角cos值*0.5+0.5处理

//区别：逐顶点与逐像素最大的区别 worldLight的计算与漫反射光的计算要在片元着色器中进行
Shader "ZChapter3/ZChapter3_2_frag"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
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
