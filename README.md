# bat2exe
Small tool for generating tiny exe files from bat scripts.

The loader was written on assembler (using masm32).

The main dll was written on C, using WinAPI.

# How to use
Compile c-dll\main.cpp. You will get a dll, it can be used in your project.

Export functions:

*BOOL complie2exe(LPCSTR szFileName, LPCSTR szOutFileName, LPCSTR szSectionName, BOOL HideCmd)*

*BOOL change_icon(LPCSTR szFileName, LPCSTR szIconFileName)*

# Some..
That program is old, but suddenly it is necessary for someone. Totally not recommended for using in production.
