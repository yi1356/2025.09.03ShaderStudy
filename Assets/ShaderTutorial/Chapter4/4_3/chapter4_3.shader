Shader "Chapter4/chapter4_3"
{
    Properties
    {
        //这里的法线贴图用于计算折射产生的扭曲
        _BumpMap("Normal Map",2D)="bump"{}
        _Distortion("Distortion",range(0,100))=10
    }
    SubShader
    {
        //保证该物体渲染时，其他不透明物体都已经渲染完成
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        //抓取当前屏幕的渲染图像并存入指定纹理
        GrabPass{"_RefractionTex"}

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
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD4;
            };
            
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _Distortion;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _BumpMap);
                //得到屏幕采样坐标
                o.scrPos = ComputeGrabScreenPos(o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 tanNormal = UnpackNormal(tex2D(_BumpMap, i.uv.xy));
                //对采集的屏幕图像进行关于法线方向上的扭曲和偏移，也就是模拟折射的效果
                //_RefractionTex_TexelSize表示纹理的 纹素大小（Texel Size），即纹理中每个像素在 UV 坐标中的大小
                float2 offset = tanNormal.xy*_Distortion*_RefractionTex_TexelSize.xy;
                i.scrPos.xy += offset;
                fixed3 color = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).xyz;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
    fallback "Diffuse"
}