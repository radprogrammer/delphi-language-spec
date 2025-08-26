unit UFileUtil;

interface

uses
  System.SysUtils,
  System.Classes;

type

  TFileUtil = class
  public
    class function ReadAllText(const Path:string):string; static;
    class function NormalizeText(const S:string):string; static;
  end;


implementation

uses
  System.IOUtils;


class function TFileUtil.ReadAllText(const Path:string):string;
var
  Bytes:TBytes;
begin
  Bytes := TFile.ReadAllBytes(Path);
  // Assume UTF-8 with or without BOM
  Result := TEncoding.UTF8.GetString(Bytes);
end;


class function TFileUtil.NormalizeText(const S:string):string;
var
  R:string;
  i:Integer;
  Lines:TArray<string>;
begin
  R := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  R := StringReplace(R, #13, #10, [rfReplaceAll]);
  // trim trailing spaces on each line
  Lines := R.Split([#10]);
  for i := 0 to high(Lines) do
  begin
    Lines[i] := Lines[i].TrimRight;
  end;
  Result := string.Join(#10, Lines);
  // final trailing newline normalized
  if (Result <> '') and (not Result.EndsWith(#10)) then
  begin
    Result := Result + #10;
  end;
end;

end.
