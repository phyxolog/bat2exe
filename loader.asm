;; (c) 2008

.386
.model flat, stdcall
option casemap: none

include \masm32\include\windows.inc
include \masm32\macros\macros.asm
uselib kernel32, user32, masm32, shell32

MainProc PROTO
create_process PROTO :DWORD, :DWORD, :DWORD, :DWORD

.data
szBatExt db "bat", 0h
pBuffer dd 0
tmp dd 0
PeSection IMAGE_SECTION_HEADER <>

.data?
hFile dd ?
hBatFile dd ?
szBatFileName dd ?
szMyCmdLine dd ?
szExePath dd ?
DosHeader IMAGE_DOS_HEADER <?>
NtHeader IMAGE_NT_HEADERS <?>
StartInfo STARTUPINFO <?>
ProcInfo PROCESS_INFORMATION <?>

.code

MAIN:
	invoke MainProc
	jmp THEEND
	
	MainProc proc		
		;;get full path to my exe
		invoke GetModuleFileName, 0, addr szExePath, MAX_PATH

		;;open my exe
		invoke CreateFile, addr szExePath, GENERIC_READ, 0, 0, OPEN_EXISTING, 0, 0
		mov hFile, eax
		
		;;check for errors
		.IF hFile == INVALID_HANDLE_VALUE	
			invoke MessageBox, 0, chr$('[X] Error opening exe file!'), chr$('bat2exe ldr'), MB_OK + MB_ICONERROR
			invoke CloseHandle, hFile
			ret
		.ENDIF
		
		;;read dos header
		invoke ReadFile, hFile, addr DosHeader, sizeof IMAGE_DOS_HEADER, addr tmp, NULL
		.IF eax == FALSE
			invoke MessageBox, 0, chr$('[X] Error reading DosHeader from exe file!'), chr$('bat2exe ldr'), MB_OK + MB_ICONERROR
			invoke CloseHandle, hFile
			ret
		.ENDIF
		
		invoke SetFilePointer, hFile, DosHeader.e_lfanew, NULL, FILE_BEGIN ;;pointer of nt header (указатель на структуру nt header)
		invoke ReadFile, hFile, addr NtHeader, sizeof IMAGE_NT_HEADERS , addr tmp, NULL	;;read nt header
		.IF eax == FALSE
			invoke MessageBox, 0, chr$('[X] Error reading NtHeader from exe file!'), chr$('bat2exe ldr'), MB_OK + MB_ICONERROR
			invoke CloseHandle, hFile
			ret
		.ENDIF
		
		;;read last of sections
		xor edi, edi
		add esi, DosHeader.e_lfanew
		add esi, sizeof IMAGE_NT_HEADERS
		movsx eax, NtHeader.FileHeader.NumberOfSections
		dec ax
		mov ebx, sizeof IMAGE_SECTION_HEADER
		mul ebx
		add edi, eax		
		invoke SetFilePointer, hFile, EDI, NULL, FILE_BEGIN
		invoke ReadFile, hFile, addr PeSection, sizeof IMAGE_SECTION_HEADER, addr tmp, NULL
		.IF eax == FALSE
			invoke MessageBox, 0, chr$('[X] Error reading section header from exe file!'), chr$('bat2exe ldr'), MB_OK + MB_ICONERROR
			invoke CloseHandle, hFile
			ret
		.ENDIF
		
		;;PeSection - pointer of last pe section
		;;PeSection.Misc.VirtualSize - bat file size
		;;PeSection.PointerToRawData - bat file offset
		
		;;create global buff.
		invoke GlobalAlloc, GMEM_ZEROINIT or GMEM_FIXED, PeSection.Misc.VirtualSize
		mov pBuffer, eax
		
		;;read data of bat file
		invoke SetFilePointer, hFile, PeSection.PointerToRawData, NULL, FILE_BEGIN
		invoke ReadFile, hFile, pBuffer, PeSection.Misc.VirtualSize, addr tmp, NULL
		.IF eax == FALSE
			invoke MessageBox, 0, chr$('[X] Error reading section data from exe file!'), chr$('bat2exe ldr'), MB_OK + MB_ICONERROR
			invoke CloseHandle, hFile
			ret
		.ENDIF
		
		;;close descriptor of file
		invoke CloseHandle, hFile
		
		;;gen random file name
		invoke GetTickCount
		invoke wsprintf, addr szBatFileName, chr$('%d.%s'), eax, addr szBatExt
		
		;;create bat file
		invoke CreateFile, addr szBatFileName, GENERIC_WRITE, FILE_SHARE_READ, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_HIDDEN, 0
		mov hBatFile, eax
		.IF hBatFile == INVALID_HANDLE_VALUE	
			invoke MessageBox, 0, chr$('[X] Error create bat file!'), chr$('bat2exe ldr'), MB_OK + MB_ICONERROR
			ret
		.ENDIF
		
		;;and write data
		invoke WriteFile, hBatFile, pBuffer, PeSection.Misc.VirtualSize, addr tmp, NULL 
	    	.IF eax == FALSE
			invoke MessageBox, 0, chr$('[X] Error writing data to bat-file!'), chr$('bat2exe ldr'), MB_OK + MB_ICONERROR
			invoke CloseHandle, hBatFile
			ret
		.ENDIF
		
		;;free memory
		invoke GlobalFree, pBuffer
		invoke CloseHandle, hBatFile		
		
		;;execute bat file
		invoke create_process, addr szBatFileName, chr$('.\\'), TRUE, 0
		
		;;delete bat file
		invoke DeleteFile, addr szBatFileName

		;;exit
		ret
	MainProc endp
	
	;;no comment :-)
	create_process proc szCmdLine :DWORD, szDestDir :DWORD, dwShow :DWORD, dwPriority :DWORD
		LOCAL szResult :DWORD, dwWait :DWORD, prt :DWORD
		LOCAL pMsg :MSG
		LOCAL bQuit :BOOL
		
		mov prt, NORMAL_PRIORITY_CLASS
		mov szResult, FALSE
		
		invoke memfill, addr StartInfo, sizeof StartInfo, 0
		invoke memfill, addr ProcInfo, sizeof ProcInfo, 0
		
		mov StartInfo.cb, sizeof StartInfo
		mov StartInfo.dwFlags, STARTF_USESHOWWINDOW + STARTF_USESTDHANDLES

		mov eax, dwShow		
	    	.IF eax == TRUE
			mov StartInfo.wShowWindow, SW_SHOW
		.ELSE
			mov StartInfo.wShowWindow, SW_HIDE
		.ENDIF
		
		mov eax, dwPriority
		.IF eax == -1
			mov prt, IDLE_PRIORITY_CLASS
		.ENDIF
		
		.IF eax == 0
			mov prt, NORMAL_PRIORITY_CLASS
		.ENDIF
		
		.IF eax == 1
			mov prt, REALTIME_PRIORITY_CLASS
		.ENDIF		
		add prt, CREATE_NEW_CONSOLE
		
		invoke CreateProcess, 0, szCmdLine, 0, 0, FALSE, prt, 0, szDestDir, addr StartInfo, addr ProcInfo
		
		.IF eax == TRUE
			mov szResult, TRUE
			mov bQuit, FALSE
			
			invoke WaitForSingleObject, ProcInfo.hProcess, 10
			mov dwWait, eax
			
			.WHILE dwWait != WAIT_OBJECT_0
				invoke WaitForSingleObject, ProcInfo.hProcess, 10
				mov dwWait, eax
				
				.WHILE !(bQuit)
					invoke PeekMessage, addr pMsg, 0, 0, 0, PM_REMOVE
					.IF eax
						.IF (pMsg.message == WM_QUIT)
							mov bQuit, TRUE
						.ELSE
							invoke TranslateMessage, addr pMsg
							invoke DispatchMessage, addr pMsg
						.ENDIF
					.ELSE
						.BREAK
					.ENDIF
				.ENDW				
			.ENDW			
		.ELSE
			mov szResult, FALSE
		.ENDIF
		
		invoke CloseHandle, ProcInfo.hProcess
		invoke CloseHandle, ProcInfo.hThread
		
		mov eax, szResult		
		ret
	create_process endp
	
THEEND:
	invoke ExitProcess, 0

end MAIN
