//Z：作用：物体添加透明扭曲效果，有点像透过水、玻璃或魔法护盾看东西时，后面的画面会变形、波动的感觉


//Z：思路：

//Z：问题：还是不理解为什么getVectorFromCenter是计算像素到屏幕中心的距离，不理解模型的UV 与 整个屏幕的关系


Shader "ZChapter8/ZChapter8_5"
{
	Properties
	{
		_StrengthColor("Color strength", Float) = 1 // 颜色强度，默认1
		_DistortionStrength ("Distortion strength", Range(-2,2)) = 0.1 // 扭曲强度，范围-2到2，默认0.1
		_DistortionCircle ("Distortion circle", Range(0,1)) = 0 // 扭曲圆形范围，范围0到1，默认0
		_NormalTexture("Normal", 2D) = "blue" { } // 法线纹理，默认蓝色
		_NormalTexStrength("Normal strength", Range(0,1)) = 0.5 // 法线强度，范围0到1，默认0.5
		_NormalTexFrameless("Normal circle", Range(0,1)) = 0.5 // 法线圆形范围，范围0到1，默认0.5
		_UVOffset("UVOffset XY, ignore ZW", Vector) = (0,0.01,0,0) // UV偏移，默认(0, 0.01, 0, 0)
	}
	Category  //Z： Category，你可以把这些通用设置写在 Category 里，里面所有的 SubShader 都会自动继承这些设置，Category 和 SubShader 不是替代关系，而是 “包含关系”——Category 里面必须放 SubShader，它只是给 SubShader 提供 “共享设置” 的工具
	{
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" } // 渲染队列为透明，渲染类型为透明，忽略投影器
		Blend SrcAlpha OneMinusSrcAlpha // 混合模式：SrcAlpha, OneMinusSrcAlpha(Z：作用：设置透明度混合规则。公式为：最终颜色 = 自身颜色 × 自身透明度 + 背景颜色 ×(1 - 自身透明度)，实现半透明效果（比如玻璃的通透感）)
		ZWrite Off // 关闭深度写入
		SubShader
		{
			GrabPass // 抓取屏幕内容(Z：作用：设置透明度混合规则。公式为：最终颜色 = 自身颜色 × 自身透明度 + 背景颜色 ×(1 - 自身透明度)，实现半透明效果（比如玻璃的通透感）)
			{
				Name "BASE"//Z：给这个 Pass 起个名字
				Tags { "LightMode" = "Always" }//Z：Tags { "LightMode" = "Always" }：确保在任何光照模式下执行
			}
			Pass
			{
				Name "BASE"
				Tags { "LightMode" = "Always" }
				CGPROGRAM
				#pragma vertex vert // 顶点着色器
				#pragma fragment frag // 片段着色器
				#include "UnityCG.cginc" // 引入Unity的CG库
				
				sampler2D _GrabTexture; // 抓取的屏幕纹理（Z：这个应该是默认的）
				float _DistortionStrength; // 扭曲强度
				float _DistortionCircle; // 扭曲圆形范围
				float _StrengthColor; // 颜色强度
				sampler2D _NormalTexture; // 法线纹理
				float4 _NormalTexture_ST; // 法线纹理的缩放和偏移
				float _NormalTexStrength; // 法线强度
				float _NormalTexFrameless; // 法线圆形范围
				float4 _UVOffset; // UV偏移(X,Y代表速度)
				
				// 顶点着色器输入结构
				struct VertexInput
				{
					float4 vertex : POSITION; // 顶点位置
					float2 texcoord0 : TEXCOORD0; // 纹理坐标
					float4 color : COLOR; // 顶点颜色
				};
				
				// 顶点着色器输出结构
				struct Vert2Frag
				{
					float4 position : SV_POSITION; // 裁剪空间中的顶点位置
					float4 uv_grab : TEXCOORD0; // Z：抓取纹理的UV坐标（用于采样_GrabTexture）
					float2 uv : TEXCOORD1; // 纹理坐标（Z：传递给片段着色器）
					float2 uv_normal : TEXCOORD2; // 法线纹理的UV坐标（Z：用于采样_NormalTexture）
					float2 movement: TEXCOORD3; // UV偏移运动（Z：随时间变化的偏移量）？？？？？？？？？？？？？？？？？？？？？
					float4 color : TEXCOORD4; // 顶点颜色
				};


				
				// 顶点着色器（Z：主要是计算抓取纹理的UV坐标，法线纹理变换）
                //Z：顶点着色器的作用是处理每个顶点的位置和纹理坐标，输出给片段着色器
				Vert2Frag vert (VertexInput vertIn)
				{
					Vert2Frag output;
					output.position = UnityObjectToClipPos(vertIn.vertex); // 将顶点从对象空间转换到裁剪空间
					output.uv_grab = ComputeGrabScreenPos(output.position); // 计算抓取纹理的UV坐标 [Z：计算_GrabTexture（抓取的屏幕纹理）的 UV 坐标，让每个顶点对应的像素能正确采样到抓取的屏幕内容]******************************************************
					output.uv = vertIn.texcoord0; // 传递纹理坐标

                    //Z：下面这两句可以互换，意义是一样的
					//output.uv_normal = vertIn.texcoord0.xy * _NormalTexture_ST.xy + _NormalTexture_ST.zw; // 计算法线纹理的UV坐标（Z：原始 UV × 缩放（_NormalTexture_ST.xy） + 偏移（_NormalTexture_ST.zw））
                    output.uv_normal=TRANSFORM_TEX(vertIn.texcoord0,_NormalTexture);

					output.movement = _UVOffset.xy*_Time.y; // 计算UV偏移运动
					output.color = vertIn.color; // 传递顶点颜色
					return output;
				}
				
				// 获取从中心到当前UV的向量（Z：计算当前像素相对于屏幕中心的 "方向和距离"）？？？？？？？？？？？？？？？？没有理解
				float2 getVectorFromCenter(float2 uv)
				{
					float factor = _ScreenParams.y / _ScreenParams.x; // 计算屏幕宽高比
					float2 direction = float2((uv.x-0.5), (uv.y-0.5)) * factor; // 计算从中心到当前UV的向量
					return (direction);
				}
				
				// 获取扭曲强度（Z：基于离屏幕中心的距离？？？）
				float getDistortionStrength(float2 uv)
				{
					float2 diff = float2(distance(0.5, uv.x), distance(0.5, uv.y)) * 2.0; // 计算UV到中心的距离
					float dist = saturate(length(diff)); // 计算距离并限制在0到1之间 [Z：length(diff)：计算二维向量的长度]
					return 1.0-dist; // 返回扭曲强度（Z：也就是说越是中心扭曲强度越大）
				}
				
				// 获取法线（??????????????????????????????????????????）
				float2 getNormal(sampler2D _NormalTexture, float2 normalUv, float2 uv, float2 uvOffset, float frameless, float strength)
				{
					float2 normal = tex2D( _NormalTexture, normalUv+uvOffset ).zy; // 从法线纹理中获取法线值
					float length = getDistortionStrength(uv); // 获取扭曲强度
					float normalTexStrength = ((1-frameless) + frameless*length) * strength; // 计算法线强度
					normal.x = ((normal.x-.5)*2) * normalTexStrength; // 调整法线X分量
					normal.y = ((normal.y-.5)*2) * normalTexStrength; // 调整法线Y分量
					return normal; // 返回法线
				}
				
				// 片段着色器
				half4 frag (Vert2Frag fragIn) : SV_Target
				{
					float4 uvScreen = UNITY_PROJ_COORD(fragIn.uv_grab); // 获取抓取纹理的UV坐标
					float2 direction = getVectorFromCenter(fragIn.uv
						); // 获取从中心到当前UV的向量
					float strength = getDistortionStrength(fragIn.uv); // 获取扭曲强度
					strength = (_DistortionCircle*strength + (1-_DistortionCircle)) * _DistortionStrength; // 计算最终扭曲强度
					direction *= strength; // 调整方向向量
					uvScreen += float4(direction.x, direction.y, 0, 0); // 调整抓取纹理的UV坐标
					float2 influence = normalize(direction) * strength; // 计算影响向量
					float2 offset = fragIn.movement; // 获取UV偏移
					float2 normal = getNormal(_NormalTexture, fragIn.uv_normal, fragIn.uv, offset, _NormalTexFrameless, _NormalTexStrength); // 获取法线
					uvScreen += float4(normal.x, normal.y, 0, 0); // 调整抓取纹理的UV坐标
					influence += normal.xy; // 调整影响向量
					float4 final = tex2Dproj(_GrabTexture, uvScreen); // 从抓取纹理中获取颜色
					float alpha = 1; // 设置透明度
					final = float4(final.xyz, alpha); // 设置最终颜色
					strength = saturate(sqrt(pow(abs(influence.x), 2.0) + pow(abs(influence.y), 2.0)) * _StrengthColor); // 计算最终强度
					final = final + (fragIn.color*strength); // 调整最终颜色
					final.w = saturate(final.w*fragIn.color.w); // 调整最终透明度
					return final; // 返回最终颜色
				}
				ENDCG
			}
		}
	}
}
