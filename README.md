# Godot Yarn Editor
A viewer/editor for Yarn text files.

<p align="center">
  <img src="media/godot-yarn-editor-screen1.png">
</p>

Built in Godot 4.3

## Purpose

Can't seem to find just a basic Yarn editor that isn't in a browser..
And also works with my yarn custom mods...
As text-edited yarn files get larger and larger, the need for visualization also grows...

The plan is to have a visualizer so that we can see broken/dead end paths, etc,
while also keeping text-friendly manual editing at the forefront of any saves.

Viewing Yarn files is the focus of this editor, creating + editing them is secondary.
It will still be recommended to do most of that by hand, and using the GYE for visual overviews and tweaking.

## Tree Sorting

A future feature planned is adding algorithms for auto-arrangement of trees.

## Godot

This is not be meant as an addon for Godot, just a stand-alone yarn editing app.

Godot is just the framework for the app, but in the future, turning it into addon should be easy if warranted.

Currently uses Godot 4.3dev5, was supposed to be 4.2 but accidentally was opened in 4.3 and now 4.2 can't open yarn_box.tscn.

## Credits

Addons / Libraries:
- Eranot Resizable Addon [https://github.com/Eranot/godot-resizable]
- Godot Yarn Importer [https://github.com/naturally-intelligent/godot-yarn-importer]

