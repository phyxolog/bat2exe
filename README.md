# bat2exe
This small program generate tiny exe files from .bat

Loader write on assembler (use masm32).

Main dll write on C, use WinAPI.

# How to use
Complie c-dll\main.cpp. You get dll, her can use in your project.

Export functions:

*BOOL complie2exe(LPCSTR szFileName, LPCSTR szOutFileName, LPCSTR szSectionName, BOOL HideCmd)*

*BOOL change_icon(LPCSTR szFileName, LPCSTR szIconFileName)*

# Some..
I know, that program is old, code shit, but suddenly it is necessary for someone.
