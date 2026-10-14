//作用："曲面细分 - 固定数量"（Tessellation - Fixed Count）是一种控制模型表面细分程度的方式，统一按设定的数值细分，目的是让模型表面变得更光滑或更精细
//原理：想象你有一个三角形纸片，它看起来是平的。如果把这个三角形的每条边都平均分成 2 份，然后连接这些分点，原来的 1 个三角形就会变成 4 个小三角形

//思路：
//设置好表面着色器编译指令，关联曲面细分函数——固定数量（tessFixed）[返回固定值]，关联顶点处理函数（disp）；
//在顶点处理函数中 根据灰度图计算出顶点位移强度，并移动顶点




Shader "ZChapter5/ZChapter5_2_regular"
{
    Properties
    {
       // 定义一个控制细分（Tessellation）程度的滑块，范围是1到32，默认值为4 [Z：控制曲面细分的程度]
        _Tess ("Tessellation", Range(1,32)) = 4
        
        // 定义基础颜色纹理属性，默认值为白色。
        _MainTex ("Base (RGB)", 2D) = "white" {}
        
        // 定义用于位移映射的纹理属性，默认值为灰色。
        _DispTex ("Disp Texture", 2D) = "gray" {}
        
        // 定义法线贴图属性，用于控制表面细节的法线效果，默认值为bump类型。
        _NormalMap ("Normalmap", 2D) = "bump" {}
        
        // 定义位移强度的滑块，范围是0到1，默认值为0.3 [Z：位移强度滑块，控制位移效果的幅度]
        _Displacement ("Displacement", Range(0, 1.0)) = 0.3
        
        // 定义颜色属性，用于控制整体颜色，默认值为白色。
        _Color ("Color", color) = (1,1,1,0)

        //定义镜面反射颜色属性，默认值为灰色???
        _SpecColor ("Spec color",color)=(0.5,0.5,0.5,0.5)


    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

        CGPROGRAM

        //Z：这一行是表面着色器编译指令******************************************************************************************
        // 使用BlinnPhong光照模型，启用阴影，并添加顶点位移和细分着色(Z：这里应该是设置光照之类的操作的吧)
        //Z：fullforwardshadows：在正向渲染中支持所有阴影类型
        //Z：vertex:disp：关联顶点处理函数（disp）
        //Z：tessellate:tessFixed：关联曲面细分函数（tessFixed）
        //Z：nolightmap：禁用光照贴图
        #pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:disp tessellate:tessFixed nolightmap 

        // 设置目标为Shader Model 4.6 (支持更高级功能，如细分着色)
        #pragma target 4.6

        //定义应用程序顶点数据结构[Z：定义应用程序输入的顶点数据结构，包含渲染所需的基础顶点信息；      也就是说是顶点处理函数disp的输入]
        struct appdata
        {
            float4 vertex : POSITION; //顶点位置
            float4 tangent : TANGENT; //切线，用于法线映射
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0; //UV坐标 
        };

        //定义细分界别变量，  用于控制细分程度
        float _Tess;

        //Z：固定数量细分的核心函数（返回的是固定数值）：返回用户设置的细分等级
        //固定细分级别函数，返回细分强度？？？
        float4 tessFixed()
        {
            return _Tess; //由用户设置的_Tess 值决定细分强度
        }

        // 定义用于位移贴图的纹理采样器和位移强度变量。
        sampler2D _DispTex;
        float _Displacement;

        //Z：这里是核心*********************************************************
        //位移函数，对顶点位置进行调整???????
        void  disp(inout appdata v){
            // 使用纹理采样lod方式获取位移贴图值，并乘以位移强度??????
            //Z：tex2Dlod用来 “读取纹理上某个点颜色”,这里用来读取模型上这个点位置中纹理的颜色信息，取灰度*位移变量得到真正的变化强度
            float d = tex2Dlod(_DispTex, float4(v.texcoord.xy, 0,0)).r * _Displacement;
            // 根据法线方向调整顶点位置，实现位移效果(Z：其实这一步就改变了顶点了)
            v.vertex.xyz += v.normal * d;
        }

        //定义输入结构体，用于传递UV坐标
        struct Input{
            float2 uv_MainTex;  // 主纹理的UV坐标
        };

        //定义其它所需变量
        sampler2D _MainTex; //主纹理采样器
        sampler2D _NormalMap; //法线贴图采样器
        fixed4 _Color; //基础颜色

        // Surface函数，处理表面着色逻辑。
        void surf (Input IN, inout SurfaceOutput o)
        {
            //从主纹理中采样颜色，并乘以用户设置的基础颜色。
            half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;

            //设置漫反射颜色（Albedo）
            o.Albedo = c.rgb;

            //设置镜面反射强度为0.2??????
            o.Specular = 0.2;

            //设置光泽度为1.0
            o.Gloss = 1.0;

            //从法线贴图中采样法线，并解包法线数据（Z：前面是用灰度图计算，实现凹凸起伏。这里法线是为了表面细节）*************************************
            o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));  
        }
        ENDCG
    }
    FallBack "Diffuse"
}
