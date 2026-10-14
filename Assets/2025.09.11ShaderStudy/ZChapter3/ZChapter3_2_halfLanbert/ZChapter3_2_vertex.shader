//半兰伯特光照模型，逐顶点
//公式diffus=光线颜色*材质颜色*max(0,（n*l）*0.5+0.5)
//思路：其实就是  在兰伯特基础上，更亮一些，对夹角cos值*0.5+0.5处理

Shader "ZChapter3/ZChapter3_2_vertex"
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
                float3 normal : NORMAL;//normal:表面法线
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                //color：计算得到的漫反射光照颜色
                fixed3 color : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //计算世界空间的法线，将模型空间的法线转换为世界空间(法线)
                fixed3 worldNormal =normalize(UnityObjectToWorldNormal(v.normal));
                //计算世界空间的光照方向，根据光源的方向并标准化（入射光方向）
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                //计算漫反射光照强度（Dot  product）（Z：也就是漫反射颜色）: 计算法线与光源方向的点积并应用光源颜色
                fixed3 diffus= _LightColor0.rgb * saturate(dot(worldNormal,worldLight)*0.5+0.5); //Z：根据公式检查，发现还少材质颜色（这个写在片元着色器中）
                //将计算的漫反射颜色传递给输出
                o.color=diffus;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col.rgb=col.rgb*i.color;
                return col;
            }
            ENDCG
        }
    }
}
