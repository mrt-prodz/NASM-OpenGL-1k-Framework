#NASM/GoLink OpenGL 1k Framework
 
####Tiny OpenGL fragment shader

This is a port of [Jeff "drift" Symons Visual Studio OpenGL 1k Framework](http://www.pouet.net/topic.php?which=10038&page=2#c480977) in x86 Assembly using NASM/GoLink.

The purpose of this project was to build a tiny binary being able to play OpenGL fragment shader and play music in the background. I tried to save a couple bytes by re-using registers a lot, source is documented.

##Features:

Following Jeff "drift" Symons project:

* OpenGL fragment shader (plasma)
* MIDI ambient noise
* 2,560 bytes unpacked compiled binary

This is a Windows project, Makefile and code have been created for NASM/GoLink.

##Screenshot:
![Plasma fragment shader](https://raw.githubusercontent.com/mrt-prodz/NASM-OpenGL-1k-Framework/master/screenshot.jpg)

##Reference:
[Jeff "drift" Symons Visual Studio OpenGL 1k Framework on pouet.net](http://www.pouet.net/topic.php?which=10038&page=2#c480977)

[NASM](http://www.nasm.us/)

[GoLink](http://www.godevtool.com/)