unit UDiff;

interface

function BuildSimpleDiff(const A, B, AName, BName:string):string;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Math;


function SplitLines(const S:string):TArray<string>;
begin
  Result := S.Replace(#13#10, #10).Replace(#13, #10).Split([#10]);
end;


function BuildSimpleDiff(const A, B, AName, BName:string):string;
var
  LA, LB:TArray<string>;
  i, maxLen:Integer;
  outLines:TList<string>;
  sa, sb:string;
begin
  LA := SplitLines(A);
  LB := SplitLines(B);
  maxLen := Max(Length(LA), Length(LB));
  outLines := TList<string>.Create;
  try
    outLines.Add('--- ' + AName);
    outLines.Add('+++ ' + BName);
    for i := 0 to maxLen - 1 do
    begin
      sa := '';
      sb := '';
      if i < Length(LA) then
        sa := LA[i];
      if i < Length(LB) then
        sb := LB[i];
      if sa <> sb then
      begin
        outLines.Add(Format('@@ line %d @@', [i + 1]));
        outLines.Add('- ' + sa);
        outLines.Add('+ ' + sb);
      end;
    end;
    Result := string.Join(sLineBreak, outLines.ToArray);
  finally
    outLines.Free;
  end;
end;

end.
