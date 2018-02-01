using UnityEngine;
using UnityEditor;

public static class GameEditorTools
{
	[MenuItem("Tools/Clear Progress Bar")]
	static internal void ClearProgressBar () { EditorUtility.ClearProgressBar(); }
}