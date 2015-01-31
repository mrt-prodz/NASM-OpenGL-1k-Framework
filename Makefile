TARGET = opengl
LIBS = kernel32.dll user32.dll opengl32.dll winmm.dll gdi32.dll

AFLAGS = -f win32 $(TARGET).asm -o $(TARGET).obj
LFLAGS = /entry start /mix  $(TARGET).obj $(LIBS)


all: $(TARGET)

$(TARGET): $(TARGET).asm
	nasm $(AFLAGS)
	golink $(LFLAGS)

recompile:
	make clean
	make all

clean:
	rm -f *.exe
	rm -f *.obj