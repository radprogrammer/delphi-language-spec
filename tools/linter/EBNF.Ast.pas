unit EBNF.Ast;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TNodeKind = (nkChoice, nkSeq, nkSuffix, nkGroup, nkOptional, nkRepeat, nkTerminal, nkIdentRef);
  TSuffixKind = (skNone, skOpt, skStar, skPlus);


  TNode = class
  private
    fKind:TNodeKind;
    fLine:Integer;
    fCol:Integer;
  public
    property Kind:TNodeKind read fKind write fKind;
    property Line:Integer read fLine write fLine;
    property Col:Integer read fCol write fCol;
  end;


  TNodeList = class(TObjectList<TNode>);


  TTerminalNode = class(TNode)
  private
    fText:string; // quoted literal content without quotes
  public
    property Text:string read fText write fText;
  end;


  TIdentRefNode = class(TNode)
  private
    fName:string; // may be token or nonterminal; resolved later
  public
    property Name:string read fName write fName;
  end;


  TSeqNode = class(TNode)
  private
    fItems:TNodeList;
  public
    constructor Create;
    destructor Destroy; override;

    property Items:TNodeList read fItems write fItems;
  end;


  TChoiceNode = class(TNode)
  private
    fAlts:TNodeList;
  public
    constructor Create;
    destructor Destroy; override;

    property Alts:TNodeList read fAlts write fAlts;
  end;


  TSuffixNode = class(TNode)
  public
    Base:TNode;
    Suffix:TSuffixKind;
  end;


  TGroupNode = class(TNode)
  public
    Inner:TNode;
  end;


  TOptNode = class(TNode)
  public
    Inner:TNode;
  end;


  TRepeatNode = class(TNode)
  public
    Inner:TNode;
  end;


  TProduction = class
  public
    Name:string;
    Expr:TNode;
    Line:Integer;
  end;


  TGrammar = class
  private
    fProds:TObjectList<TProduction>;
  public
    constructor Create;
    destructor Destroy; override;

    function FindProd(const Name:string):TProduction;

    property Prods:TObjectList<TProduction> read fProds write fProds;
  end;

implementation


constructor TSeqNode.Create;
begin
  inherited;
  fKind := nkSeq;
  fItems := TNodeList.Create(True);
end;


destructor TSeqNode.Destroy;
begin
  fItems.Free;
  inherited;
end;


constructor TChoiceNode.Create;
begin
  inherited;
  fKind := nkChoice;
  fAlts := TNodeList.Create(True);
end;


destructor TChoiceNode.Destroy;
begin
  fAlts.Free;
  inherited;
end;


constructor TGrammar.Create;
begin
  inherited;
  fProds := TObjectList<TProduction>.Create(True);
end;


destructor TGrammar.Destroy;
begin
  fProds.Free;
  inherited;
end;


function TGrammar.FindProd(const Name:string):TProduction;
var
  p:TProduction;
begin
  for p in Prods do
  begin
    if SameText(p.Name, name) then
    begin
      Exit(p);
    end;
  end;
  Result := nil;
end;

end.
