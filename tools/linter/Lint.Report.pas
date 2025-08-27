unit Lint.Report;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Lint.Issues;


type

  TLintReport = Class
    class procedure OutputText(const Issues:TObjectList<TLintIssue>);
    class procedure OutputJson(const StartSymbol:string; const Issues:TObjectList<TLintIssue>);
  End;


implementation

uses
  System.JSON,
  System.StrUtils;


class procedure TLintReport.OutputText(const Issues:TObjectList<TLintIssue>);
var
  Errs, Warns:Integer;
  sev,loc:string;
  it:TLintIssue;
begin
  Errs := 0;
  Warns := 0;
  Writeln('Delphi EBNF Lint Results');
  for it in Issues do
  begin
    sev := IfThen(it.Severity = lsError, 'error', 'warn');
    loc := '';
    if it.Line > 0 then
      loc := Format(' (line %d)', [it.Line]);
    Writeln(Format('%s: %s %s: %s%s', [it.Code, sev, '', it.Message, loc]));
    if it.Extra <> '' then
    begin
      Writeln('  ---');
      Writeln(it.Extra);
    end;
    if it.Severity = lsError then
      Inc(Errs)
    else
      Inc(Warns);
  end;
  Writeln(Format('Summary: %d error(s), %d warning(s)', [Errs, Warns]));
end;


class procedure TLintReport.OutputJson(const StartSymbol:string; const Issues:TObjectList<TLintIssue>);
var
  root:TJSONObject;
  arr:TJSONArray;
  o:TJSONObject;
  s:string;
  it:TLintIssue;
begin
  root := TJSONObject.Create;
  try
    root.AddPair('start', StartSymbol);
    arr := TJSONArray.Create;
    root.AddPair('issues', arr);
    for it in Issues do
    begin
      o := TJSONObject.Create;
      o.AddPair('code', it.Code);
      o.AddPair('severity', IfThen(it.Severity = lsError, 'error', 'warning'));
      o.AddPair('message', it.Message);
      if it.Line > 0 then
        o.AddPair('line', TJSONNumber.Create(it.Line));
      if it.Col > 0 then
        o.AddPair('col', TJSONNumber.Create(it.Col));
      if it.Extra <> '' then
        o.AddPair('extra', it.Extra);
      arr.AddElement(o);
    end;
    s := root.ToJSON;
    Writeln(s);
  finally
    root.Free;
  end;
end;

end.
