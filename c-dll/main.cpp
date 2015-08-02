#include "main.h"

BOOL change_icon(LPCSTR szFileName, LPCSTR szIconFileName)
{
	HANDLE hWhere = BeginUpdateResource(szFileName, FALSE);
	if (hWhere == NULL)
		return FALSE;
	
	char *buffer;
	long buffersize;
	int hFile;
	
	hFile = open(szIconFileName, O_RDONLY | O_BINARY);
	if (hFile == -1)
		return FALSE;
	
	buffersize = filelength(hFile);
	buffer = (char*)malloc(buffersize);
	read(hFile, buffer, buffersize);
	close(hFile);
	
	if (!UpdateResource(hWhere, RT_ICON,MAKEINTRESOURCE(1), MAKELANGID(LANG_ENGLISH, SUBLANG_DEFAULT), (buffer + 22), buffersize - 22))
		return FALSE;
	
	GROUPICON grData;
	
	grData.Reserved1 = 0;
	grData.ResourceType = 1;
	grData.ImageCount = 1;
	grData.Width = 32;
	grData.Height = 32;
	grData.Colors = 0;
	grData.Reserved2 = 0;
	grData.Planes = 2;
	grData.BitsPerPixel = 32;
	grData.ImageSize = buffersize - 22;
	grData.ResourceID = 1;
	
	if (!UpdateResource(hWhere, RT_GROUP_ICON, "MAINICON", MAKELANGID(LANG_ENGLISH, SUBLANG_DEFAULT), &grData, sizeof(GROUPICON)))
		return FALSE;
	
	delete[] buffer;
	
	if (!EndUpdateResource(hWhere, FALSE))
		return FALSE;
	
	return TRUE;
}

BOOL complie2exe(LPCSTR szFileName, LPCSTR szOutFileName, LPCSTR szSectionName, BOOL HideCmd)
{
	LPBYTE pBatData;
	DWORD BatFileSize;
	DWORD PeFileSize = LdrData_size;
	DWORD tmp;
	PIMAGE_DOS_HEADER DOSHeader;
	PIMAGE_NT_HEADERS32 NtHeader32;
	PIMAGE_SECTION_HEADER PESection;
	
	LPBYTE LoaderData = (LPBYTE)malloc(LdrData_size);
	memcpy(LoaderData, LdrData, LdrData_size);
	
	HANDLE hBatFile = CreateFileA(szFileName, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, 0, 0);
	if (hBatFile == INVALID_HANDLE_VALUE)
		return FALSE;
	
	BatFileSize = GetFileSize(hBatFile, NULL);
	if (BatFileSize == 0)
		return FALSE;
	
	pBatData = (LPBYTE)malloc(BatFileSize);
	if (!ReadFile(hBatFile, pBatData, BatFileSize, &tmp, 0))
		return FALSE;
	
	CloseHandle(hBatFile);
	
	if (HideCmd)
		LoaderData[0x6B2] = 0x00;

	DOSHeader = (PIMAGE_DOS_HEADER)LoaderData;
	NtHeader32 = (PIMAGE_NT_HEADERS32)(LoaderData + DOSHeader->e_lfanew);
	PESection = (PIMAGE_SECTION_HEADER)((LPBYTE)&(NtHeader32->OptionalHeader) + NtHeader32->FileHeader.SizeOfOptionalHeader);
	
	DWORD i = NtHeader32->FileHeader.NumberOfSections;
	
	DWORD NewVA = PESection[NtHeader32->FileHeader.NumberOfSections - 1].VirtualAddress + PESection[NtHeader32->FileHeader.NumberOfSections - 1].Misc.VirtualSize;
	NewVA = AlignSize(NewVA, NtHeader32->OptionalHeader.SectionAlignment);
	NewVA += NtHeader32->OptionalHeader.ImageBase;
	
	DWORD NewOffset = PESection[NtHeader32->FileHeader.NumberOfSections - 1].PointerToRawData + PESection[NtHeader32->FileHeader.NumberOfSections - 1].SizeOfRawData;
	NewOffset = AlignSize(NewOffset, NtHeader32->OptionalHeader.FileAlignment);
	
	DWORD NewSize = AlignSize(BatFileSize, NtHeader32->OptionalHeader.SectionAlignment);
	
	CopyMemory(&PESection[i].Name, szSectionName, 8);
	PESection[i].Misc.VirtualSize = BatFileSize;
	PESection[i].VirtualAddress = NewVA - NtHeader32->OptionalHeader.ImageBase;
	PESection[i].SizeOfRawData = BatFileSize;
	PESection[i].PointerToRawData = NewOffset;
	PESection[i].Characteristics = IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE;
	NtHeader32->FileHeader.NumberOfSections++;
	NtHeader32->OptionalHeader.SizeOfImage += NewSize;
	PeFileSize += NtHeader32->OptionalHeader.FileAlignment;
	
	HANDLE hFile = CreateFileA(szOutFileName, GENERIC_READ + GENERIC_WRITE, FILE_SHARE_READ, 0, CREATE_ALWAYS, 0, 0);
	if (hFile == INVALID_HANDLE_VALUE)
	return FALSE;

	SetFilePointer(hFile, 0, NULL, FILE_BEGIN);
	if (!WriteFile(hFile, LoaderData, PeFileSize, &tmp, 0))
		return FALSE;
	
	SetFilePointer(hFile, NewOffset, NULL, FILE_BEGIN);
	if (!WriteFile(hFile, pBatData, BatFileSize, &tmp, 0))
		return FALSE;
	
	CloseHandle(hFile);
	return TRUE;
}

extern "C" DLL_EXPORT BOOL APIENTRY DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    switch (fdwReason)
    {
        case DLL_PROCESS_ATTACH:
            // attach to process
            // return FALSE to fail DLL load
            break;

        case DLL_PROCESS_DETACH:
            // detach from process
            break;

        case DLL_THREAD_ATTACH:
            // attach to thread
            break;

        case DLL_THREAD_DETACH:
            // detach from thread
            break;
    }
    return TRUE; // succesful
}
