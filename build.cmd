@echo off

set cfile=loader

\masm32\bin\ml /c /coff /Cp %cfile%.asm
\masm32\bin\link /SUBSYSTEM:WINDOWS /LIBPATH:\masm32\lib %cfile%.obj
pause