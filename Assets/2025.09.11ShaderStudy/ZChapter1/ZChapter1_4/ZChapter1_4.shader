Shader "ZChapter1/ZChapter1_4"//外描边效果
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Main Color", Color) = (1,1,1,1) //主颜色，默认为白色
        _OutLineTex("OutLine Texture",2D)="White"{}//轮廓纹理，默认为白色纹理
        _OutLineTexXSpeed("TexTure scroll speed X",Range(-50,50))=10//轮廓纹理在X轴上的滚动速度
        _OutLineTexYSpeed("TexTure scroll speed Y",Range(-50,50))=10//轮廓纹理在Y轴上的滚动速度
        [HideInInspector] _RandomSeed("_MaxYUV", Range(0,10000))=0 //隐藏在Inspector中，随机种子值


        [Space] //空格，分割属性
        _OutLineDistortTex("Outline Distortion Textrue",2D)="White" {}// 轮廓失真纹理，默认为白色纹理
        _OutLineDistortAmount("Outline Distortion Amount",Range(0,2))=0.5//轮廓失真强度（Z：边缘轮廓的不规则程度）
        _OutLineDistortTexXSpeed("Distortion Scroll speed X",Range(-50,50))=5 //失真纹理在X方向上的滚动速度
        _OutLineDistortTexYSpeed("Distortion Scroll speed Y",Range(-50,50))=5 //失真纹理在Y方向上的滚动速度

        [Space] //空格，分割属性
        _OutLineColor("Outline Base Color",Color)=(1,1,1,1)// 轮廓的基本颜色，默认为白色
        _OutLineAlpha("Outline Base Alpha",Range(0,1))=1// 轮廓透明度，默认为1
        _OutLineGlow("Outline Base Glow",Range(0,100))=1.5// 轮廓发光强度
        _OutLineWidth("Outline Base Width",Range(0,0.5))=0.004// 轮廓宽度
        
    }
    SubShader
    {
        Tags { 
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        Blend SrcAlpha OneMinusSrcAlpha //设置混合模式，使用源和目标的Alpha值进行混合（Z：常用来做水、玻璃等效果）
        LOD 100


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
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half4 color : COLOR;//顶点颜色
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                half4 color : COLOR;//顶点颜色
                half2 uvOutTex :  TEXCOORD1;//用于轮廓纹理的纹理坐标
                half2 uvOutDistTex : TEXCOORD2;//用于轮廓失真纹理的纹理坐标
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST, _MainTex_TexelSize, _Color; //主纹理的变换和颜色值[Z：_MainTex_TexelSize（形式：纹理名_TexelSize） 是 Unity 自动为纹理生成的变量，它代表 “1 个像素在 UV 坐标中占多大”]

            sampler2D _OutLineTex;//轮廓纹理
            half4 _OutLineTex_ST;//轮廓纹理的变换
            half  _OutLineTexXSpeed, _OutLineTexYSpeed; //轮廓纹理的滚动速度

            half4 _OutLineColor; //轮廓的基本颜色
            half _OutLineAlpha, _OutLineGlow, _OutLineWidth; //轮廓透明，发光强度，宽度


            sampler2D _OutLineDistortTex; //轮廓失真纹理
            half4 _OutLineDistortTex_ST;//轮廓失真纹理的变换
            half _OutLineDistortTexXSpeed, _OutLineDistortTexYSpeed, _OutLineDistortAmount;//失真纹理的滚动速度 和 强度

            UNITY_DEFINE_INSTANCED_PROP(float,_RandomSeed)// 随机种子，用于每个物体实例化

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;//将顶点颜色传递给片段着色器
                o.uvOutTex = TRANSFORM_TEX(v.uv,_OutLineTex);//轮廓纹理的坐标变换
                o.uvOutDistTex=TRANSFORM_TEX(v.uv, _OutLineDistortTex);//轮廓失真纹理的坐标变换
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
               fixed4 col = tex2D(_MainTex, i.uv);
               half originalAlpha = col.a;// 记录纹理的Alpha值 （Z：originalAlpha是当前像素自身的透明度（物体内部 = 1，背景 = 0，边缘 = 1））
               half randomSeed = UNITY_ACCESS_INSTANCED_PROP(Props, _RandomSeed); // 获取随机种子值；Z：“取出当前物体在容器中的专属值”（取对应格子的东西）
               //处理轮廓失真
               i.uvOutDistTex.x += ((_Time.x+randomSeed) * _OutLineDistortTexXSpeed) % 1;//轮廓失真纹理X轴滚动
               i.uvOutDistTex.y += ((_Time.x+randomSeed) * _OutLineDistortTexYSpeed) % 1;//轮廓失真纹理Y轴滚动
               half outDistortAmnt = (tex2D(_OutLineDistortTex, i.uvOutDistTex).r - 0.5) * 0.2 * _OutLineDistortAmount;//Z：tex2D(_DistortTex, i.uvDistTex)采样扭曲纹理在当前 UV 位置的颜色（返回 RGBA），这里.r相当于取红色的值（0~1）；
               //_MainTex_TexelSize是贴图 _MainTex 的像素尺寸大小， 值：Vector4(1/widht,1/height,width,height)？？？？？？
               //Z：作用：算出一个 “观察距离”（上下左右各看多远），这个距离会影响轮廓的粗细；（单位是 UV 坐标）；
               half2 destUv = half2(_OutLineWidth * _MainTex_TexelSize.x*200, _OutLineWidth * _MainTex_TexelSize.y*200);// 计算失真偏移???[Z：是后续 “检测边缘” 的关键，作用就是：不管图片多大，让你调的 “0.004” 始终对应差不多的实际像素宽度；且可以通过_OutLineWidth来控制轮廓宽度]********************
               destUv.x +=outDistortAmnt;// 应用X轴失真(Z：给 “观察距离” 加一点 “随机偏差”，虽然outDistortAmnt看起来比较大，但最终计算下来也就几个像素的波动)
               destUv.y +=outDistortAmnt;// 应用Y轴失真


               //采样主纹理的四个方向的透明值，来检测轮廓区域？？？？？（Z:原理就是检查一个像素上下左右检测范围里内的像素，如果透明度和<4就证明是边缘像素，但这里实际用起来魔改了下，更加复杂）
               half spriteLeft = tex2D(_MainTex, i.uv + half2(destUv.x,0)).a;//Z：这里好像写错了，左侧应该是-，但是影响不大
               half spriteRight = tex2D(_MainTex, i.uv - half2(destUv.x,0)).a;
               half spriteBottom = tex2D(_MainTex, i.uv+half2(0,destUv.y)).a;
               half spriteTop = tex2D(_MainTex, i.uv - half2(0,destUv.y)).a;
               half result = spriteLeft + spriteRight + spriteBottom + spriteTop;// 计算轮廓效果的强度

               //saturate（X）作用时如果x取值小于0则返回值为0，如x取值大于1，则返回值为1，若在0~1，则直接返回x值
               //step(edge,x);当x>edge时返回1，否则返回0
               result = step(0.05, saturate(result)); //通过saturate 和 step函数生成轮廓区域？？？？？？？[Z：到这里其实还没有完，这里=1的是物体内像素+边缘像素；其实就是剔除了透明背景，真正的判断边缘还在后面]****************************



               //轮廓纹理滚动??????
               i.uvOutTex.x +=((_Time.x + randomSeed) * _OutLineTexXSpeed) % 1; //轮廓纹理X轴滚动
               i.uvOutTex.y +=((_Time.x + randomSeed) * _OutLineTexYSpeed) % 1; //轮廓纹理Y轴滚动
               half4 tempOutColor = tex2D(_OutLineTex, i.uvOutTex); //获取轮廓纹理的颜色
               tempOutColor *= _OutLineColor; //应用轮廓颜色
               _OutLineColor = tempOutColor;
               half4 outline = _OutLineColor * i.color.a;//轮廓颜色，按顶点哈暗示为颜色加全权 
               outline.rgb*=_OutLineGlow; //应用轮廓发光效果
               //Z：总之，这里要筛选的是前面的result=1的(物体内部像素+边缘像素) 并且 originalAlpha=0的（也就是这个像素本身透明度是0）；这样来筛选出真正的边缘像素
               result *= (1- originalAlpha) * _OutLineAlpha;//根据主纹理透明度调整轮廓透明度？？？？？？[Z：锁定 “真正的边缘”（result最终调整），：从 “物体相关区域”（物体内像素+边缘像素） 里，精准找出 “边缘”]******************************
               //Z：经过最终筛选后，真正的边缘像素result=1，透明背景和物体内部为0；
               outline.a = result; //轮廓的透明度为轮廓强度


               //Z：核心部分??????
               //Lerp用于得出两个状态（两个值，两个点，两种颜色，两个角度）的中间状态，插值一般取0~1??????
               //靠近0时接近第一个状态，靠近1时接近第二个状态
               col = lerp(col, outline, result);// 将主纹理与轮廓纹理混合
               col *= _Color; //应用主颜色
               
                return col;
            }
            ENDCG
        }
    }
}
