Shader "Chapter6/chapter6_triangle_ani_2"
{
    Properties
    {
        _MainTex ("纹理", 2D) = "white" {}  // 主纹理，默认白色
		_BottomColor ("底部颜色", Color) = (1, 1, 1, 1)  // 底部颜色，默认白色
        _TopColor ("顶部颜色", Color) = (0, 0, 0, 1)  // 顶部颜色，默认黑色
        _Threshold ("阈值", Float) = 0  // 用于判断顶点位置的阈值
		_V0 ("初始速度", Float) = 0  // 初始速度
		_A ("加速度", Float) = 0  // 加速度
		_SizeVelocity ("大小变化速度", Float) = 1  // 控制大小变化的速度
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }  // 渲染类型为不透明
        LOD 100  // 细节级别

        Pass
        {
            CGPROGRAM
            #pragma vertex vert  // 顶点着色器
            #pragma geometry geom  // 几何着色器
            #pragma fragment frag  // 片段着色器

            #include "UnityCG.cginc"  // 引入 Unity 的 CG 库

            // 输入结构：从应用阶段传递到顶点着色器的数据
            struct a2v
            {
                float4 vertex : POSITION;  // 顶点位置
                float2 uv : TEXCOORD0;  // 纹理坐标
            };
            
            // 顶点着色器输出结构：传递到几何着色器的数据
            struct v2g
            {
                float4 vertex : POSITION;  // 顶点位置
                float2 uv : TEXCOORD0;  // 纹理坐标
            };

            // 几何着色器输出结构：传递到片段着色器的数据
            struct g2f
            {
                float4 vertex : SV_POSITION;  // 裁剪空间中的顶点位置
                float2 uv : TEXCOORD0;  // 纹理坐标
				float4 color : COLOR;  // 顶点颜色
            };

            sampler2D _MainTex;  // 主纹理
            float4 _MainTex_ST;  // 纹理的缩放和偏移
			float4 _BottomColor;  // 底部颜色
            float4 _TopColor;  // 顶部颜色
            float _Threshold;  // 阈值
			float _V0;  // 初始速度
			float _A;  // 加速度
			float _SizeVelocity;  // 大小变化速度

            // 顶点着色器
            v2g vert (a2v v)
            {
                v2g o;
                o.vertex = v.vertex;  // 传递顶点位置
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);  // 计算纹理坐标
                return o;
            }
            
            // 几何着色器：处理三角形
            [maxvertexcount(3)]  // 最大输出顶点数为 3
            void geom(triangle v2g input[3], inout TriangleStream<g2f> outStream)
            {   
                // 计算三角形的中心点
                float4 center = (input[0].vertex + input[1].vertex + input[2].vertex) / 3;

				g2f o;
				for(int i = 0; i < 3; i++)  // 遍历三角形的三个顶点
				{
					if(center.y >= _Threshold)  // 如果中心点的 y 坐标大于阈值
					{
						float t = center.y - _Threshold;  // 计算时间 t
						float v = _V0 * t + 0.5 * _A * t * t;  // 计算速度 v
						float4 dir = input[i].vertex - center;  // 计算顶点相对于中心点的方向

						o.vertex = center;  // 设置顶点位置为中心点
						if(t * _SizeVelocity <= 1)  // 如果大小变化速度未超过限制
						{
							o.vertex += dir;  // 保持原始大小
						}
						else
						{
							o.vertex += dir / (t * _SizeVelocity);  // 缩小顶点
						}
						o.vertex.y += v;  // 根据速度调整 y 坐标
						o.vertex = UnityObjectToClipPos(o.vertex);  // 转换到裁剪空间
						o.uv = input[i].uv;  // 传递纹理坐标
						o.color = lerp(_BottomColor, _TopColor, t * _SizeVelocity);  // 插值计算颜色
						outStream.Append(o);  // 输出顶点
					}
					else  // 如果中心点的 y 坐标小于阈值
					{
						o.vertex = input[i].vertex;  // 保持原始顶点位置
						o.vertex = UnityObjectToClipPos(o.vertex);  // 转换到裁剪空间
						o.uv = input[i].uv;  // 传递纹理坐标
						o.color = _BottomColor;  // 使用底部颜色
						outStream.Append(o);  // 输出顶点
					}
				}

				outStream.RestartStrip();  // 结束当前三角形并开始新的三角形
            }

            // 片段着色器
            fixed4 frag (g2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * i.color;  // 采样纹理并乘以颜色
                return col;  // 返回最终颜色
            }
            ENDCG
        }
    }
}