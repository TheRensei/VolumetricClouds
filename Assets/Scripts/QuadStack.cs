using UnityEngine;

public class QuadStack : MonoBehaviour
{

    public int horizontalStackSize = 20;
    public float cloudHeight = 1f;
    public Mesh quadMesh;
    public Material cloudMaterial;
    float offset;

    public int layer;
    private Matrix4x4 matrix;
    private Matrix4x4[] matrices;

    void Update()
    {

        cloudMaterial.SetFloat("_midYValue", transform.position.y);
        cloudMaterial.SetFloat("_cloudHeight", cloudHeight);
        cloudMaterial.SetVector("_Origin", transform.position);

        offset = cloudHeight / horizontalStackSize / 2f;
        Vector3 startPosition = transform.position + (Vector3.up * (offset * horizontalStackSize / 2f));

        for (int i = 0; i < horizontalStackSize; i++)
        {
            matrix = Matrix4x4.TRS(startPosition - (Vector3.up * offset * i), transform.rotation, transform.localScale);
            Graphics.DrawMesh(quadMesh, matrix, cloudMaterial, layer, null, 0, null, false, false, false);
        }
    }

}
