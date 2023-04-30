unit UnitCode_LibraryExportsEnumerator;

interface

uses
  System.Classes;

type
  TDumpLibraryExportsResultCode = (Ok, CannotOpenFile, CannotMapImage, CannotMapView, CannotReadPEHeader, InvalidFileSignature,
    CannotReadExports, CannotReadExportNames, ExceptionRaised);

  TDumpLibraryExportNamesResult = record
    ResultCode: TDumpLibraryExportsResultCode;
    Names: TStrings;
    ExceptionInstance: TObject;
  end;

  TLibraryExportsEnumerator = class
  public
    class function DumpLibraryExportNames(const AImageName: string; ANamesList: TStrings): TDumpLibraryExportNamesResult;
  end;

implementation

uses
  WinApi.Windows;

type
  PIMAGE_NT_HEADERS = ^IMAGE_NT_HEADERS;
  PIMAGE_EXPORT_DIRECTORY = ^IMAGE_EXPORT_DIRECTORY;

function ImageNtHeader(Base: Pointer): PIMAGE_NT_HEADERS; stdcall; external 'dbghelp.dll';
function ImageRvaToVa(NtHeaders: Pointer; Base: Pointer; Rva: ULONG; LastRvaSection: Pointer): Pointer; stdcall; external 'dbghelp.dll';

class function TLibraryExportsEnumerator.DumpLibraryExportNames(const AImageName: string; ANamesList: TStrings): TDumpLibraryExportNamesResult;
var
  i: Integer;
  lFileHandle: THandle;
  lImageHandle: THandle;
  lImagePointer: Pointer;
  lHeader: PIMAGE_NT_HEADERS;
  lExportTable: PIMAGE_EXPORT_DIRECTORY;
  lNamesPtr: PCardinal;
  lNamePtr: PAnsiChar;
begin
  Result.ResultCode := TDumpLibraryExportsResultCode.Ok;
  Result.Names := ANamesList;
  ANamesList.Clear;
  try
    lFileHandle := CreateFile(PChar(AImageName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if lFileHandle = INVALID_HANDLE_VALUE then
    begin
      Result.ResultCode := TDumpLibraryExportsResultCode.CannotOpenFile;
      Exit;
    end;
    try
      lImageHandle := CreateFileMapping(lFileHandle, nil, PAGE_READONLY, 0, 0, nil);
      if lImageHandle = 0 then
      begin
        Result.ResultCode := TDumpLibraryExportsResultCode.CannotMapImage;
        Exit;
      end;
      try
        lImagePointer := MapViewOfFile(lImageHandle, FILE_MAP_READ, 0, 0, 0);
        if not Assigned(lImagePointer) then
        begin
          Result.ResultCode := TDumpLibraryExportsResultCode.CannotMapView;
          Exit;
        end;

        try
          lHeader := ImageNtHeader(lImagePointer);
          if not Assigned(lHeader) then
          begin
            Result.ResultCode := TDumpLibraryExportsResultCode.CannotReadPEHeader;
            Exit;
          end;

          if lHeader.Signature <> $00004550 then
          begin
            Result.ResultCode := TDumpLibraryExportsResultCode.InvalidFileSignature;
            Exit;
          end;

          lExportTable := ImageRvaToVa(lHeader, lImagePointer, lHeader.OptionalHeader.DataDirectory[0].VirtualAddress, nil);
          if not Assigned(lExportTable) then
          begin
            Result.ResultCode := TDumpLibraryExportsResultCode.CannotReadExports;
            Exit;
          end;

          lNamesPtr := ImageRvaToVa(lHeader, lImagePointer, Cardinal(lExportTable.AddressOfNames), nil);
          if not Assigned(lNamesPtr) then
          begin
            Result.ResultCode := TDumpLibraryExportsResultCode.CannotReadExportNames;
            Exit;
          end;

          for i := 1 to lExportTable.NumberOfNames do
          begin
            lNamePtr := ImageRvaToVa(lHeader, lImagePointer, lNamesPtr^, nil);
            if not Assigned(lNamePtr) then
            begin
              Exit;
            end;

            ANamesList.Add(UTF8ToUnicodeString(lNamePtr));
            Inc(lNamesPtr);
          end;
        finally
          UnmapViewOfFile(lImagePointer);
        End;
      finally
        CloseHandle(lImageHandle);
      end;
    finally
      CloseHandle(lFileHandle);
    end;
  except
    Result.ResultCode := TDumpLibraryExportsResultCode.ExceptionRaised;
    Result.ExceptionInstance := AcquireExceptionObject;
  end;
end;

end.
