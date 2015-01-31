; =============================================================================
;
; OpenGL 1k Framework
; -------------------
; Based on Jeff "drift" Symons Visual Studio project
; http://www.pouet.net/topic.php?which=10038&page=2#c480977
;
; Port to NASM/GoLink by Themistokle "mrt-prodz" Benetatos
;
; nasm -f win32 opengl.asm -o opengl.obj
; golink /entry start /mix opengl.obj kernel32.dll user32.dll opengl32.dll winmm.dll gdi32.dll
;
; =============================================================================

EXTERN ExitProcess
EXTERN CreateWindowExA
EXTERN GetAsyncKeyState
EXTERN PeekMessageA
EXTERN ShowCursor
EXTERN GetDC
EXTERN SetPixelFormat
EXTERN ChoosePixelFormat
EXTERN SwapBuffers
EXTERN wglMakeCurrent
EXTERN wglCreateContext
EXTERN wglGetProcAddress
EXTERN glColor3us
EXTERN glColor4ubv
EXTERN glRects
EXTERN timeGetTime
EXTERN midiOutOpen
EXTERN midiOutShortMsg

SECTION .data
    fShader     db "float t=gl_Color.x*100;"
                db "void main(){"
                db "vec2 r=gl_FragCoord.xy/500;"
                db "float c=sin(t+r.x*3)+sin(t+r.y*5)+sin((t+r.x+r.y)*4);"
                db "gl_FragColor=vec4(vec3(sin(c),sqrt(c),cos(c)),1);"
                db "}", 0

    glCreateShaderProgramv db "glCreateShaderProgramv", 0
    glUseProgram           db "glUseProgram", 0
    ;; PIXEL FORMAT DESCRIPTOR STRUC
    STRUC PXLFRMTDSCRPTR
        .nSize     resw 1  ;; word
        .nVersion  resw 1  ;; word
        .dwFlags   resd 1  ;; dword
    ENDSTRUC
    ;; Initialize struc with values
    pfd ISTRUC PXLFRMTDSCRPTR
        AT PXLFRMTDSCRPTR.nSize,     dw 0
        AT PXLFRMTDSCRPTR.nVersion,  dw 0
        AT PXLFRMTDSCRPTR.dwFlags,   dd 21  ;; PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER
    IEND

SECTION .bss
    midiOut        resd 1
    startTime      resd 1

SECTION .text
    global start

start:
    xor esi, esi                                        ;; Instead push 0 (2 bytes) push esi with value of 0 (1 byte)
    ;; Create window
    push esi                                            ;; lpParam
    push esi                                            ;; hInstance
    push esi                                            ;; hMenu
    push esi                                            ;; hWndParent
    push esi                                            ;; height
    push esi                                            ;; width
    push esi                                            ;; y
    push esi                                            ;; x
    push 0x91000000                                     ;; dwStyle - WS_POPUP | WS_VISIBLE | WS_MAXIMIZE
    push esi                                            ;; lpWindowName
    push 0x0C018                                        ;; lpClassName - Edit 
    push esi                                            ;; dwExStyle
    call [CreateWindowExA]

    push eax                                            ;; hWnd from CreateWindowExA
    call [GetDC]                                        ;; Get device context
    xchg edi, eax                                       ;; Save hDC in edi for later use

    push pfd                                            ;; pfd - pPixelformat
    push edi                                            ;; hDC
    call [ChoosePixelFormat]                            ;; Try to match pixel format for device context

    push pfd                                            ;; pfd
    push eax                                            ;; iPixelFormat from ChoosePixelFormat
    push edi                                            ;; hDC
    call [SetPixelFormat]                               ;; Set pixel format specified by iPixelFormat to device context

    push edi                                            ;; hDC
    call [wglCreateContext]                             ;; Create OpenGL context

    push eax                                            ;; Context from wglCreateContext
    push edi                                            ;; hDC
    call [wglMakeCurrent]                               ;; Make OpenGL context current rendering context

    push esi                                            ;; Set value to false (esi = 0)
    call [ShowCursor]                                   ;; Hide busy cursor

    push glCreateShaderProgramv                         ;; Get address of
    call [wglGetProcAddress]                            ;; OpenGL extension glCreateShaderProgramv

    push dword fShader                                  ;; Push fragment shader source on stack
    lea ebx, [esp]                                      ;; Load effective address of shader source on stack in ebx
    push dword ebx                                      ;; Push address of shader source
    push 1
    push 0x8B30                                         ;; GL_FRAGMENT_SHADER
    call eax                                            ;; Call glCreateShaderProgramv with fragment shader source
    xchg ebx, eax

    push glUseProgram                                   ;; Get address of
    call [wglGetProcAddress]                            ;; OpenGL extension glUseProgram

    push ebx                                            ;; Use shader program in ebx with the address of glUseProgram
    call eax                                            ;; Call glUserProgram

    ;; Play some MIDI ambient noise
    push esi                                            ;; dwFlags - esi = 0
    push esi                                            ;; dwCallbackInstance
    push esi                                            ;; dwCallback
    push esi                                            ;; uDeviceID
    push midiOut                                        ;; lphmo - Store to midiOut
    call [midiOutOpen]                                  ;;
    mov ebx, dword [midiOut]

    push 0x7EC0                                         ;; dwMsg - 0x7EC0
    push ebx                                            ;; hmo
    call [midiOutShortMsg]                              ;;

    push 0x7F2490                                       ;; dwMsg - 0x7F2490
    push ebx                                            ;; hmo
    call [midiOutShortMsg]                              ;;

    call [timeGetTime]                                  ;; Call timer
    mov dword [startTime], eax                          ;; Store output in startTime

    .loop:
        ;; Update timer
        call [timeGetTime]                              ;; Call timer
        xchg ebx, eax                                   ;; Save time elapsed in ebx
        sub ebx, [startTime]                            ;; startTime - currentTime

        ;; Send time to the shader through the red channel
        push esi                                        ;; blue - esi = 0
        push esi                                        ;; green
        push ebx                                        ;; red - Time elapsed
        call [glColor3us]

        ;; Create a fullscreen rectangle to display the fragment shader
        push 1                                          ;; y2
        push 1                                          ;; x2
        push -1                                         ;; y1
        push -1                                         ;; x1
        call [glRects]                                  ;;

        ;; Swap buffer and display shader
        push edi                                        ;; hDC was stored earlier in edi
        call [SwapBuffers]                              ;; Exchange front and back buffers for device context

        ;; PeekMessageA to remove busy cursor
        push esi                                        ;; wRemoveMsg - esi = 0
        push esi                                        ;; wMsgFilterMax
        push esi                                        ;; wMsgFilterMin
        push esi                                        ;; hWnd
        push 1                                          ;; lpMsg - PM_REMOVE - Remove message
        call [PeekMessageA]                             ;; Dispatch incoming sent message

        ;; Check if time limit has been reached
        cmp ebx, 10000                                  ;; Is time elapsed above 10 seconds?
        jge SHORT quit                                  ;; Quit if above limit

        ;; Check for VK_ESCAPE
        push 0x1B                                       ;; VK_ESCAPE
        call [GetAsyncKeyState]                         ;; Check for key state
        sahf
        jns SHORT .loop

quit:
    push esi                                            ;; esi = 0
    call [ExitProcess]                                  ;; 