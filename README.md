# bat2exe

**bat2exe** is a lightweight tool designed to convert batch (.bat) scripts into executable (.exe) files.

The tool consists of two main components:
- **Loader**: Written in Assembly using MASM32.
- **Main DLL**: Developed in C, utilizing the WinAPI.

## How to use
1. Compile `c-dll/main.cpp` to generate the DLL file. This DLL can then be integrated into your project.
2. The DLL provides the following functions:

```c
BOOL complie2exe(LPCSTR szFileName, LPCSTR szOutFileName, LPCSTR szSectionName, BOOL HideCmd)
BOOL change_icon(LPCSTR szFileName, LPCSTR szIconFileName)
```

## Note
This program is outdated but might still be useful in certain scenarios.
