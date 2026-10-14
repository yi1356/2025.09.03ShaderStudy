//实现一种离屏幕画面中心越近，越亮，越远(也就是离屏幕边缘越近)越黑的效果
//思路：计算中模型中心的裁剪空间坐标，并归一化x,y和求绝对值；最后得出col[范围0~1]越接近1，越接近画面中心


Shader "ZChapter2/ZChapter2_3"
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
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPosition = mul(unity_ObjectToWorld,v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //Z：计算（0，0，0）位置（模型中心）的顶点，转换到裁剪空间（剪裁空间是 GPU 用来判断 “这个点是否能显示在屏幕上” 的坐标）
                float4 pos = UnityObjectToClipPos(float4(0,0,0,1));
                //计算水平和垂直方向上的平滑过渡效果
                //使用smoothstep  生成平滑的渐变效果，基于绝对值计算
                //Z：将裁剪空间坐标转为归一化设备坐标
                //Z:float ndcX = pos.x / pos.w;  // 水平方向归一化坐标
                //Z：float ndcY = pos.y / pos.w;  // 垂直方向归一化坐标[这样得到的最终范围是  -1~1]
                float col = smoothstep(1,0,abs(pos.x/pos.w)) * smoothstep(1,0,abs(pos.y/pos.w));//Z：这样的出来的效果就是模型越接近画面中心，co1越接近1   [co1范围0~1]



                return col;
            }
            ENDCG
        }
    }
}
