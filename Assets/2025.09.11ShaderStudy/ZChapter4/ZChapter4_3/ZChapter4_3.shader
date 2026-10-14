//作用：利用GrabPass命令，实现玻璃折射的效果

//???????????????????????????????????????????
//思路：抓取当前屏幕的渲染图像并存入指定纹理 -> 结合法线贴图，计算偏移[先记录原始顶点对应的采样纹理坐标（_RefractionTex的，其实就是百分比屏幕坐标）] 
//-> 采样扭曲[原始采样坐标应用偏移后,通过透视除法（i.scrPos.xy / i.scrPos.w）校正透视变形,最终采样抓取纹理得到折射后的颜色，输出为物体表面颜色]

Shader "ZChapter4/ZChapter4_3"
{
    Properties
    {
        //这里的法线贴图用于计算折射产生的扭曲
        _BumpMap("Normal Map",2D)="bump"{}
        _Distortion("Distortion",range(0,100))=10
    }
    SubShader
    {
        //保证该物体渲染时，其它不透明物体都已经渲染完成[Z：表示自己是不透明，但是要在所有不透明物体后渲染]
        //Z："RenderType"="Opaque",默认开启 深度测试（ZTest LEqual） 和 深度写入（ZWrite On）[Z：主要和 RenderType 关联（而非 Queue）]
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100

        //抓取当前屏幕的渲染图像并存入指定纹理*****************************************************************************************
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
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f       
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD4;//Z：记录原始位置（好像就是原始顶点的在屏幕空间的百分比坐标）
            };

            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _Distortion;

            sampler2D _RefractionTex;  //Z：将捕获的内容放在这里
            float4 _RefractionTex_TexelSize;//  Z:纹理中的每个像素的大小 （用于计算偏移量）？？？？？？


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _BumpMap);//Z：这里为什么要+xy ？（不加也行）
                //得到屏幕采样坐标????????????????????????      [这里得到的似乎是屏幕空间中的坐标 ] 还是不理解？？？？？？？？？？？？？？？？？？           
                o.scrPos = ComputeGrabScreenPos(o.pos);//Z：把裁剪空间坐标转换为「抓取纹理的采样坐标（其实就是屏幕坐标以百分比的形式表示）」******************
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                //***************Z：这里其实是真正的核心代码************************
                fixed3 tanNormal = UnpackNormal(tex2D(_BumpMap,i.uv.xy));//Z： 解包法线贴图）(Z：tex2D (_BumpMap,i.uv.xy)：采样法线贴图，“采样” 就是 “按坐标查信息”—— 用纹理坐标当 “索引”，从贴图里提取对应位置的具体数据（这里是法线方向）)
                //对采集的屏幕图像进行关于法线方向上的扭曲和偏移 ， 也就是模拟折射效果
                //_RefractionTex_TexelSize 表示纹理 的像素大小 (Texel Size)， 即纹理中每个像素在 uv  坐标中的大小 [Z：（形式：纹理名_TexelSize） 是 Unity 自动为纹理生成的变量，它代表 “1 个像素在 UV 坐标中占多大”（也就是说，其实还是看贴图，但这里正好UV和屏幕大小相同）]
                float2 offset =  tanNormal.xy * _Distortion * _RefractionTex_TexelSize.xy;//Z：* _RefractionTex_TexelSize.xy是为了避免不同分辨率屏幕效果差异过大（让偏移量按 “像素数量” 计算，而不是按纹理坐标比例）
                i.scrPos.xy += offset;          
                fixed3 color =  tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).xyz;      //Z：根据计算好的 “偏移后位置”，从抓取的屏幕图像中取出对应颜色，作为玻璃上该点最终显示的颜色***********************************
                                                                                          //Z：i.scrPos.xy / i.scrPos.w ，“透视除法”，作用是处理 “近大远小” 的透视效果
                                                                                          //Z：注意这里之所以需要透视除法，因为屏幕截图的坐标是 “带透视变形的”，所以必须除 w 来修正（其实，普通纹理的坐标也有但是 “模型自带的纹理坐标（uv）”，这个坐标天生就和纹理匹配）？？？？？？
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
