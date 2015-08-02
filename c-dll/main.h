#ifndef __MAIN_H__
#define __MAIN_H__

#include <windows.h>
#include <io.h>
#include <fcntl.h>

#include "ldr.h"

#define AlignSize( dwSize, dwAlign ) (dwSize + (dwAlign - ((dwSize % dwAlign) ? (dwSize % dwAlign) : dwAlign)))

#pragma pack(push, 2)
typedef struct {
  WORD Reserved1;
  WORD ResourceType;
  WORD ImageCount;
  BYTE Width;
  BYTE Height;
  BYTE Colors;
  BYTE Reserved2;
  WORD Planes;
  WORD BitsPerPixel;
  DWORD ImageSize;
  WORD ResourceID;
} GROUPICON;
#pragma pack(pop)

#ifdef BUILD_DLL
    #define DLL_EXPORT __declspec(dllexport)
#else
    #define DLL_EXPORT __declspec(dllimport)
#endif


#ifdef __cplusplus
extern "C"
{
#endif

BOOL DLL_EXPORT change_icon(LPCSTR szFileName, LPCSTR szIconFileName);
BOOL DLL_EXPORT complie2exe(LPCSTR szFileName, LPCSTR szOutFileName, LPCSTR szSectionName, BOOL HideCmd);

#ifdef __cplusplus
}
#endif

#endif // __MAIN_H__
