Shader "ZChapter1/ZChapter1_3"//UV扰动效果
{
    Properties//Z：这里面的内容还要在后面再申明一边[因为这里属性中的值是给编辑器看的；后者是给 Shader 代码看的]
    {
        _MainTex ("Texture", 2D) = "white" {}//Z：_MainTex：变量名——"Texture"：在 Inspector 中显示的名字（给人看的）——2D：类型是 2D 纹理（图片）——"white"：默认值是纯白色纹理
        _DistortTex("Distortion TTexture",2D)="white" {}//扭曲纹理
        _DistortAmount("Distortion Amount",Range(0,2))=0.5 //扭曲强度
        _DistortTexXSpeed("Scroll speed X",Range(-50,50))=5 //扭曲纹理在X方向上的滚动速度
        _DistortTexYSpeed("Scroll speed Y",Range(-50,50))=5 //扭曲纹理在Y方向上的滚动速度

        [HideInInspector] _RandomSeed("_MaxYUV", Range(0,10000))=0 //隐藏在Inspector中，随机种子值
    }
    SubShader
    {
        Tags {                     //Z：标签，告诉 Unity 这个 Shader 的渲染规则
            "Queue" = "Transparent"// 设置渲染队列为透明队列，表示该对象会在不透明对象之后渲染，数值越大越后渲染
            "RenderType" = "Transparent" //设置渲染类型为透明类型（Z：给物体 "分类贴标签"）
            }

            Blend SrcAlpha OneMinusSrcAlpha //设置混合模式，使用源和目标的Alpha值进行混合（Z：常用来做水、玻璃等效果）
        LOD 100 //Z：细节级别，值越小，Shader 越简单（性能越好）。Unity 可以根据设备性能自动降低 LOD，选择更简单的 Shader。

        Pass//Z：一个 SubShader 可以有多个 Pass，每个 Pass 代表一次完整的渲染流程（比如先渲染阴影，再渲染颜色）
        {
            CGPROGRAM//Z：开始使用 CG 语言编写着色器代码（类似 C# 的using，告诉 Unity 接下来用 CG 语法）
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog    // Z：开启雾效支持（如果场景中有雾，这个 Shader 渲染的物体也会受雾影响）

            #include "UnityCG.cginc"

            struct appdata   //Z：定义传给顶点着色器的原始数据结构（从模型来的数据）
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;//Z：v.uv 是模型本身自带的 “纹理坐标”，就像模型表面画好的 “网格线”，每个顶点都对应网格上的一个交点，默认0~1
            };

            struct v2f//Z：顶点→片段着色器输出（v2f）[定义顶点着色器处理后，传给片段着色器的数据结构]????????????
            {
                float2 uv : TEXCOORD0; //Z：处理后的主纹理 UV 坐标(注意是处理后的，就是经过我们在编辑器上调整变化后的)
                UNITY_FOG_COORDS(1) //Z：雾效相关的坐标（用于计算雾对像素的影响）
                float4 vertex : SV_POSITION; //Z：转换到屏幕坐标的顶点位置（好像是：传递给片段着色器的裁剪空间位置）？？？？？？
                half2 uvDistTex : TEXCOORD3; //用于扭曲纹理的UV坐标
            };


            //Z：可以把这些理解成 “连接 Shader 和 Unity 面板的桥梁变量”；专门用来接收从 Unity 面板面板传递过来的参数，或者供 Shader 内部的工具函数
            sampler2D _MainTex;
            float4 _MainTex_ST;//Z：其实是专门存储面板中设置的 “平铺” 和 “偏移” 参数，被 TRANSFORM_TEX 函数偷偷使用了。当你在面板中调整纹理的 “平铺（Tiling）” 和 “偏移（Offset）” 时，这些值会自动 “传给”_MainTex_ST
            sampler2D _DistortTex; //扭曲纹理采样器
            half4 _DistortTex_ST; //扭曲纹理的缩放和偏移

            half _DistortTexXSpeed, _DistortTexYSpeed, _DistortAmount; // 扭曲相关的参数
            UNITY_DEFINE_INSTANCED_PROP(float,_RandomSeed) //定义实例化属性，随机种子
            //这个宏用于在着色器代码中定义一个实例化的属性，实例化属性意味着每个渲染实例(比如每个物体或者每个渲染单元) 都可以有不同属性值，而不是................
            //Z：这句话的作用是：让同一个材质的多个物体，拥有各自独立的_RandomSeed值，简单说就是 “复制粘贴的物体，效果能不一样”。
            //Z：UNITY_DEFINE_INSTANCED_PROP声明的变量是 “实例化属性”，相当于给每个物体开了个 “私人储物柜”，各自的种子存在自己的柜子里，互不干扰
            //Z：是 “创建多物体独立存储的变量容器”（建快递柜）。


            v2f vert (appdata v)//Z：顶点着色器——作用：处理每个顶点的位置，计算传给片段着色器的数据  
            {
                v2f o;//Z：创建输出结构的实例
                o.vertex = UnityObjectToClipPos(v.vertex);//Z：把模型空间的顶点位置（v.vertex）转换为屏幕裁剪空间的位置（最终显示在屏幕上的位置）
                //Z：注意处理纹理为什么都用v.uv为基准，因为v.uv 是模型本身自带的 “纹理坐标”，就像模型表面画好的 “网格线”，和o.uv 不是一回事
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);//Z：应用_MainTex_ST的缩放和偏移，计算最终的主纹理 UV 坐标（比如纹理平铺 2 倍，UV 会被放大 2 倍）
                UNITY_TRANSFER_FOG(o,o.vertex);//Z：计算雾效坐标，让片段着色器知道这个像素受雾影响的程度（应该不太用了解了）
                o.uvDistTex = TRANSFORM_TEX(v.uv,_DistortTex); //对扭曲纹理的UV进行变换；Z：计算扭曲纹理的 UV 坐标（同样考虑缩放和偏移），传给片段着色器
                return o;
            }

            fixed4 frag (v2f i) : SV_Target//Z：片段着色器——作用：计算每个像素的最终颜色（核心效果在这里实现）
                                           //fixed4：返回值是一个四维颜色（RGBA，fixed 是低精度，节省性能）
                                           //SV_Target：语义，告诉 GPU 这个返回值是要画到屏幕上的颜色。
            {
                half randomSeed = UNITY_ACCESS_INSTANCED_PROP(Props, _RandomSeed); // 获取随机种子值；Z：“取出当前物体在容器中的专属值”（取对应格子的东西）
                UNITY_APPLY_FOG(i.fogCoord, col); // 应用雾效

                // 根据时间和随机种子值滚动扭曲纹理的UV
                i.uvDistTex.x += ((_Time.x + randomSeed) * _DistortTexXSpeed) % 1;//Z：_Time.x（可以理解为从程序运行开始每秒+1，/20）； % 1是为了限制使其为0~1防止衔接有问题（注意：%1 只限制 “动态滚动的部分”，不影响你设置的 Tiling/Offset）；？？？？？？？
                                                                                  //Z：无论 TRANSFORM_TEX 处理后 UV 是多大范围，最终都把它 “压缩” 回 0~1，确保纹理滚动时不会因为数值过大而出错。
				i.uvDistTex.y += ((_Time.x + randomSeed) * _DistortTexYSpeed) % 1;

				// 计算扭曲的强度，并对主纹理的UV坐标进行扰动
                //Z：根据扭曲纹理的明暗，计算主纹理应该偏移多少（暗的地方向左下偏，亮的地方向右上偏）。
				half distortAmnt = (tex2D(_DistortTex, i.uvDistTex).r - 0.5) * 0.2 * _DistortAmount;//Z：tex2D(_DistortTex, i.uvDistTex)采样扭曲纹理在当前 UV 位置的颜色（返回 RGBA），这里.r相当于取红色的值（0~1）；
                //Z：用计算出的扭曲量，偏移主纹理的 UV 坐标（让主纹理 "歪" 起来）
				i.uv.x += distortAmnt;
				i.uv.y += distortAmnt;

                fixed4 col = tex2D(_MainTex, i.uv); // 采样主纹理颜色（Z：根据偏移后的 UV，采样主纹理的颜色）
                return col; // 输出最终颜色
            }
            ENDCG
        }
    }
}
