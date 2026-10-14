//作用："曲面细分 - 基于 phong"***根据模型表面 “弯曲程度”（曲率）来决定细分程度的方式 —— 表面越弯曲（比如棱角、弧度大的地方），细分越精细；表面越平坦（比如平面、弧度小的地方），细分越粗糙***





Shader "ZChapter5/Zchapter5_5_phong"
{
    Properties
    {
         _Phong ("Phong 强度", Range(0,1)) = 0.5    // Phong高光强度

        // 控制细分曲面因子的强度，范围是1到32，默认值为4。
        _Tess ("Tessellation", Range(1,32)) = 4
        
        // 最大距离。
        _MaxDis ("MaxDis", Range(1,100)) = 50
        
        // 最小距离。
        _MinDis ("MinDis", Range(1,100)) = 20
        
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
        #pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:dispNone tessellate:tessDistance tessphong:_Phong nolightmap 

        // 设置目标为Shader Model 4.6 (支持更高级功能，如细分着色)
        #pragma target 4.6

        // 包含Unity内置的细分曲面库，提供细分算法支持。
        #include "Tessellation.cginc"

        //定义应用程序顶点数据结构[Z：定义应用程序输入的顶点数据结构，包含渲染所需的基础顶点信息；      也就是说是顶点处理函数disp的输入]
        struct appdata
        {
            float4 vertex : POSITION; //顶点位置
            float4 tangent : TANGENT; //切线，用于法线映射
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0; //UV坐标 
        };

       
        // Phong高光强度
        float _Phong;
        // 定义细分曲面强度属性。
        float _Tess;
        float _MaxDis;
        float _MinDis;
        // 基于距离的细分曲面函数，使用Unity内置的算法。
        float4 tessDistance(appdata v0, appdata v1, appdata v2)//Z：v0.vertex / v1.vertex / v2.vertex：原始三角形的三个顶点位置
        {
           //设置最小 和 最大细分距离
           float minDist = _MinDis;  //最小距离，细分强度较大
           float maxDist = _MaxDis; //最大距离，细分强度较小

           // 调用unity的内置函数，根据顶点与相机的距离计算细分因子
           return UnityDistanceBasedTess(v0.vertex,v1.vertex,v2.vertex ,minDist, maxDist, _Tess);

        }

        // 定义用于位移贴图的纹理采样器和位移强度变量。
        sampler2D _DispTex;
        float _Displacement;

        // 顶点处理函数，空函数，不做操作
        void dispNone(inout appdata v)
        {
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
