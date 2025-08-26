unit Grammar.LexicalInventory;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.JSON,
  System.Classes;

type

  TLexicalInventory = class
  private
    fTokens:TDictionary<string, Boolean>;
    fKeywords:TDictionary<string, Boolean>;
    fPunct:TDictionary<string, Boolean>;
    function ExtractStringArray(const Arr:TJSONArray):TArray<string>;
    procedure AddStringsToDict(const Items:TArray<string>; D:TDictionary<string, Boolean>; Lower:Boolean);
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile(const Path:string);
    function HasToken(const Name:string):Boolean;
    //for future use: T001 “Unknown terminal literal
    function HasKeywordLiteral(const Lit:string):Boolean;
    function HasPunct(const Lit:string):Boolean;
  end;

implementation

uses
  System.IOUtils;


constructor TLexicalInventory.Create;
begin
  inherited;
  fTokens := TDictionary<string, Boolean>.Create;
  fKeywords := TDictionary<string, Boolean>.Create;
  fPunct := TDictionary<string, Boolean>.Create;
end;


destructor TLexicalInventory.Destroy;
begin
  fTokens.Free;
  fKeywords.Free;
  fPunct.Free;
  inherited;
end;


function TLexicalInventory.ExtractStringArray(const Arr:TJSONArray):TArray<string>;
var
  tmp:TList<string>;
  v:TJSONValue;
  nameVal:TJSONValue;
begin
  tmp := TList<string>.Create;
  try
    for v in Arr do
    begin
      if v is TJSONString then
        tmp.Add((v as TJSONString).Value)
      else if v is TJSONObject then
      begin
        nameVal := (v as TJSONObject).Values['name'];
        if (nameVal <> nil) and (nameVal is TJSONString) then
          tmp.Add((nameVal as TJSONString).Value);
      end;
    end;
    Result := tmp.ToArray;
  finally
    tmp.Free;
  end;
end;


procedure TLexicalInventory.AddStringsToDict(const Items:TArray<string>; D:TDictionary<string, Boolean>; Lower:Boolean);
var
  s:string;
  key:string;
begin
  for s in Items do
  begin
    key := s;
    if Lower then
      key := key.ToLower;
    if not D.ContainsKey(key) then
      D.Add(key, True);
  end;
end;


procedure TLexicalInventory.LoadFromFile(const Path:string);
var
  s:string;
  JO:TJSONObject;

  function GetArray(J:TJSONValue):TJSONArray;
  begin
    if J is TJSONArray then
      Result := TJSONArray(J)
    else
      Result := nil;
  end;

  procedure LoadTokens;
  var
    vTokens, vNames:TJSONValue;
    Arr:TJSONArray;
  begin
    vTokens := JO.Values['tokens'];
    if vTokens = nil then
      Exit;

    // Case 1: tokens is a flat array
    Arr := GetArray(vTokens);
    if Arr <> nil then
    begin
      AddStringsToDict(ExtractStringArray(Arr), FTokens, False);
      Exit;
    end;

    // Case 2: tokens is an object with "names": [...]
    if vTokens is TJSONObject then
    begin
      vNames := TJSONObject(vTokens).Values['names'];
      Arr := GetArray(vNames);
      if Arr <> nil then
        AddStringsToDict(ExtractStringArray(Arr), FTokens, False);
      // else: no explicit names; nothing to do (we don't auto-derive names)
    end;
  end;

  procedure LoadKeywords;
  var
    vKw:TJSONValue;
    Arr:TJSONArray;
    obj:TJSONObject;
    p:TJSONPair;
  begin
    vKw := JO.Values['keywords'];
    if vKw = nil then
      Exit;

    // Accept either a flat array or nested object of arrays
    Arr := GetArray(vKw);
    if Arr <> nil then
    begin
      AddStringsToDict(ExtractStringArray(Arr), FKeywords, True);
      Exit;
    end;

    if vKw is TJSONObject then
    begin
      obj := TJSONObject(vKw);
      for p in obj do
        if p.JsonValue is TJSONArray then
          AddStringsToDict(ExtractStringArray(TJSONArray(p.JsonValue)), FKeywords, True);
    end;
  end;

  procedure LoadPunctuators;
  var
    Arr:TJSONArray;
  begin
    Arr := GetArray(JO.Values['punctuators']);
    if Arr <> nil then
      AddStringsToDict(ExtractStringArray(Arr), FPunct, False);
  end;


begin
  s := TFile.ReadAllText(Path, TEncoding.UTF8);
  JO := TJSONObject(TJSONObject.ParseJSONValue(s));
  if JO = nil then
    raise Exception.Create('Invalid JSON in ' + Path);
  try
    LoadTokens;
    LoadKeywords;
    LoadPunctuators;
  finally
    JO.Free;
  end;
end;


function TLexicalInventory.HasKeywordLiteral(const Lit:string):Boolean;
begin
  Result := FKeywords.ContainsKey(Lit.ToLower);
end;


function TLexicalInventory.HasPunct(const Lit:string):Boolean;
begin
  Result := FPunct.ContainsKey(Lit);
end;


function TLexicalInventory.HasToken(const Name:string):Boolean;
begin
  Result := FTokens.ContainsKey(name);
end;

end.
