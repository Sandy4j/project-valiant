using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

[Tool]
public partial class DungeonGenerator : Node3D
{
	[Export]
	public NodePath GridMapPath;

	private GridMap _gridMap;

	[Export]
	public bool Start
	{
		get => _start;
		set
		{
			_start = value;
			if (Engine.IsEditorHint())
			{
				CreateDungeon();
			}
		}
	}
	private bool _start = false;

	private PackedScene _dunCellScene;

	private Dictionary<string, Vector3I> _directions = new Dictionary<string, Vector3I>
	{
		{"up", Vector3I.Forward},
		{"down", Vector3I.Back},
		{"left", Vector3I.Left},
		{"right", Vector3I.Right}
	};

	public override void _Ready()
	{
		_gridMap = GetNode<GridMap>(GridMapPath);
		_dunCellScene = GD.Load<PackedScene>("res://Proc Dungeon/imports/DunCell.tscn");
	}

	private void HandleNone(Node3D cell, string dir) => cell.Call("remove_door_" + dir);

	private void Handle00(Node3D cell, string dir)
	{
		cell.Call("remove_wall_" + dir);
		cell.Call("remove_door_" + dir);
	}

	private void Handle01(Node3D cell, string dir) => cell.Call("remove_door_" + dir);

	private void Handle02(Node3D cell, string dir)
	{
		cell.Call("remove_wall_" + dir);
		cell.Call("remove_door_" + dir);
	}

	private void Handle10(Node3D cell, string dir) => cell.Call("remove_door_" + dir);

	private void Handle11(Node3D cell, string dir)
	{
		cell.Call("remove_wall_" + dir);
		cell.Call("remove_door_" + dir);
	}

	private void Handle12(Node3D cell, string dir)
	{
		cell.Call("remove_wall_" + dir);
		cell.Call("remove_door_" + dir);
	}

	private void Handle20(Node3D cell, string dir)
	{
		cell.Call("remove_wall_" + dir);
		cell.Call("remove_door_" + dir);
	}

	private void Handle21(Node3D cell, string dir) => cell.Call("remove_wall_" + dir);

	private void Handle22(Node3D cell, string dir)
	{
		cell.Call("remove_wall_" + dir);
		cell.Call("remove_door_" + dir);
	}

	private async void CreateDungeon()
	{
		foreach (Node child in GetChildren())
		{
			RemoveChild(child);
			child.QueueFree();
		}

		int t = 0;
		foreach (Vector3I cell in _gridMap.GetUsedCells())
		{
			int cellIndex = _gridMap.GetCellItem(cell);
			if (cellIndex <= 2 && cellIndex >= 0)
			{
				Node3D dunCell = _dunCellScene.Instantiate<Node3D>();
				dunCell.Position = cell + new Vector3(0.5f, 0, 0.5f);
				AddChild(dunCell);
				t++;

				for (int i = 0; i < 4; i++)
				{
					Vector3I cellN = cell + _directions.Values.ElementAt(i);
					int cellNIndex = _gridMap.GetCellItem(cellN);
					if (cellNIndex == -1 || cellNIndex == 3)
					{
						HandleNone(dunCell, _directions.Keys.ElementAt(i));
					}
					else
					{
						string key = $"{cellIndex}{cellNIndex}";
						CallDeferred("Handle" + key, dunCell, _directions.Keys.ElementAt(i));
					}
				}

				if (t % 10 == 9)
				{
					await ToSignal(GetTree().CreateTimer(0), SceneTreeTimer.SignalName.Timeout);
				}
			}
		}
	}
}
