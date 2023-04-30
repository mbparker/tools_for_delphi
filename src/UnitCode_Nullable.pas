unit UnitCode_Nullable;

interface

type
  TNullable<T> = record
  private
    fHasValue: boolean;
    fValue: T;
    function GetValue: T;
    procedure SetValue(const AValue: T);
  public
    class operator Initialize(out ADest: TNullable<T>);
    property HasValue: boolean read fHasValue;
    property Value: T read GetValue write SetValue;
  end;

implementation

uses
  System.SysUtils;

class operator TNullable<T>.Initialize(out ADest: TNullable<T>);
begin
  ADest.fHasValue := False;
end;

function TNullable<T>.GetValue: T;
begin
  if fHasValue then
    Result := fValue
  else
    raise Exception.Create('Nullable type value is nil.');
end;

procedure TNullable<T>.SetValue(const AValue: T);
begin
  fHasValue := True;
  fValue := AValue;
end;

end.
