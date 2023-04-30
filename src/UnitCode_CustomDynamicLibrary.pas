unit UnitCode_CustomDynamicLibrary;

interface

uses
  System.Classes, WinApi.Windows, System.SysUtils;

type
  ELibraryNotFound = class(Exception)
  public
    constructor Create(const ALibraryFilename: string);
  end;

  ERoutineNotFound = class(Exception)
  strict private
    fFoundExports: TStrings;
  public
    constructor Create(const ALibraryFilename, ARoutineName: string; AFoundExports: TStrings);
    destructor Destroy; override;

    property FoundExports: TStrings read fFoundExports;
  end;

  TCustomDynamicLibrary = class abstract
  strict private
    fLibraryFilename: string;
    fLibraryHandle: THandle;

    procedure Deinitialize;
    procedure Initialize;
    procedure RaiseRoutineNotFound(const AName: string);
  strict protected
    procedure LibraryNeeded;
    procedure MapRoutine(const AName: string; const ARoutine: PPointer);
    procedure MapRoutines; virtual; abstract;
    procedure RaiseLibraryNotFound;
  public
    constructor Create(const ALibraryFilename: string);
    destructor Destroy; override;

    procedure EnsureLoaded;
  end;

implementation

uses
  UnitCode_LibraryExportsEnumerator;

resourcestring
  LibraryNotFound = 'Library %s was not found';
  RoutineNotFound = '%s was not found in library %s';


{ ELibraryNotFound }

constructor ELibraryNotFound.Create(const ALibraryFilename: string);
begin
  inherited CreateFmt(LibraryNotFound, [ALibraryFilename]);
end;

{ ERoutineNotFound }

constructor ERoutineNotFound.Create(const ALibraryFilename,
  ARoutineName: string; AFoundExports: TStrings);
begin
  inherited CreateFmt(RoutineNotFound, [ARoutineName, ALibraryFilename]);
  fFoundExports := AFoundExports;
end;

destructor ERoutineNotFound.Destroy;
begin
  FreeAndNil(fFoundExports);
end;

{ TCustomDynamicLibrary }

constructor TCustomDynamicLibrary.Create(const ALibraryFilename: string);
begin
  inherited Create;
  fLibraryFilename := ALibraryFilename;
end;

procedure TCustomDynamicLibrary.Deinitialize;
begin
  if fLibraryHandle <> 0 then
  begin
    FreeLibrary(fLibraryHandle);
    fLibraryHandle := 0;
  end;
end;

destructor TCustomDynamicLibrary.Destroy;
begin
  Deinitialize;
  inherited;
end;

procedure TCustomDynamicLibrary.EnsureLoaded;
begin
  LibraryNeeded;
end;

procedure TCustomDynamicLibrary.Initialize;
begin
  fLibraryHandle := LoadLibrary(PWChar(fLibraryFilename));
  if fLibraryHandle = 0 then
  begin
    try
      RaiseLastOSError;
    except
      on E: Exception do
      begin
        E.Message := Format('[%s] %s', [fLibraryFilename, E.Message]);
        raise;
      end;
    end;
  end;
  MapRoutines;
end;

procedure TCustomDynamicLibrary.LibraryNeeded;
begin
  if fLibraryHandle = 0 then
    Initialize;
end;

procedure TCustomDynamicLibrary.MapRoutine(const AName: string;
  const ARoutine: PPointer);
begin
  ARoutine^ := GetProcAddress(fLibraryHandle, PWChar(AName));
  if ARoutine^ = nil then
    RaiseRoutineNotFound(AName);
end;

procedure TCustomDynamicLibrary.RaiseLibraryNotFound;
begin
  raise ELibraryNotFound.Create(fLibraryFilename);
end;

procedure TCustomDynamicLibrary.RaiseRoutineNotFound(const AName: string);
begin
  raise ERoutineNotFound.Create(fLibraryFilename, AName,
    TLibraryExportsEnumerator.DumpLibraryExportNames(fLibraryFilename, TStringList.Create).Names);
end;

end.
