using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

/// <summary>
/// Add the "SaveAs" function to the mesh.
/// </summary>

static public class MeshExtensionAddSaveAs
{
	static public Mesh SaveAs (this Mesh mesh, string path)
	{
		var existing = AssetDatabase.LoadAssetAtPath<Mesh>(path);

		if (existing == null)
		{
			AssetDatabase.CreateAsset(mesh, path);
			AssetDatabase.SaveAssets();
			return AssetDatabase.LoadAssetAtPath<Mesh>(path) ?? mesh;
		}

		existing.Clear();
		EditorUtility.CopySerialized(mesh, existing);
		AssetDatabase.SaveAssets();
		return existing;
	}

	[MenuItem("CONTEXT/MeshFilter/Save Mesh as...", true)]
	static bool SaveAsOptionA (MenuCommand menuCommand) { return (menuCommand.context as MeshFilter).sharedMesh != null; }

	[MenuItem("CONTEXT/MeshFilter/Save Mesh as...", false)]
	static void SaveAsOptionB (MenuCommand menuCommand)
	{
		var mesh = (menuCommand.context as MeshFilter).sharedMesh;
		string path = FileDialog.ShowSave(mesh.name, "asset");

		if (!string.IsNullOrEmpty(path))
		{
			path = "Assets" + path.Replace(Application.dataPath, "");
			mesh.SaveAs(path);
		}
	}

	[MenuItem("CONTEXT/MeshFilter/Slice off bottom", true)]
	static bool SliceOffBottomA (MenuCommand menuCommand) { return (menuCommand.context as MeshFilter).sharedMesh != null; }

	[MenuItem("CONTEXT/MeshFilter/Slice off bottom", false)]
	static void SliceOffBottomB (MenuCommand menuCommand)
	{
		var filter = (menuCommand.context as MeshFilter);
		string path = FileDialog.ShowSave(filter.sharedMesh.name, "asset");

		if (!string.IsNullOrEmpty(path))
		{
			path = "Assets" + path.Replace(Application.dataPath, "");
			var copy = SliceOffBottom(filter);

			if (copy != null)
			{
				copy.SaveAs(path);
				filter.transform.position = Vector3.zero;
				filter.sharedMesh = copy;
			}
		}
	}

	static Mesh SliceOffBottom (MeshFilter filter)
	{
		var slicer = new MeshSlicing.MeshSlicer();
		var cut = MeshSlicing.MeshSlicerTools.GetMeshInstance(filter);
		var split0 = new MeshSlicing.MeshInstance();
		var up = Vector3.up;
		var worldPos = Vector3.zero;
		var settings = new MeshSlicing.Settings();

		var plane = new MeshSlicing.Plane(up, worldPos);
		plane.InverseTransform(ref cut.world2local);
		plane.UpdateMatrices();

		if (slicer.Slice(cut, plane, split0, null, settings.crossUVs, settings.crossColor, settings) && split0.vertsD != null)
		{
			for (int i = 0; i < split0.vertsD.Length; ++i)
				split0.vertsD[i] = cut.local2world.MultiplyPoint3x4(split0.vertsD[i]);

			split0.mesh.name = filter.sharedMesh.name;
			return split0.mesh;
		}
		return null;
	}

	[MenuItem("CONTEXT/MeshFilter/Reset pivot to (0, 0, 0)", true)]
	static bool ResetPivotA (MenuCommand menuCommand) { return (menuCommand.context as MeshFilter).sharedMesh != null; }

	[MenuItem("CONTEXT/MeshFilter/Reset pivot to (0, 0, 0)", false)]
	static void ResetPivotB (MenuCommand menuCommand)
	{
		var filter = (menuCommand.context as MeshFilter);
		string path = FileDialog.ShowSave(filter.sharedMesh.name, "asset");

		if (!string.IsNullOrEmpty(path))
		{
			path = "Assets" + path.Replace(Application.dataPath, "");
			var copy = ResetPivot(filter);
			copy.SaveAs(path);

			var trans = filter.transform;
			trans.position = Vector3.zero;
			trans.rotation = Quaternion.identity;
			trans.localScale = Vector3.one;

			filter.sharedMesh = copy;
		}
	}

	static Mesh ResetPivot (MeshFilter filter)
	{
		var mesh = filter.sharedMesh;
		var verts = mesh.vertices;
		var norms = mesh.normals;
		var tans = mesh.tangents;
		var uv0 = mesh.uv;
		List<Vector4> uv2 = new List<Vector4>();
		mesh.GetUVs(1, uv2);
		var cols = mesh.colors32;
		var trans = filter.transform;
		var l2w = trans.localToWorldMatrix;

		for (int i = 0, imax = verts.Length; i < imax; ++i)
		{
			verts[i] = trans.TransformPoint(verts[i]);

			if (norms != null) norms[i] = trans.TransformDirection(norms[i]);

			if (tans != null)
			{
				var tan = tans[i];
				var v = new Vector3(tan.x, tan.y, tan.z);
				v = trans.TransformDirection(v);
				tan.x = v.x;
				tan.y = v.y;
				tan.z = v.z;
				tans[i] = tan;
			}
		}

		var copy = new Mesh();
		copy.name = mesh.name;
		copy.vertices = verts;
		if (norms != null) copy.normals = norms;
		if (tans != null) copy.tangents = tans;
		if (cols != null) copy.colors32 = cols;
		if (uv0 != null) copy.uv = uv0;
		copy.SetUVs(1, uv2);
		copy.triangles = mesh.triangles;
		return copy;
	}
}
