using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class UpdateCut : MonoBehaviour
{
    public GameObject CuttingPosition;

    private Material[] Material = {};
    private Vector3 Center = new Vector3(0, 0, 0);
    void Start()
    {
        //获取当前物体材质
        Renderer[] renderers = GetComponentsInChildren<Renderer>();
        Material = new Material[renderers.Length];
        for (int i = 0; i < renderers.Length; i++)
        {
            Material[i] = renderers[i].sharedMaterial;
        }
    }

    void Update()
    {
        if (CuttingPosition)
        {
            for (int i = 0; i < Material.Length; i++)
            {
                Material[i].SetVector("_Position", CuttingPosition.transform.position);
            }  
        }
        else
        {
            for (int i = 0; i < Material.Length; i++)
            {
                Material[i].SetVector("_Position", Center);
            } 
        }

    }
}
