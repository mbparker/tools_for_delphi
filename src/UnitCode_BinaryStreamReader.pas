unit UnitCode_BinaryStreamReader;

interface

uses
  WinApi.Windows, System.SysUtils, System.Classes;

type
  TByteOrdering = (AsStored, Reversed);

  TBinaryStreamReader = class
  strict private
    fOwnsStream: boolean;
    fStream: TStream;

    function GetEof: boolean;
  strict protected
    function IncPtr(APtr: Pointer; AOffset: Cardinal): Pointer;
    procedure ReverseByteOrder(AData: pointer; ASize: cardinal);
    function ReverseStringWide(const AText: string): string;
    procedure CheckedRead(var ABuff; ASize: integer; AByteOrder: TByteOrdering);

    property Stream: TStream read fStream;
  public
    constructor Create(AStream: TStream; AOwnsStream: boolean = True);
    destructor Destroy; override;

    function ReadBool(AByteOrder: TByteOrdering = AsStored): BOOL; virtual;
    function ReadByte: byte; virtual;
    function ReadBytes(ACount: integer; AByteOrder: TByteOrdering = AsStored): TBytes; virtual;
    function ReadCardinal(AByteOrder: TByteOrdering = AsStored): cardinal; virtual;
    function ReadInt64(AByteOrder: TByteOrdering = AsStored): Int64; virtual;
    function ReadInteger(AByteOrder: TByteOrdering = AsStored): integer; virtual;
    function ReadSingle(AByteOrder: TByteOrdering = AsStored): single; virtual;
    function ReadSmallInt(AByteOrder: TByteOrdering = AsStored): SmallInt; virtual;
    function ReadString(ACount: integer; AByteOrder: TByteOrdering = AsStored): AnsiString; virtual;
    function ReadStringWide(ACount, ADivideCountBy: integer; AByteOrder: TByteOrdering = AsStored): string; virtual;
    function ReadUInt24(AByteOrder: TByteOrdering = AsStored): cardinal; virtual;
    function ReadUInt64(AByteOrder: TByteOrdering = AsStored): UInt64; virtual;
    function ReadWord(AByteOrder: TByteOrdering = AsStored): word; virtual;

    property Eof: boolean read GetEof;
  end;

implementation

{ TBinaryStreamReader }

procedure TBinaryStreamReader.CheckedRead(var ABuff; ASize: integer;
  AByteOrder: TByteOrdering);
begin
  ZeroMemory(@ABuff, ASize);
  if EOF then
    Exit;
  if (Stream.Read(ABuff, ASize) = ASize) and (AByteOrder = Reversed) then
    ReverseByteOrder(@ABuff, ASize);
end;

constructor TBinaryStreamReader.Create(AStream: TStream; AOwnsStream: boolean);
begin
  inherited Create;
  fStream := AStream;
  fOwnsStream := AOwnsStream;
end;

destructor TBinaryStreamReader.Destroy;
begin
  if fOwnsStream then
    FreeAndNil(fStream);
  inherited;
end;

function TBinaryStreamReader.GetEof: boolean;
begin
  Result := Stream.Position = Stream.Size;
end;

function TBinaryStreamReader.IncPtr(APtr: Pointer; AOffset: Cardinal): Pointer;
begin
  Result := Pointer(Cardinal(APtr) + AOffset);
end;

function TBinaryStreamReader.ReadBool(AByteOrder: TByteOrdering): BOOL;
begin
  CheckedRead(Result, SizeOf(Result), AByteOrder);
end;

function TBinaryStreamReader.ReadByte: byte;
begin
  CheckedRead(Result, SizeOf(Result), AsStored);
end;

function TBinaryStreamReader.ReadBytes(ACount: integer;
  AByteOrder: TByteOrdering): TBytes;
begin
  if ACount > 0 then
  begin
    SetLength(Result, ACount);
    CheckedRead(PByte(Result)^, ACount, AByteOrder);
  end
  else
    SetLength(Result, 0);
end;

function TBinaryStreamReader.ReadCardinal(
  AByteOrder: TByteOrdering): cardinal;
begin
  CheckedRead(Result, SizeOf(Result), AByteOrder);
end;

function TBinaryStreamReader.ReadInt64(AByteOrder: TByteOrdering): Int64;
begin
  CheckedRead(Result, SizeOf(Result), AByteOrder);
end;

function TBinaryStreamReader.ReadInteger(AByteOrder: TByteOrdering): integer;
begin
  CheckedRead(Result, SizeOf(Result), AByteOrder);
end;

function TBinaryStreamReader.ReadSingle(AByteOrder: TByteOrdering): single;
begin
  CheckedRead(Result, SizeOf(Result), AByteOrder);
end;

function TBinaryStreamReader.ReadSmallInt(
  AByteOrder: TByteOrdering): SmallInt;
begin
  CheckedRead(Result, SizeOf(Result), AByteOrder);
end;

function TBinaryStreamReader.ReadString(ACount: integer;
  AByteOrder: TByteOrdering): AnsiString;
begin
  SetLength(Result, ACount);
  if ACount = 0 then
    Exit;
  CheckedRead(PAnsiChar(Result)^, ACount, AByteOrder);
end;

function TBinaryStreamReader.ReadStringWide(ACount, ADivideCountBy: integer;
  AByteOrder: TByteOrdering): string;
begin
  SetLength(Result, ACount div ADivideCountBy);
  if ACount = 0 then
    Exit;
  CheckedRead(PChar(Result)^, ACount, AByteOrder);
  if AByteOrder = Reversed then
    Result := ReverseStringWide(Result);
end;

function TBinaryStreamReader.ReadUInt24(AByteOrder: TByteOrdering): cardinal;
begin
  if AByteOrder = Reversed then
    Result := 0 or ReadByte or (ReadByte shl 8) or (ReadByte shl 16)
  else
    Result := 0 or (ReadByte shl 16) or (ReadByte shl 8) or ReadByte;
end;

function TBinaryStreamReader.ReadUInt64(AByteOrder: TByteOrdering): UInt64;
begin
  CheckedRead(Result, SizeOf(Result), AByteOrder);
end;

function TBinaryStreamReader.ReadWord(AByteOrder: TByteOrdering): word;
begin
  CheckedRead(Result, SizeOf(Result), AByteOrder);
end;

procedure TBinaryStreamReader.ReverseByteOrder(AData: pointer; ASize: cardinal);
var
  I: Integer;
  J: Integer;
  lTemp: pointer;
begin
  if ASize < 1 then
    Exit;
  lTemp := AllocMem(ASize);
  try
    CopyMemory(lTemp, AData, ASize);
    J := ASize-1;
    for I := 0 to ASize-1 do
    begin
      CopyMemory(IncPtr(AData, I), IncPtr(lTemp, J), 1);
      Dec(J);
    end;
  finally
    FreeMem(lTemp);
  end;
end;

function TBinaryStreamReader.ReverseStringWide(const AText: string): string;
var
  I: Integer;
  P: PChar;
begin
  SetLength(Result, Length(AText));
  P := PChar(Result);
  for I := Length(AText) downto 1 do
  begin
    P^ := AText[I];
    Inc(P);
  end;
end;

end.
