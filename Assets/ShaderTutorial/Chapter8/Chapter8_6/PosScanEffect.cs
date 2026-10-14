using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// 该脚本实现了一个扫描效果，当用户点击物体时，扫描效果会从该位置开始，并随时间扩展
// 这个脚本会在编辑模式下也生效（[ExecuteInEditMode]属性）
[ExecuteInEditMode]
public class PosScanEffect : MonoBehaviour
{
    // 用于存储扫描效果的材质（shader），此材质会控制实际的视觉效果
    public Material ScanMat;

    // 控制扫描速度，扫描的范围会根据这个值逐渐增大
    public float ScanSpeed = 20;

    // 扫描计时器，决定扫描的进度，随着时间的推移，扫描的范围会增大
    public float scanTimer = 0;

    // 存储相机组件的引用
    private Camera scanCam;

    // 记录扫描的中心点，即鼠标点击时的物体位置
    private Vector3 ScanPoint = Vector3.zero;

    // 初始化方法，这里没有初始化操作
    void Awake()
    {
    }

    // 每一帧调用，主要用于计算扫描参数和更新扫描效果
    private void Update()
    {
        // 获取当前物体上的相机组件
        scanCam = GetComponent<Camera>();

        // 启用深度纹理（Depth）和法线深度纹理（DepthNormals），这些纹理对后续的渲染处理至关重要
        scanCam.depthTextureMode |= DepthTextureMode.Depth;
        scanCam.depthTextureMode |= DepthTextureMode.DepthNormals;

        // 获取相机的长宽比
        float aspect = scanCam.aspect;

        // 获取相机的远裁剪平面（远离相机的最大距离）
        float farPlaneDistance = scanCam.farClipPlane;

        // 根据相机的视野（field of view）计算出上方向量，用于定位视锥体的边界
        Vector3 midup = Mathf.Tan(scanCam.fieldOfView / 2 * Mathf.Deg2Rad) * farPlaneDistance * scanCam.transform.up;

        // 计算右方向量，同样用于确定视锥体的边界
        Vector3 midright = Mathf.Tan(scanCam.fieldOfView / 2 * Mathf.Deg2Rad) * farPlaneDistance * scanCam.transform.right * aspect;

        // 计算远裁剪平面的中心点位置
        Vector3 farPlaneMid = scanCam.transform.forward * farPlaneDistance;

        // 根据计算出的参数确定视锥体的四个角的世界坐标
        Vector3 bottomLeft = farPlaneMid - midup - midright;
        Vector3 bottomRight = farPlaneMid - midup + midright;
        Vector3 upLeft = farPlaneMid + midup - midright;
        Vector3 upRight = farPlaneMid + midup + midright;

        // 创建一个矩阵来表示视锥体的四个角
        Matrix4x4 frustumCorner = new Matrix4x4();
        frustumCorner.SetRow(0, bottomLeft); // 设置底左角
        frustumCorner.SetRow(1, bottomRight); // 设置底右角
        frustumCorner.SetRow(2, upRight); // 设置上右角
        frustumCorner.SetRow(3, upLeft); // 设置上左角

        // 将视锥体的矩阵传递给Shader
        ScanMat.SetMatrix("_FrustumCorner", frustumCorner);

        // 进行射线检测，获取鼠标点击的世界坐标
        RaycastHit hit;
        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition); // 将鼠标屏幕坐标转换为射线
        if (Input.GetMouseButton(0) && Physics.Raycast(ray, out hit)) // 如果按下左键并且射线与物体碰撞
        {
            scanTimer = 0; // 重置扫描计时器
            ScanPoint = hit.point; // 获取碰撞点的位置作为扫描的起始点
        }

        // 增加扫描计时器，控制扫描的进度
        scanTimer += Time.deltaTime;

        // 将扫描的起始位置和扫描进度传递给材质（Shader）
        ScanMat.SetVector("_ScanCenter", ScanPoint);
        ScanMat.SetFloat("_ScanRange", scanTimer * ScanSpeed);

        // 将相机的世界坐标变换矩阵传递给Shader
        ScanMat.SetMatrix("_CamToWorld", scanCam.cameraToWorldMatrix);
    }

    // 在渲染图像时调用，进行后处理操作，应用扫描效果
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // 将相机的远裁剪平面距离传递给材质（Shader），用于控制扫描的范围
        ScanMat.SetFloat("_CamFar", GetComponent<Camera>().farClipPlane);

        // 使用Graphics.Blit方法将源纹理渲染到目标纹理，并应用扫描效果的材质
        Graphics.Blit(source, destination, ScanMat);
    }
}
