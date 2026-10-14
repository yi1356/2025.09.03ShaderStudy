Shader "Chapter1/chapter1_3"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {} // 主纹理
        _DistortTex("Distortion Texture", 2D) = "white" {} // 扭曲纹理
		_DistortAmount("Distortion Amount", Range(0,2)) = 0.5 // 扭曲强度
		_DistortTexXSpeed("Scroll speed X", Range(-50,50)) = 5 // 扭曲纹理在X方向上的滚动速度
		_DistortTexYSpeed("Scroll speed Y", Range(-50,50)) = 5 // 扭曲纹理在Y方向上的滚动速度
        [HideInInspector] _RandomSeed("_MaxYUV", Range(0, 10000)) = 0.0 // 隐藏在Inspector中，随机种子值
    }
    SubShader
    {
        Tags {
            "Queue"="Transparent" // 设置渲染队列为透明队列，表示该对象会在不透明对象之后渲染，数值越大越后渲染
            "RenderType"="Transparent" // 设置渲染类型为透明类型
        }

        Blend SrcAlpha OneMinusSrcAlpha // 设置混合模式，使用源和目标的Alpha值进行混合
        LOD 100 // 设置Shader的细节层次，用于区分不同性能设备支持的渲染效果

        Pass
        {
            CGPROGRAM
            #pragma vertex vert // 顶点着色器入口
            #pragma fragment frag // 片段着色器入口
            // 启用雾效支持
            #pragma multi_compile_fog

            #include "UnityCG.cginc" // 引入Unity常用的着色器函数库

            struct appdata
            {
                float4 vertex : POSITION; // 顶点位置
                float2 uv : TEXCOORD0; // UV坐标
            };

            struct v2f
            {
                float2 uv : TEXCOORD0; // UV坐标
                UNITY_FOG_COORDS(1) // 雾效的插值数据
                float4 vertex : SV_POSITION; // 转换到裁剪空间的顶点位置
                half2 uvDistTex : TEXCOORD3; // 用于扭曲纹理的UV坐标
            };

            sampler2D _MainTex; // 主纹理采样器
            float4 _MainTex_ST; // 主纹理的缩放和偏移
            sampler2D _DistortTex; // 扭曲纹理采样器
			half4 _DistortTex_ST; // 扭曲纹理的缩放和偏移
			half _DistortTexXSpeed, _DistortTexYSpeed, _DistortAmount; // 扭曲相关的参数
            UNITY_DEFINE_INSTANCED_PROP(float, _RandomSeed) // 定义实例化属性，随机种子，
            //这个宏用于在着色器代码中定义一个实例化的属性。实例化属性意味着每个渲染实例（比如每个物体或每个渲染单元）都可以有不同的属性值，而不是共享一个值。

            // 顶点着色器
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex); // 将顶点从本地空间转换到裁剪空间
                //TRANSFORM_TEX主要作用是拿顶点的uv去和材质球的tiling和offset作运算， 确保材质球里的缩放和偏移设置是正确的
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); // 对UV进行缩放和偏移变换
                UNITY_TRANSFER_FOG(o,o.vertex); // 传递雾效相关数据
                o.uvDistTex = TRANSFORM_TEX(v.uv, _DistortTex); // 对扭曲纹理的UV进行变换
                return o;
            }

            // 片段着色器
            fixed4 frag (v2f i) : SV_Target
            {
                half randomSeed = UNITY_ACCESS_INSTANCED_PROP(Props, _RandomSeed); // 获取随机种子值
                UNITY_APPLY_FOG(i.fogCoord, col); // 应用雾效

                // 根据时间和随机种子值滚动扭曲纹理的UV
                i.uvDistTex.x += ((_Time.x + randomSeed) * _DistortTexXSpeed) % 1;
				i.uvDistTex.y += ((_Time.x + randomSeed) * _DistortTexYSpeed) % 1;

				// 计算扭曲的强度，并对主纹理的UV坐标进行扰动
				half distortAmnt = (tex2D(_DistortTex, i.uvDistTex).r - 0.5) * 0.2 * _DistortAmount;
				i.uv.x += distortAmnt;
				i.uv.y += distortAmnt;

                fixed4 col = tex2D(_MainTex, i.uv); // 采样主纹理颜色
                return col; // 输出最终颜色
            }
            ENDCG
        }
    }
}
