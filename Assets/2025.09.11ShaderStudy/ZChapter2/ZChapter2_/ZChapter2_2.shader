//让模型以中心为界，上黑下白（中间有一段过渡）

Shader "ZChapter2/ZChapter2_2"
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPosition = mul(unity_ObjectToWorld,v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //计算**模型**水平线的世界坐标位置（这里的水平线是Y=0的位置）
                half4 horLine = mul(unity_ObjectToWorld,float4(0,0,0,1));
                //计算当前片段与水平线(Y=0)之间的偏移量
                half yOffset = horLine.y - i.worldPosition.y;
                //使用smoothstep函数生成平滑的颜色过渡，yoffset决定过渡的范围
                half4 col = smoothstep(0,0.3,yOffset);//Z：含义如果yOffset<0 则返回0；yOffset>0.3返回1；yOffset在0~0.3之间按比例计算，如为0.15时，返回0.5；

                
                return col;
            }
            ENDCG
        }
    }
}
