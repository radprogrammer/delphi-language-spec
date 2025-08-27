unit Lint.Issues;

interface


type

  TLintSeverity = (lsWarning, lsError);

  TLintIssue = class
  private
    fCode:string;
    fSeverity:TLintSeverity;
    fMessage:string;
    fLine:Integer;
    fCol:Integer;
    fExtra:string; // optional payload (e.g., diff)
  public
    constructor Create(const ACode:string; ASeverity:TLintSeverity; const AMessage:string; ALine, ACol:Integer; const AExtra:string = '');

    property Code:string read fCode write fCode;
    property Severity:TLintSeverity read fSeverity write fSeverity;
    property Message:string read fMessage write fMessage;
    property Line:Integer read fLine write fLine;
    property Col:Integer read fCol write fCol;
    property Extra:string read fExtra write fExtra;
  end;


implementation


constructor TLintIssue.Create(const ACode:string; ASeverity:TLintSeverity; const AMessage:string; ALine, ACol:Integer; const AExtra:string);
begin
  Code := ACode;
  Severity := ASeverity;
  message := AMessage;
  Line := ALine;
  Col := ACol;
  Extra := AExtra;
end;



end.
