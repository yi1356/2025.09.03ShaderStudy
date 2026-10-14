Shader "ZChapter8/ZChapter8_2_Test"
{
    Properties
    {
        _Color("color",Color)=(1,1,1,1)
        _width("Width",Range(1, 2))=1
        _strenth("strenth",Range(1, 2))=1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
       
        LOD 100

        Pass
        {
            ZTest Greater
            ZWrite Off
            Blend  SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            #include "UnityCG.cginc"

           fixed4 _Color;
           fixed _width;
           fixed _strenth;


            struct v2f
            {
               float4 vertex : SV_POSITION; // 必须添加：存储屏幕位置
               float3 normalDir : TEXCOORD0;
               float3 viewDir : TEXCOORD1;
            };


            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normalDir = normalize(UnityObjectToWorldDir(v.normal));
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                fixed4 col;
                col.rgb=_Color.rgb;

                fixed a=saturate(dot(i.normalDir, i.viewDir));
                fixed b=pow((1-a),_width) *_strenth;
                col.a=b;

                return col;
            }
            ENDCG
        }
    }
}
