Shader "Chapter1/chapter1_4" // 定义着色器名称为“Chapter1/chapter1_4”
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}  // 主纹理，默认为白色纹理
        _Color("Main Color", Color) = (1,1,1,1) // 主颜色，默认为白色

        _OutlineTex("Outline Texture", 2D) = "white" {} // 轮廓纹理，默认为白色纹理
        _OutlineTexXSpeed("Texture scroll speed X", Range(-50,50)) = 10 // 轮廓纹理在X轴上的滚动速度
        _OutlineTexYSpeed("Texture scroll speed Y", Range(-50,50)) = 0 // 轮廓纹理在Y轴上的滚动速度
        [HideInInspector] _RandomSeed("_MaxYUV", Range(0, 10000)) = 0.0 // 随机种子，影响轮廓随机效果
        
        [Space] // 空格，用于分隔属性
        _OutlineDistortTex("Outline Distortion Texture", 2D) = "white" {} // 轮廓失真纹理，默认为白色纹理
        _OutlineDistortAmount("Outline Distortion Amount", Range(0,2)) = 0.5 // 轮廓失真强度
        _OutlineDistortTexXSpeed("Distortion scroll speed X", Range(-50,50)) = 5 // 失真纹理在X轴的滚动速度
        _OutlineDistortTexYSpeed("Distortion scroll speed Y", Range(-50,50)) = 5 // 失真纹理在Y轴的滚动速度
        
        [Space] // 空格，用于分隔属性
        _OutlineColor("Outline Base Color", Color) = (1,1,1,1) // 轮廓的基本颜色，默认为白色
        _OutlineAlpha("Outline Base Alpha",  Range(0,1)) = 1 // 轮廓透明度，默认为1（完全不透明）
        _OutlineGlow("Outline Base Glow", Range(1,100)) = 1.5 // 轮廓发光强度
        _OutlineWidth("Outline Base Width", Range(0,0.2)) = 0.004 // 轮廓宽度
    }
    SubShader
    {
        Tags {
            "Queue"="Transparent" // 设置渲染队列为透明队列，表示该对象会在不透明对象后渲染
            "RenderType"="Transparent" // 设置渲染类型为透明类型
        }

        Blend SrcAlpha OneMinusSrcAlpha // 设置混合模式，基于源Alpha进行混合
        LOD 100 // 设定Shader的细节层次为100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert // 使用顶点着色器
            #pragma fragment frag // 使用片段着色器
            // 使雾效工作
            #pragma multi_compile_fog // 启用多种雾效编译选项

            #include "UnityCG.cginc" // 引入Unity的通用着色器代码库

            // 定义输入结构体，用于接收顶点数据
            struct appdata
            {
                float4 vertex : POSITION; // 顶点位置
                float2 uv : TEXCOORD0; // 顶点纹理坐标
                half4 color : COLOR; // 顶点颜色
            };

            // 定义输出结构体，传递数据到片段着色器
            struct v2f
            {
                float2 uv : TEXCOORD0; // 顶点的纹理坐标
                half4 color : COLOR; // 顶点颜色
                half2 uvOutTex : TEXCOORD1; // 用于轮廓纹理的纹理坐标
                half2 uvOutDistTex : TEXCOORD2; // 用于轮廓失真纹理的纹理坐标
                float4 vertex : SV_POSITION; // 顶点位置（裁剪空间）
            };

            // 声明所有纹理采样器和参数
            sampler2D _MainTex; // 主纹理
            float4 _MainTex_ST, _MainTex_TexelSize, _Color; // 主纹理的变换和颜色值

            sampler2D _OutlineTex; // 轮廓纹理
            half4 _OutlineTex_ST; // 轮廓纹理的变换
            half _OutlineTexXSpeed, _OutlineTexYSpeed; // 轮廓纹理滚动速度

            half4 _OutlineColor; // 轮廓的基本颜色
            half _OutlineAlpha, _OutlineGlow, _OutlineWidth; // 轮廓透明度、发光强度、宽度

            sampler2D _OutlineDistortTex; // 轮廓失真纹理
            half4 _OutlineDistortTex_ST; // 轮廓失真纹理的变换
            half _OutlineDistortTexXSpeed, _OutlineDistortTexYSpeed, _OutlineDistortAmount; // 失真纹理的滚动速度和强度
            
            UNITY_DEFINE_INSTANCED_PROP(float, _RandomSeed) // 随机种子，用于每个物体实例化

            // 顶点着色器
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex); // 将顶点坐标转换到裁剪空间
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); // 将纹理坐标从模型空间转换到UV空间
                o.color = v.color; // 将顶点颜色传递给片段着色器
                o.uvOutTex = TRANSFORM_TEX(v.uv, _OutlineTex); // 轮廓纹理的坐标变换
                o.uvOutDistTex = TRANSFORM_TEX(v.uv, _OutlineDistortTex); // 轮廓失真纹理的坐标变换
                return o;
            }

            // 片段着色器
            fixed4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv); // 获取主纹理的颜色
                half originalAlpha = col.a; // 记录主纹理的Alpha值

                half randomSeed = UNITY_ACCESS_INSTANCED_PROP(Props, _RandomSeed); // 获取随机种子值

                // 处理轮廓失真(Z：让扰动纹理滚动，并采样明暗，计算得出失真强度[后面扰动轮廓纹理要用])
                i.uvOutDistTex.x += ((_Time.x + randomSeed) * _OutlineDistortTexXSpeed) % 1; // 轮廓失真纹理X轴滚动
                i.uvOutDistTex.y += ((_Time.x + randomSeed) * _OutlineDistortTexYSpeed) % 1; // 轮廓失真纹理Y轴滚动
                half outDistortAmnt = (tex2D(_OutlineDistortTex, i.uvOutDistTex).r - 0.5) * 0.2 * _OutlineDistortAmount; // 获取失真强度
                //_MainTex_TexelSize是贴图 _MainTex 的像素尺寸大小，值： Vector4(1 / width, 1 / height, width, height)？？？？？？
                half2 destUv = half2(_OutlineWidth * _MainTex_TexelSize.x * 200, _OutlineWidth * _MainTex_TexelSize.y * 200); // 计算失真偏移
                destUv.x += outDistortAmnt; // 应用X轴失真
                destUv.y += outDistortAmnt; // 应用Y轴失真

                // 采样主纹理的四个方向的透明度值，来检测轮廓区域
                half spriteLeft = tex2D(_MainTex, i.uv + half2(destUv.x, 0)).a;
                half spriteRight = tex2D(_MainTex, i.uv - half2(destUv.x, 0)).a;
                half spriteBottom = tex2D(_MainTex, i.uv + half2(0, destUv.y)).a;
                half spriteTop = tex2D(_MainTex, i.uv - half2(0, destUv.y)).a;
                half result = spriteLeft + spriteRight + spriteBottom + spriteTop; // 计算轮廓效果的强度
                //saturate(x)的作用是如果x取值小于0，则返回值为0。如果x取值大于1，则返回值为1。若x在0到1之间，则直接返回x的值
                //step(edge,x)：当x>edge时返回1，否则返回0
                result = step(0.05, saturate(result)); // 通过saturate和step函数生成轮廓区域
                
                // 轮廓纹理滚动
                i.uvOutTex.x += ((_Time.x + randomSeed) * _OutlineTexXSpeed) % 1; // 轮廓纹理X轴滚动
                i.uvOutTex.y += ((_Time.x + randomSeed) * _OutlineTexYSpeed) % 1; // 轮廓纹理Y轴滚动
                half4 tempOutColor = tex2D(_OutlineTex, i.uvOutTex); // 获取轮廓纹理的颜色
                tempOutColor *= _OutlineColor; // 应用轮廓颜色
                _OutlineColor = tempOutColor;
                half4 outline = _OutlineColor * i.color.a; // 轮廓颜色，按顶点颜色加权
                outline.rgb *= _OutlineGlow; // 应用轮廓发光效果
                result *= (1 - originalAlpha) * _OutlineAlpha; // 根据主纹理透明度调整轮廓透明度
                outline.a = result; // 轮廓的透明度为轮廓强度

                //Lerp用于得出两个状态(两个值, 两个点, 两种颜色, 两个角度等)的中间状态, 插值一般取0~1,
                //靠近0时接近第一个状态, 靠近1时接近第二个状态
                col = lerp(col, outline, result); // 将主纹理与轮廓纹理混合
                col *= _Color; // 应用主颜色

                return col; // 返回最终的颜色结果
            }
            ENDCG
        }
    }
}
