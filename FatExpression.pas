{
  TFatExpression by Gasper Kozak, gasper.kozak@email.si
  component is open-source and is free for all use
  version: 1.0 beta, June 2001
  --------------------------------------------
  this is a component used for calculating text-presented expressions
  features
    operations: + - * / ^ !
    parenthesis: ( )
    variables: their values are requested through OnEvaluate event
    user-defined functions:
    format function_name [ (argument_name [, argument_name ... ]] = expression

  ! parental advisory : bugs included
  if you find any, fix it or let me know

  **************** version 1.1, June 2002 *******************************

  alteracoes feitas por Allan Kardek Neponuceno Lima
  (Belem-Para-Brasil) allan_kardek@yahoo.com.br

  * bugs removidos
     fatorial        !    x!   = removido erro de avaliacao

  * verification of number of parameters

  * add operations relations:
     minor           <       x<y  = 1 (true) or 0 (false)
     major           >       x>y  = 1 (true) or 0 (false)
     major or equal  >=      x>=y = 1 (true) or 0 (false)
     minor or egual  <=      x<=y = 1 (true) or 0 (false)
     deferente       <>      x<>y = 1 (true) or 0 (false)
     egual           = (==)  x=y  = 1 (true) or 0 (false)

  * add operations logics
     and                and(.and.)  &    x and y
     or                 or(.or.)    |    x or y
     or exclusive       xor(.xor.)  ?    x xor y
     negation           not(.not.)   !    not x

  * add operations:
     divisao inteira    div    x div y = trunc(x/y)
     modulo             %      x%y     = x mod y = x – (trunc(x/y)*y)
     menos unario       -      -x      = x * (-1)

  * operacoes matematicas basicas adicionadas
     abs, and, frac, if, max, min, mod, or, sign, sum, round, trunc

  * fields of datasets:
     field  -> or :   x:y = retorna o valor do campo y do dataset x

     propriedades do TFatExpression para nomeacao simples de datasets
     a .. z: TDataSet;

  * multiples lines of FText

  **************** version 1.2, november 2002 ******************************

  * add comentarios adicionados (style pascal)
     // comentario de linha simples

  * new type: text - delimitado por " aspas duplas - permite concatenacao (+)
    ex: "allan_kardek"
    ex: "allan_kardek" + "@" + "yahoo.com.br" = "allan_kardek@yahoo.com.br"

  *********************** version 1.3, dezembrer 2002 **********************

  run script
  * command linguage clipper - if else endif
     do while | enddo | exit | loop
     begin sequence | end sequence | break
     return (optional)
  * command linguagem clipper tables -
     x->first | x->next | x->last | x->eof | x->bof


}

unit FatExpression;

{$IFDEF VER210} { Embarcadero Delphi 2010 }
  {$DEFINE D2010}
{$ENDIF}

{$IFDEF VER200} { CodeGear Delphi 2009 (also defines VER200) }
  {$DEFINE D2009}
{$ENDIF}

{$IFDEF VER185} { CodeGear Delphi 2007 (also defines VER180) }
  {$DEFINE D2007}
{$ENDIF}

{$IFDEF VER180} { Borland Delphi 2006 10.x / Turbo Delphi / Delphi 2007 }   // JB
  {$DEFINE D2006}
{$ENDIF}

{$IFDEF VER170} { Borland Delphi 2005 9.x }   // JB
   {$DEFINE D2005}
{$ENDIF}

{$IFDEF VER160} { Borland Delphi 8.0 }
  {$DEFINE D8}
{$ENDIF}

{$IFDEF VER150} { Borland Delphi 7.0 }
  {$DEFINE D7}
{$ENDIF}

{$IFDEF VER140} { Borland Delphi 6.0 }
  {$DEFINE D6}
{$ENDIF}

{$IFDEF VER130} { Borland Delphi 5.0 }
  {$DEFINE D5}
{$ENDIF}

{$IFDEF VER120} { Borland Delphi 4.0 }
  {$DEFINE D4}
{$ENDIF}

{$IFDEF VER100} { Borland Delphi 3.0 }
  {$DEFINE D3}
{$ENDIF}

{$IFDEF D2010} {$DEFINE D2009} {$ENDIF}
{$IFDEF D2009} {$DEFINE D2007} {$ENDIF}
{$IFDEF D2007} {$DEFINE D2006} {$ENDIF}
{$IFDEF D2006} {$DEFINE D2005} {$ENDIF}
{$IFDEF D2005} {$DEFINE D8}    {$ENDIF}
{$IFDEF D8}    {$DEFINE D7}    {$ENDIF}
{$IFDEF D7}    {$DEFINE D6}    {$ENDIF}
{$IFDEF D6}    {$DEFINE D5}    {$ENDIF}
{$IFDEF D5}    {$DEFINE D4}    {$ENDIF}
{$IFDEF D4}    {$DEFINE D3}    {$ENDIF}

interface

uses Classes, SysUtils, Math, DB {$IFDEF D6}, Variants{$ENDIF};

type

  // empty token, numeric, (), +-*/^!, function or variable, "," character
  TTokenType = ( ttNone, ttNumeric, ttOperation, ttString, ttText,
                 ttParamDelimitor, ttParenthesisOpen,
                 ttParenthesisClose, ttRelation, ttField, ttBoolean);

  TEvaluateOrder = (eoInternalFirst, eoEventFirst);

  {$IFDEF D6}
  TOnEvaluate = procedure( Sender: TObject; Eval: String;
                           Args: array of Variant;
                           ArgCount: Integer;
                           var Value: Variant;
                           var Done: Boolean) of object;

  TOnVariable = procedure( Sender: TObject; Eval: String;
                           var Value: Variant; var Done: Boolean) of object;

  {$ELSE}
  TOnEvaluate = procedure( Sender: TObject; Eval: String;
                           Args: array of Double;
                           ArgCount: Integer;
                           var Value: Double;
                           var Done: Boolean) of object;

  TOnVariable = procedure( Sender: TObject; Eval: String;
                           var Value: Double; var Done: Boolean) of object;

  {$ENDIF}


  TIdentType = (ttIf, ttWhile, ttBegin);

  TIdent = class
  private
    FType: TIdentType;
    FSuspend: Boolean;
    FCondicion: Boolean;
    FExecute: Boolean;
    FLine: SmallInt;
    FIfElse: Boolean;
  public
    property IdentType: TIdentType read FType;
  end;

  TVariable = class
  private
    FName: String;
    FValue: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
  public
    property Name: String read FName;
    {$IFDEF D6}
    property Value: Variant read FValue;
    {$ELSE}
    property Value: Double read FValue;
    {$ENDIF}
  end;

  // class used by TExpParser and TExpNode for breaking text into
  // tokens and building a syntax tree
  TExpToken = class
  private
    FText: String;
    FTokenType: TTokenType;
  public
    property Text: String read FText;
    property TokenType: TTokenType read FTokenType;
  end;

  // engine for breaking text into tokens
  TExpParser = class
  private
    procedure Clear;
    procedure ClearVariables;
    function GetToken(Index: Integer): TExpToken;
    function GetTokenType(S: String; First: Boolean): TTokenType;
    function GetIdent(Index: Integer): TIdent;
    function IsNumeric(s: string; var n: Double): Boolean;
    procedure SetVariable( VarName:String;
                           const Value: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF});
    function FindVariable( VarName:String):TVariable;
    function IdentLast: TIdent;
  protected
    FExpression: String;
    FTokens: TList;
    FPos: Integer;
    FVariables: TList;
    FIdentList: TList;
  public
    constructor Create;
    destructor Destroy; override;
    function ReadFirstToken: TExpToken;
    function ReadNextToken: TExpToken;
    function TokenCount: Integer;
    property Tokens[Index: Integer]: TExpToken read GetToken;
    property TokenList: TList read FTokens;
    property Idents[Index: Integer]: TIdent read GetIdent;
    property IdentList: TList read FIdentList;
    property Expression: String read FExpression write FExpression;
  end;

  // syntax-tree node. this engine uses a bit upgraded binary-tree
  TExpNode = class
  protected
    FOwner: TObject;
    FParent: TExpNode;
    FChildLeft: TList;
    FChildRigth: TList;
    FTokens: TList;
    FLevel: Integer;
    FOnEvaluate: TOnEvaluate;
  private
    function GetToken(Index: Integer): TExpToken;
    function GetToken0: TExpToken;
    function GetChildLeft(Index: Integer): TExpNode;
    function GetChildRigth(Index: Integer): TExpNode;
    function FindDataSet(DataSetName:String):TDataSet;
    function FindLSOTI: Integer; // Least Significant Operation Token Index
    function ParseFunction: Boolean;
    procedure RemoveSorroundingParenthesis;
    procedure SplitToChildren(TokenIndex: Integer);
    function Evaluate: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
    property ChildLeft[Index: Integer]: TExpNode read GetChildLeft;
    property ChildRigth[Index: Integer]: TExpNode read GetChildRigth;
    function OperParamateres: Boolean;
    function Exl(Value: Integer): Double;
  public
    constructor Create( AOwner: TObject; AParent: TExpNode; Tokens: TList);
    destructor Destroy; override;

    procedure Build;
    function TokenCount: Integer;
    function Calculate: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
    function AsDouble: Double;
    function AsString: String;

    property Tokens[Index: Integer]: TExpToken read GetToken;
    property Token: TExpToken read GetToken0;
    property Parent: TExpNode read FParent;
    property Level: Integer read FLevel;
    property OnEvaluate: TOnEvaluate read FOnEvaluate write FOnEvaluate;

  end;

  TFunction = class
  protected
    FAsString: String;
    FName: String;
    FHead: String;
    FFunction: String;
    FOwner: TObject;
    FArgs: TStringList;
    FValues: array of {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
  private
    procedure SetHeader( const Value: String);
    function GetArgCount:Integer;
    procedure SetAsString(const Value: String);
    procedure EvalArgs(Sender: TObject; Eval: String;
                       Args: array of {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
                       var Value: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF});
    function FindDataSet(DataSetName: String): TDataSet;
  public
    constructor Create(AOwner: TObject);
    destructor Destroy; override;
    {$IFDEF D6}
    function Call(Values: array of Variant): Variant;
    {$ELSE}
    function Call(Values: array of Double): Double;
    {$ENDIF}
    property AsString: String read FAsString write SetAsString;
    property Name: String read FName;
    property ArgCount: Integer read GetArgCount;
    property Args: TStringList read FArgs;
  end;

  TDataSetList = class(TPersistent)
  private
    FA, FB, FC, FD, FE, FF, FG, FH, FI,
    FJ, FK, FL, FM, FN, FO, FP, FQ, FR,
    FS, FT, FU, FV, FW, FX, FY, FZ: TDataSet;
  published
    property A: TDataSet read FA write FA;
    property B: TDataSet read FB write FB;
    property C: TDataSet read FC write FC;
    property D: TDataSet read FD write FD;
    property E: TDataSet read FE write FE;
    property F: TDataSet read FF write FF;
    property G: TDataSet read FG write FG;
    property H: TDataSet read FH write FH;
    property I: TDataSet read FI write FI;
    property J: TDataSet read FJ write FJ;
    property K: TDataSet read FK write FK;
    property L: TDataSet read FL write FL;
    property M: TDataSet read FM write FM;
    property N: TDataSet read FN write FN;
    property O: TDataSet read FO write FO;
    property P: TDataSet read FP write FP;
    property Q: TDataSet read FQ write FQ;
    property R: TDataSet read FR write FR;
    property S: TDataSet read FS write FS;
    property T: TDataSet read FT write FT;
    property U: TDataSet read FU write FU;
    property V: TDataSet read FV write FV;
    property W: TDataSet read FW write FW;
    property X: TDataSet read FX write FX;
    property Y: TDataSet read FY write FY;
    property Z: TDataSet read FZ write FZ;
  end;

  // main component, actually only a wrapper for TExpParser, TExpNode and
  // user input via OnEvaluate event
  TCustomFatExpression = class(TComponent)
  protected
    FCompiled: Boolean;
    FEvaluateOrder: TEvaluateOrder;
    FDataSetList: TDataSetList;
    FOnEvaluate: TOnEvaluate;
    FOnVariable: TOnVariable;
    FExpParser: TExpParser;
    {$IFDEF D6}
    FValue: Variant;
    {$ELSE}
    FValue: Double;
    {$ENDIF}
    FFunctions: TStringList;
    FText: TStringList;
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
    procedure SetFunctions(Value: TStringList);
    function GetText:String;
    procedure SetText( Value: String);
    procedure EvaluateCustom( Sender: TObject; Eval: String;
                           Args: array of {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
                           ArgCount: Integer;
                           var Value: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
                           var Done: Boolean); virtual;
  private
    procedure Compile;
    function GetDouble: Double;
    function GetBoolean: Boolean;
    function GetInteger: Integer;
    function GetString: String;
    procedure Evaluate( Eval: String;
      Args: array of {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
      var Value: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF});
    function FindFunction(FuncName: String): TFunction;
    //property Compiled: Boolean read FCompiled;
    procedure AdjustExpression;
    function FindDataSet(DataSetName:String): TDataSet;
    property Parser: TExpParser read FExpParser;
    function RunLine( var Index: Integer): String;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Value: Double read GetDouble;
    property AsBoolean: Boolean read GetBoolean;
    property AsDouble: Double read GetDouble;
    property AsInteger: Integer read GetInteger;
    property AsString: String read GetString;
    property EvaluateOrder: TEvaluateOrder
             read FEvaluateOrder write FEvaluateOrder default eoEventFirst;
    property Text: String read GetText write SetText;
  end;

  TFatExpression = class(TCustomFatExpression)
  published
    property DataSetList: TDataSetList read FDataSetList write FDataSetList;
    property EvaluateOrder;
    property Text;
    property Functions: TStringList read FFunctions write SetFunctions;
    property OnEvaluate: TOnEvaluate read FOnEvaluate write FOnEvaluate;
    property OnVariable: TOnVariable read FOnVariable write FOnVariable;
  end;

procedure Register;

implementation

uses ConvUtils;

const
  ERROR_CHARACTER_ILLEGAL = 'Parse error: illegal character "%s".';
  ERROR_STRING_OPEN = 'Parse error: text string not close';
  ERROR_CALCULATE_SYNTAX = 'Calculate error: syntax tree fault. Token: "%s"';
  ERROR_COMPILE_SYNTAX =  'Erro na compilação: falha na sintaxe'; // 'Compile error: syntax fault.';
  ERROR_UNDECLARED =  'Identificador não declarado: "%s"'; // 'undeclared identifier: "%s"';
  ERROR_DATASET = 'DataSet "%s" not defined.';
  ERROR_FIELD = 'Field "%s" of DataSet "%s" not found.';

  ERROR_FUNCTION_PARSE = 'Function "%s" parse error.';
  ERROR_FUNCTION_PARAMETER = 'Function "%s" invalid number parameter.';
  ERROR_FUNCTION_INVALID = 'Função "%s" não é válida.'; //  'Function "%s" is not valid.';
  ERROR_FUNCTION_HEADER = 'Function header "%s" is not valid.';
  ERROR_FUNCTION_DELIMITOR = ERROR_FUNCTION_PARSE + ': delimitor "%s" expected between arguments.';
  ERROR_FUNCTION_CLOSE = ERROR_FUNCTION_PARSE + ': parenthesis close expected.';
  ERROR_FUNCTION_TYPE = ERROR_FUNCTION_PARSE + ': argurment expected type string.';
  ERROR_FUNCTION_PARENTHESIS = 'Compile error: parenthesis mismatch.';
  ERROR_TOKEN_LIST = 'Tokens List error.';

  STR_FUNCTION = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_';
  STR_FUNCTION_2 = STR_FUNCTION + '$0123456789';
  STR_FIELD = ':';
  STR_OPERATION = '*/^%#+-!';  // supported operations numeric
  STR_RELATION  = '<>=<=='; // supported operations relation
  STR_BOOLEAN = '&|';  // & (AND), | (OR)
  // legal variable name characters
  STR_STRING: array[0..1] of string = (STR_FUNCTION, STR_FUNCTION_2);
  // function parameter delimitor
  STR_PARAMDELIMITOR = ',';
  STR_TEXT = '"';

  A_BOOLEAN: array[0..1] of String = ('&', '|');
  A_OPERATION: array[0..2] of String = ('*%^', '-+', '!/');

procedure Register;
begin
  RegisterComponents('Additional', [TFatExpression]);
end;

// ************************** TExpParser ********************

constructor TExpParser.Create;
begin
  inherited Create;
  FTokens    := TList.Create;
  FVariables := TList.Create;
  FIdentList := TList.Create;
end;

destructor TExpParser.Destroy;
begin
  Clear;
  ClearVariables;
  FIdentList.Free;
  FVariables.Free;
  FTokens.Free;
  inherited;
end;

procedure TExpParser.Clear;
begin
  while (FTokens.Count > 0) do
  begin
    TExpToken(FTokens[0]).Free;
    FTokens.Delete(0);
  end;
end;

function TExpParser.GetToken(Index: Integer): TExpToken;
begin
  Result := TExpToken(FTokens[Index]);
end;

procedure TExpParser.ClearVariables;
begin
  while (FVariables.Count > 0) do
  begin
    TVariable(FVariables[0]).Free;
    FVariables.Delete(0);
  end;
  while (FIdentList.Count > 0) do
  begin
    TIdent(FIdentList[0]).Free;
    FIdentList.Delete(0);
  end;
end;

procedure TExpParser.SetVariable( VarName:String;
  const Value: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF});
var
  Variable: TVariable;
begin

  Variable := FindVariable(VarName);

  if Assigned(Variable) then
    Variable.FValue := Value
  else begin
    Variable := TVariable.Create;
    Variable.FName  := VarName;
    Variable.FValue := Value;
    FVariables.Add(Variable);
  end;

end;

function TExpParser.FindVariable( VarName: String):TVariable;
var
  i: Integer;
  Variable: TVariable;
begin
  Result := nil;
  for i := 0 to FVariables.Count-1 do
  begin
    Variable := TVariable(FVariables[i]);
    if (Variable.FName = VarName) then
    begin
      Result := Variable;
      Break;
    end;
  end;  // for
end;  // function FindVariable

function TExpParser.IdentLast: TIdent;
begin
  Result := nil;
  if (FIdentList.Count > 0) then
    Result := TIdent( FIdentList.Items[FIdentList.Count-1]);
end;

function TExpParser.GetIdent(Index: Integer): TIdent;
begin
  Result := TIdent(FIdentList[Index]);
end;

function TExpParser.ReadFirstToken: TExpToken;
begin
  Clear;
  FPos := 1;
  Result := ReadNextToken;
end;

function TExpParser.IsNumeric( s: string; var n: Double): Boolean;
var
  Code:Integer;
begin
  Val( Trim(s), n, Code);
  Result := (Code = 0);
end;

function TExpParser.GetTokenType( s: String; First: Boolean): TTokenType;
var
  Value: Double;
  P: Integer;
begin

  if (s = STR_PARAMDELIMITOR) then
    Result := ttParamDelimitor
  else if Pos( s, STR_OPERATION) > 0 then
    Result := ttOperation
  else if s = '(' then
    Result := ttParenthesisOpen
  else if s = ')' then
    Result := ttParenthesisClose
  else if Pos(s, STR_RELATION) > 0 then
    Result := ttRelation
  else if Pos( s, STR_BOOLEAN) > 0 then
    Result := ttBoolean
  else if Pos(s, STR_FIELD) > 0 then
    Result := ttField
  else if Pos( s, STR_TEXT) > 0 then
    Result := ttText
  else if IsNumeric( s, Value) then
    Result := ttNumeric
  else begin
    if First then
      P := Pos( s, STR_STRING[0])
    else
      P := Pos( s, STR_STRING[1]);
    if (P > 0) then
      Result := ttString
    else
      Result := ttNone;
  end;

end;  // GetTokenType

function TExpParser.ReadNextToken: TExpToken;
var
  Part, Ch: String;
  FirstType, NextType: TTokenType;

  procedure CreateToken(Text: String);
  begin
    Result := TExpToken.Create;
    Result.FText := Text;
    Result.FTokenType := FirstType;
    FTokens.Add(Result);
  end;

begin

  Result := nil;

  if (FPos > Length(FExpression)) then
    Exit;

  repeat
    Ch := FExpression[FPos];
    Inc(FPos);
  until (Ch <> ' ') or (FPos > Length(FExpression));

  FirstType := GetTokenType(Ch, True);

  if (FirstType = ttNone) then
    raise Exception.CreateFmt(ERROR_CHARACTER_ILLEGAL, [Ch]);

  if (FirstType in [ttOperation, ttParenthesisOpen, ttParenthesisClose,
                    ttField, ttBoolean]) then
  begin
    CreateToken(Ch);
    Exit;
  end;

  if (FirstType = ttRelation) then
  begin

    if (FPos <= Length(FExpression)) then
    begin

      Part := Ch;
      Ch   := FExpression[FPos];

      NextType := GetTokenType(Ch, False);

      if (FirstType = NextType) and (FirstType = ttRelation) and (Pos(Part+Ch, STR_RELATION) > 0) then
      begin
        Inc(FPos);
        Part := Part + Ch;
      end;

    end;

    CreateToken(Part);
    Exit;

  end;

  Part := '';

  if (FirstType = ttText) then
  begin

    repeat
      Ch := FExpression[FPos];
      Inc(FPos);
      if (Ch <> STR_TEXT) then
        Part := Part + Ch
    until (Ch = STR_TEXT) or (FPos > Length(FExpression));

    if (Ch <> STR_TEXT) then
      raise Exception.Create(ERROR_STRING_OPEN);

    CreateToken(Part);
    Exit;

  end;  // if FirstType

  // number e string

  Part := Ch;

  repeat

    Ch       := FExpression[FPos];
    NextType := GetTokenType( Ch, False);

    if (NextType = FirstType) or ((FirstType = ttString) and (NextType = ttNumeric)) then
      Part := Part + Ch
    else begin
      CreateToken(Part);
      Exit;
    end;

    Inc(FPos);

  until (FPos > Length(FExpression));

  CreateToken(Part);

end; // function ReadNextToken

function TExpParser.TokenCount: Integer;
begin
  Result := FTokens.Count;
end;

// ************************** TExpNode ********************

constructor TExpNode.Create(AOwner: TObject; AParent: TExpNode; Tokens: TList);
var
  I: Integer;
begin

  inherited Create;

  FOwner := AOwner;
  FParent := AParent;

  if (FParent = nil) then
     FLevel := 0
  else
     FLevel := FParent.Level + 1;

  FTokens := TList.Create;
  for i := 0 to Tokens.Count - 1 do
    FTokens.Add(Tokens[I]);

  FChildLeft  := TList.Create;
  FChildRigth := TList.Create;

end;

destructor TExpNode.Destroy;
var
  Child: TExpNode;
begin

  if Assigned(FChildLeft) then
  begin
    while (FChildLeft.Count > 0) do
    begin
      Child :=  ChildLeft[0];
      FreeAndNil(Child);
      FChildLeft.Delete(0);
    end;
    FreeAndNil(FChildLeft);
  end;

  if Assigned(FChildRigth) then
  begin
    while (FChildRigth.Count > 0) do
    begin
      Child :=  ChildRigth[0];
      FreeAndNil(Child);
      FChildRigth.Delete(0);
    end;
    FreeAndNil(FChildRigth);
  end;

  FTokens.Free;

  inherited;

end;

procedure TExpNode.RemoveSorroundingParenthesis;
var
  First, Last, Lvl, i: Integer;
  Sorrounding: Boolean;
begin

  First := 0;
  Last := TokenCount - 1;

  while (Last > First) do
  begin

    if (Tokens[First].TokenType = ttParenthesisOpen) and
       (Tokens[Last].TokenType = ttParenthesisClose) then
    begin

      Lvl := 0;
      i := 0;

      Sorrounding := True;

      repeat

        if (Tokens[i].TokenType = ttParenthesisOpen) then
          Inc(Lvl)
        else if (Tokens[i].TokenType = ttParenthesisClose) then
          Dec(Lvl);

        if (Lvl = 0) and (i < TokenCount - 1) then
        begin
          Sorrounding := False;
          Break;
        end;

        Inc(I);

      until i = TokenCount;

      if Sorrounding then
      begin
        FTokens.Delete(Last);
        FTokens.Delete(First);
      end else
        Exit;

    end else
      Exit;

    First := 0;
    Last := TokenCount - 1;

  end;  // while

end; // RemoveSorroundingParenthesis

procedure TExpNode.Build;
var
  LSOTI: Integer;
begin

  RemoveSorroundingParenthesis;

  if (TokenCount < 2) then
    Exit;

  LSOTI := FindLSOTI();

  if (LSOTI < 0) then
  begin
    if not ParseFunction then
      raise Exception.Create(ERROR_COMPILE_SYNTAX+#13#13+
                             'Expressão: '+TFatExpression(FOwner).Text);
  end else
    SplitToChildren(LSOTI);

end;  // Build

function TExpNode.ParseFunction: Boolean;
var
  i, Delimitor, DelimitorLevel: Integer;
  FChild: TExpNode;
  FList: TList;
begin

  Result := (TokenCount > 3) and
            (Tokens[0].TokenType = ttString) and
            (Tokens[1].TokenType = ttParenthesisOpen) and
            (Tokens[TokenCount - 1].TokenType = ttParenthesisClose);

  if not Result then
    Exit;

  FTokens.Delete(TokenCount - 1);
  FTokens.Delete(1);

  FList := TList.Create;

  try

    while (TokenCount > 1) do
    begin

      Delimitor := - 1;
      DelimitorLevel := 0;

      for i := 1 to TokenCount - 1 do
      begin

        if Tokens[i].TokenType = ttParenthesisOpen then
          Inc(DelimitorLevel)
        else if Tokens[i].TokenType = ttParenthesisClose then
          Dec(DelimitorLevel)
        else if (Tokens[i].TokenType = ttParamDelimitor) and
                (DelimitorLevel = 0) then
        begin
          Delimitor := i - 1;
          FTokens.Delete(i);
          Break;
        end;

        if (DelimitorLevel < 0) then
        begin
          raise Exception.CreateFmt(ERROR_FUNCTION_PARSE, [Tokens[i].Text]);
          Exit;
        end;

      end;  // for

      if Delimitor = -1 then
        Delimitor := TokenCount - 1;

      for i := 1 to Delimitor do
      begin
        FList.Add(Tokens[1]);
        FTokens.Delete(1);
      end;

      FChild := TExpNode.Create(FOwner, Self, FList);

      FList.Clear;
      FChild.Build;
      FChildLeft.Add(FChild);

    end; // while

  finally
    FList.Free;
  end;

end;  // TExpNode.ParseFunction

procedure TExpNode.SplitToChildren(TokenIndex: Integer);
var
  Left, Right: TList;
  i: Integer;
  FChild: TExpNode;
begin

  Left  := TList.Create;   // Bug avaliacao removido
  Right := TList.Create;

  try

    if (TokenIndex < TokenCount - 1) then
    begin

      for i := TokenCount - 1 downto TokenIndex + 1 do
      begin
        Right.Insert(0, FTokens[i]);
        FTokens.Delete(i);
      end;

      FChild := TExpNode.Create(FOwner, Self, Right);
      FChildRigth.Insert(0, FChild);
      FChild.Build;

    end;

    if (TokenIndex > 0) then
    begin

      for i := TokenIndex - 1 downto 0 do
      begin
        Left.Insert(0, FTokens[i]);
        FTokens.Delete(i);
      end;

      FChild := TExpNode.Create( FOwner, Self, Left);
      FChildLeft.Insert(0, FChild);
      FChild.Build;

    end;

  finally
    Left.Free;
    Right.Free;
  end;

end;  // TExpNode.SplitToChildren

function TExpNode.GetChildLeft(Index: Integer): TExpNode;
begin
  Result := TExpNode(FChildLeft[Index]);
end;

function TExpNode.GetChildRigth(Index: Integer): TExpNode;
begin
  Result := TExpNode(FChildRigth[Index]);
end;

function TExpNode.FindDataSet( DataSetName: String):TDataSet;
begin
  Result := nil;
  if (FOwner is TFatExpression) then
    Result := TFatExpression(FOwner).FindDataSet(DataSetName)
  else if (FOwner is TFunction) then
    Result := TFunction(FOwner).FindDataSet(DataSetName);
end;  // FindDataSet

function TExpNode.FindLSOTI: Integer;

  function PosArray( SubStr: String; aString: array of String):Integer;
  var
    i: Integer;
  begin
    Result := 0;
    for i := Low( aString) to High(aString) do
    begin
      Result := Pos( SubStr, aString[i]);
      if (Result > 0) then
        Break;
    end;  // for
  end; // PosArray

var
  Lvl, i, NewPriorityBoolean, NewPriorityOperation: Integer;
  PriorityBoolean, PriorityOperation,
  PriorityRelation, PriorityField: Integer;
begin

  Lvl := 0; // Lvl = parenthesis level
  i := 0;
  Result := - 1;

  PriorityBoolean   := -1;
  PriorityRelation  := -1;
  PriorityOperation := -1;
  PriorityField     := -1;

  repeat

    if (Tokens[i].TokenType = ttParenthesisOpen) then
      Inc(Lvl)
    else if (Tokens[i].TokenType = ttParenthesisClose) then
      Dec(Lvl);

    if (Lvl < 0) then
      raise Exception.Create(ERROR_FUNCTION_PARENTHESIS);

    if (Lvl = 0) then
    begin

      if (Tokens[i].TokenType = ttBoolean) then
      begin
        NewPriorityBoolean := PosArray( Tokens[i].Text, A_BOOLEAN);
        if (PriorityBoolean = -1) or
           (NewPriorityBoolean = PriorityBoolean) or
           (NewPriorityBoolean < PriorityBoolean) then
          PriorityBoolean := i;

      end else if (Tokens[i].TokenType = ttRelation) then
        PriorityRelation := i

      else if (Tokens[i].TokenType = ttOperation) then
      begin
        NewPriorityOperation := PosArray( Tokens[i].Text, A_OPERATION);
        if (PriorityOperation = -1) or
           (NewPriorityOperation = PriorityOperation) or
           (NewPriorityOperation < PriorityOperation) then
          PriorityOperation := i;

      end else if (Tokens[i].TokenType = ttField) then
        PriorityField := i;

    end;

    Inc(I);

  until i = TokenCount;

  if (PriorityBoolean > -1) then
    Result := PriorityBoolean
  else if (PriorityRelation > -1) then
    Result := PriorityRelation
  else if (PriorityOperation > -1) then
    Result := PriorityOperation
  else if (PriorityField > -1) then
    Result := PriorityField;

end;  // function FindLSOTI

function TExpNode.Exl(Value: Integer): Double;
begin
  if Value <= 1 then
    Result := Value
  else
    Result := Value * Exl(Value - 1);
end;

function TExpNode.Evaluate: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
var
  {$IFDEF D6}
  Args: array of Variant;
  {$ELSE}
  Args: array of Double;
  {$ENDIF}
  i: Integer;
  Done: Boolean;
begin

  // {$IFDEF D2010}
  //Result := varNull;
  //{$ELSE}
  Result := NULL;
  //{$ENDIF}

  SetLength( Args, FChildLeft.Count);

  for i := 0 to FChildLeft.Count - 1 do
    Args[i] := ChildLeft[i].Calculate;

  if Assigned(FOnEvaluate) then
    FOnEvaluate( Self, Token.Text, Args, High(Args) + 1, Result, Done)
  else if (FOwner is TFatExpression) then
    TFatExpression(FOwner).Evaluate( Token.Text, Args, Result)
  else if (FOwner is TFunction) then
    TFunction(FOwner).EvalArgs( Self, Token.Text, Args, Result);

  //{$IFDEF D2010}
  //if Result = varNull then
  //  raise Exception.CreateFmt( ERROR_UNDECLARED, [Token.Text]);
  //{$ELSE}
  if Result = NULL then
    raise Exception.CreateFmt( ERROR_UNDECLARED, [Token.Text]);
  //{$ENDIF}

end;  // function TExpNode.Evaluate

function TExpNode.OperParamateres: Boolean;
begin

  Result := True;

  if (Token.TokenType in [ttOperation, ttRelation, ttBoolean, ttField]) then
  begin

    if (Token.Text = '-') and
       (FChildLeft.Count = 0) and (FChildRigth.Count = 1) then
      Result := True

    else if (Token.Text = '!') then   // negacao ou fatorial
      Result := (FChildLeft.Count = 1) xor (FChildRigth.Count = 1)

    else if Pos( Token.Text, STR_OPERATION) > 0 then
      Result := (FChildLeft.Count = 1) and (FChildRigth.Count = 1)

    else if Pos( Token.Text, STR_RELATION) > 0 then
      Result := (FChildLeft.Count = 1) and (FChildRigth.Count = 1)

    else if Pos( Token.Text, STR_FIELD) > 0 then
      Result := (FChildLeft.Count = 1) and (FChildRigth.Count = 1)

    else if Pos( Token.Text, STR_BOOLEAN) > 0 then
      Result := (FChildLeft.Count = 1) and (FChildRigth.Count = 1);

  end;

end;  // TExpNode.OperParamateres

function TExpNode.AsDouble: Double;
begin
  Result := Calculate;
end;

function TExpNode.AsString: String;
begin
  {$IFDEF D6}
  Result := String(Calculate);
  {$ELSE}
  Result := FloatToStr(Calculate);
  {$ENDIF}
end;

function TExpNode.Calculate: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
var
  DataSetName, FieldName: String;
  Left, Rigth: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
begin

  Result := 0;

  if TokenCount <> 1 then
    Exit;

  if not OperParamateres() then
    raise Exception.CreateFmt( ERROR_CALCULATE_SYNTAX, [Token.Text]);

  if (Token.TokenType = ttNumeric) then
    { Bug: Quando o DecimalSeparator (SO) era diferente de '.' a conversão resultava em número inteiro.
      Corrigido por allan_kardek em 09/11/2005 }
    // Result := Token.Text
    Result := StrToFloat( StringReplace(Token.Text, '.', DecimalSeparator, []))

  else if (Token.TokenType = ttString) then
  begin

    if UpperCase(Token.Text) = 'TRUE' then
      Result := 1
    else if UpperCase(Token.Text) = 'FALSE' then
      Result := 0
    else
      Result := Evaluate

  end else if (Token.FTokenType = ttOperation) then
  begin

    if (Token.Text = '+') then
      Result := ChildLeft[0].AsDouble + ChildRigth[0].AsDouble

    {$IFDEF D6}
    else if (Token.Text = '#') then
      Result := ChildLeft[0].AsString + ChildRigth[0].AsString
    {$ENDIF}

    else if (Token.Text = '-') then
    begin
      if (FChildLeft.Count = 0) and (FChildRigth.Count = 1) then
        Result := ChildRigth[0].Calculate*(-1)
      else
        Result := ChildLeft[0].AsDouble - ChildRigth[0].AsDouble;

    end else if (Token.Text = '*') then
      Result := ChildLeft[0].AsDouble * ChildRigth[0].AsDouble

    else if (Token.Text = '/') then
      Result := ChildLeft[0].AsDouble / ChildRigth[0].AsDouble

    else if (Token.Text = '^') then
      Result := Power(ChildLeft[0].AsDouble, ChildRigth[0].AsDouble)

    else if (Token.Text = '%') then  // module
      Result := Trunc(ChildLeft[0].AsDouble) MOD Trunc(ChildRigth[0].AsDouble)

    else if (Token.Text = '!') then
    begin

      if (FChildRigth.Count = 1) then
      begin  // negacao
        if ChildRigth[0].AsDouble = 1 then
          Result := 0
        else
          Result := 1;
      end else                               // fatorial
        Result := Exl( Trunc(ChildLeft[0].AsDouble));

    end;

  end else if (Token.TokenType = ttBoolean) then
  begin

    Left  := ChildLeft[0].AsDouble;
    Rigth := ChildRigth[0].AsDouble;

    if (Token.Text = '&') and (Left = 1) and (Rigth = 1) then
      Result := 1
    else if (Token.Text = '|') and ( (Left=1) or (Rigth = 1) ) then
      Result := 1;

  end else if (Token.FTokenType = ttField) then
  begin

    DataSetName := ChildLeft[0].Token.Text;
    FieldName   := UpperCase(ChildRigth[0].Token.Text);

    if (FieldName = 'EOF') and FindDataSet(DataSetName).Eof then
      Result := 1
    else if (FieldName = 'BOF') and FindDataSet(DataSetName).Bof then
      Result := 1
    else if (FieldName = 'NEXT') then
      FindDataSet(DataSetName).Next
    else if (FieldName = 'FIRST') then
      FindDataSet(DataSetName).First
    else if (FieldName = 'LAST') then
      FindDataSet(DataSetName).Last
    else
      Result := FindDataSet(DataSetName).FieldByName(FieldName).Value;

  // Operacoes relacionais
  end else if (Token.TokenType = ttRelation) then
  begin

    Left   := ChildLeft[0].Calculate;
    Rigth  := ChildRigth[0].Calculate;

    if (Token.Text = '>') and (Left > Rigth) then
      Result := 1
    else if (Token.Text = '<') and (Left < Rigth) then
      Result := 1
    else if (Token.Text = '>=') and (Left >= Rigth) then
      Result := 1
    else if (Token.Text='<=') and (Left <= Rigth) then
      Result := 1
    else if (Token.Text = '<>') and (Left <> Rigth) then
      Result := 1
    else if ( (Token.Text = '=') or (Token.Text = '==') ) and (Left = Rigth) then
      Result := 1;

  end
  {$IFDEF D6}
  else if (Token.TokenType = ttText) then
    Result := Token.Text
  {$ENDIF};

end;  // TExpNode.Calculate

function TExpNode.GetToken(Index: Integer): TExpToken;
begin
  Result := TExpToken(FTokens[Index]);
end;

function TExpNode.GetToken0: TExpToken;
begin
  if (TokenCount > 1) then
    raise Exception.Create( ERROR_TOKEN_LIST);
  Result := GetToken(0);
end;

function TExpNode.TokenCount: Integer;
begin
  Result := FTokens.Count;
end;

// ****************  TFunction ********************

constructor TFunction.Create(AOwner: TObject);
begin
  inherited Create;
  FOwner := AOwner;
  FAsString := '';
  FName := '';
  FArgs := TStringList.Create;
end;

destructor TFunction.Destroy;
begin
  FArgs.Free;
  inherited;
end;

{$IFDEF D6}
function TFunction.Call(Values: array of Variant): Variant;
{$ELSE}
function TFunction.Call(Values: array of Double): Double;
{$ENDIF}
var
  Token: TExpToken;
  Tree: TExpNode;
  Parser: TExpParser;
  i: Integer;
begin

  if (FArgs.Count <> High(Values)+1) then
    raise Exception.CreateFmt( ERROR_FUNCTION_PARAMETER, [Self.FName]);

  SetLength( FValues, High(Values) + 1);

  for i := 0 to High(Values) do
    FValues[i] := Values[i];

  Parser := TExpParser.Create;

  try

    Parser.Expression := FFunction;

    Token := Parser.ReadFirstToken;
    while (Token <> nil) do
      Token := Parser.ReadNextToken;

    Tree := TExpNode.Create( Self, nil, Parser.TokenList);

    try
      Tree.Build;
      Result := Tree.Calculate;
    finally
      Tree.Free;
    end;

  finally
    Parser.Free;
  end;  // try

end;  // TFunction.Call

procedure TFunction.EvalArgs(Sender: TObject; Eval: String;
  Args: array of {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
  var Value: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF});
var
  i: Integer;
begin

  for i := 0 to FArgs.Count - 1 do
    if (UpperCase(FArgs[i]) = UpperCase(Eval)) then
    begin
      Value := FValues[i];
      Exit;
    end;

  if (FOwner is TFatExpression) then
    TFatExpression(FOwner).Evaluate( Eval, Args, Value);

end;

function TFunction.FindDataSet(DataSetName: String): TDataSet;
begin
  Result := TFatExpression(FOwner).FindDataSet( DataSetName);
end;

procedure TFunction.SetHeader(const Value: String);
var
  Parser: TExpParser;
  Token: TExpToken;
  ExpectParenthesisOpen, ExpectParenthesisClose,
  ExpectDelimitor, ExpectFuncName: Boolean;
begin

  FArgs.Clear;

  FHead := Value;
  FName := '';

  ExpectParenthesisOpen  := True;
  ExpectParenthesisClose := False;
  ExpectDelimitor        := False;
  ExpectFuncName         := True;

  Parser := TExpParser.Create;

  try

    Parser.Expression := Value;

    Token := Parser.ReadFirstToken;

    while (Token <> nil) do
    begin

      if ExpectFuncName then
      begin
        if (Token.TokenType <> ttString) then
          raise Exception.CreateFmt( ERROR_FUNCTION_INVALID, [FAsString]);
        FName := Token.Text;
        ExpectFuncName := False;

      end else if ExpectParenthesisOpen then
      begin
        if (Token.TokenType <> ttParenthesisOpen) then
          raise Exception.CreateFmt( ERROR_FUNCTION_HEADER, [Value]);
        ExpectParenthesisOpen  := False;
        ExpectParenthesisClose := True;

      end else if not ExpectParenthesisClose then
        raise Exception.CreateFmt( ERROR_FUNCTION_HEADER, [Value])

      else if ExpectDelimitor then
      begin
        if not (Token.TokenType in [ttParamDelimitor, ttParenthesisClose]) then
          raise Exception.CreateFmt( ERROR_FUNCTION_DELIMITOR,
                                     [ Self.FName, STR_PARAMDELIMITOR]);
        ExpectDelimitor := False;
        if (Token.TokenType = ttParenthesisClose) then
          ExpectParenthesisClose := False;

      end else if (Token.TokenType = ttString) then
      begin
        FArgs.Add(Token.Text);
        ExpectDelimitor := True;

      end else
        raise Exception.CreateFmt( ERROR_FUNCTION_TYPE, [Self.FName] );

      Token := Parser.ReadNextToken;

    end;

    if ExpectFuncName then
      raise Exception.CreateFmt( ERROR_FUNCTION_HEADER, [Value]);

    if ExpectParenthesisClose then
      raise Exception.CreateFmt( ERROR_FUNCTION_CLOSE, [Self.FName]);

  finally
    Parser.Free;
  end;

end;

function TFunction.GetArgCount:Integer;
begin
  Result := FArgs.Count;
end;

procedure TFunction.SetAsString( const Value: String);
var
  Head: String;
  HeadPos: Integer;
begin

  HeadPos := Pos( '=', Value);

  if (HeadPos = 0) then
    raise Exception.CreateFmt( ERROR_FUNCTION_INVALID, [Value]);

  FAsString := Value;   // texto completo da funcao

  FFunction := Copy( Value, HeadPos + 1, Length(Value));
  Head      := Copy( Value, 1, HeadPos - 1);

  SetHeader(Head);

end;  // AsString

// ***************** TCustomFatExpression *************************

constructor TCustomFatExpression.Create(AOwner: TComponent);
begin
  inherited;
  FCompiled      := False;
  FDataSetList   := TDataSetList.Create;
  FEvaluateOrder := eoInternalFirst;
  FFunctions     := TStringList.Create;
  FExpParser     := TExpParser.Create;
  FText          := TStringList.Create;
end;

destructor TCustomFatExpression.Destroy;
begin
  FText.Free;
  FExpParser.Free;
  FFunctions.Free;
  FDataSetList.Free;
  inherited;
end;

procedure TCustomFatExpression.Compile;
var
  Token: TExpToken;
  Tree: TExpNode;
  Expression, VarName: String;
  i, Line: Integer;
  Done: Boolean;
begin

  Line := 0;

  while (Line < FText.Count) do
  begin

    Expression := RunLine(Line);

    if (Expression <> '') then
    begin

      VarName := '';
      i := Pos( ':=', Expression);

      if (i > 0) then
      begin
        VarName := Trim(Copy( Expression, 1, i-1));
        Delete( Expression, 1, i+1);
      end;

      Parser.Expression := Trim(Expression);

      Token := Parser.ReadFirstToken;
      while (Token <> nil) do
        Token := Parser.ReadNextToken;

      Tree := TExpNode.Create( Self, nil, Parser.TokenList);

      try
        Tree.Build;
        FValue := Tree.Calculate;
      finally
        Tree.Free;
      end;

      if (VarName <> '') then
      begin
        Done := False;
        if Assigned(FOnVariable) then
          FOnVariable( Self, VarName, FValue, Done);
        if not Done then
          Parser.SetVariable( VarName, FValue);
      end;

      if (Parser.FIdentList.Count > 0) and
         Parser.IdentLast.FExecute and Parser.IdentLast.FSuspend then
      begin
        Parser.IdentLast.FSuspend := False;
        Parser.IdentLast.FCondicion := (FValue = 1);
      end;

    end;  // if Expression <> ''

    Inc(Line);

  end;  // while

  Parser.ClearVariables;

end; // procedure Compile

function TCustomFatExpression.FindFunction(FuncName: String): TFunction;
var
  F: TFunction;
  i: Integer;
begin

  Result := nil;

  for i := 0 to FFunctions.Count - 1 do
    if (Trim(FFunctions[i]) <> '') then
    begin
      F := TFunction.Create(Self);
      F.AsString := FFunctions[i];
      if (UpperCase(F.Name) = UpperCase(FuncName)) then
      begin
        Result := F;
        Exit;
      end;
      F.Free;
    end;

end;  // FindFunction

procedure TCustomFatExpression.Evaluate( Eval: String;
  Args: array of {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
  var Value: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF});
var
  Func: TFunction;
  Variable: TVariable;
  Done: Boolean;
begin

  Done := False;

  if (EvaluateOrder = eoEventFirst) and Assigned(FOnEvaluate) then
  begin
    FOnEvaluate( Self, Eval, Args, High(Args)+1, Value, Done);
    if Done then
      Exit;
  end;

  Variable := Parser.FindVariable(Eval);

  if Assigned(Variable) then
  begin
    Value := Variable.FValue;
    Exit;
  end;

  Func := FindFunction(Eval);

  if Assigned(Func) then
  begin
    Value := Func.Call(Args);
    Func.Free;
    Exit;
  end;

  EvaluateCustom( Self, Eval, Args, High(Args)+1, Value, Done);

  if Done then
    Exit;

  if (EvaluateOrder = eoInternalFirst) and Assigned(FOnEvaluate) then
    FOnEvaluate(Self, Eval, Args, High(Args) + 1, Value, Done);

end;  // procedure Evaluate

function TCustomFatExpression.GetDouble: Double;
begin
  FValue := 0.0;
  Compile;
  Result := FValue;
end;

function TCustomFatExpression.GetBoolean: Boolean;
begin
  FValue := 0;
  Compile;
  if (FValue = 0) then  // style boolean c
    Result := False
  else
    Result := True;
end;

function TCustomFatExpression.GetInteger: Integer;
begin
  FValue := 0;
  Compile;
  Result := Trunc(FValue);
end;

function TCustomFatExpression.GetString: String;
begin
  Compile;
  Result := FloatToStr(FValue);
end;

procedure TCustomFatExpression.SetFunctions(Value: TStringList);
begin
  FFunctions.Assign(Value);
end;

procedure TCustomFatExpression.AdjustExpression;
var
  Ch: Char;
  Line: String;
  sText: String;
  i, Index:Integer;
  bOpen:Boolean;

  function PosNext( C:Char; S:String; P:Integer):Integer;
  begin
    Result := Pos( C, Copy( S, P, MaxInt));
    if Result > 0 then
      Result := Result + (P-1);
  end;

begin

  for i := 0 to FText.Count-1 do
    if (Copy( FText[i], 1, 1) = '*') then
      FText[i] := '';

  Index := 0;

  while (Index < FText.Count) do
  begin

    bOpen := False;
    sText := '';
    i     := 1;
    Line  := Trim(FText[Index]);

    // retira comentarios
    while (i <= Length(Line)) do
    begin

      Ch := Line[i];

      if (Ch = STR_TEXT) then
        bOpen := not bOpen;

      if (Ch <> '/') then
        sText := '';

      if (bOpen = False) and (Ch = '/') then
        sText := sText + Ch;

      if (sText = '//') then  // exclui comentario
        Delete( Line, i-1, MaxInt);

      Inc(i);

    end; // while

    FText[Index] := Line;
    Inc(Index);

  end; // while

end;  // TCustomFatExpression.AdjustExpression


function TCustomFatExpression.GetText:String;
begin
  Result := FText.Text;
end;

procedure TCustomFatExpression.SetText( Value: String);
begin
  FText.Text := Value;
  AdjustExpression;
  FCompiled  := False;
end;

procedure TCustomFatExpression.EvaluateCustom( Sender: TObject; Eval: String;
  Args: array of {$IFDEF D6}Variant{$ELSE}Double{$ENDIF}; ArgCount: Integer;
  var Value: {$IFDEF D6}Variant{$ELSE}Double{$ENDIF};
  var Done: Boolean);
begin
  Done := False;
end;

function TCustomFatExpression.FindDataSet( DataSetName: String): TDataSet;
begin

  Result := nil;

  DataSetName := UpperCase(DataSetName);

  if      (DataSetName = 'A') then Result := FDataSetList.FA
  else if (DataSetName = 'B') then Result := FDataSetList.FB
  else if (DataSetName = 'C') then Result := FDataSetList.FC
  else if (DataSetName = 'D') then Result := FDataSetList.FD
  else if (DataSetName = 'E') then Result := FDataSetList.FE
  else if (DataSetName = 'F') then Result := FDataSetList.FF
  else if (DataSetName = 'G') then Result := FDataSetList.FG
  else if (DataSetName = 'H') then Result := FDataSetList.FH
  else if (DataSetName = 'I') then Result := FDataSetList.FI
  else if (DataSetName = 'J') then Result := FDataSetList.FJ
  else if (DataSetName = 'K') then Result := FDataSetList.FK
  else if (DataSetName = 'L') then Result := FDataSetList.FL
  else if (DataSetName = 'M') then Result := FDataSetList.FM
  else if (DataSetName = 'N') then Result := FDataSetList.FN
  else if (DataSetName = 'O') then Result := FDataSetList.FO
  else if (DataSetName = 'P') then Result := FDataSetList.FP
  else if (DataSetName = 'Q') then Result := FDataSetList.FQ
  else if (DataSetName = 'R') then Result := FDataSetList.FR
  else if (DataSetName = 'S') then Result := FDataSetList.FS
  else if (DataSetName = 'T') then Result := FDataSetList.FT
  else if (DataSetName = 'U') then Result := FDataSetList.FU
  else if (DataSetName = 'V') then Result := FDataSetList.FV
  else if (DataSetName = 'W') then Result := FDataSetList.FW
  else if (DataSetName = 'X') then Result := FDataSetList.FX
  else if (DataSetName = 'Y') then Result := FDataSetList.FY
  else if (DataSetName = 'Z') then Result := FDataSetList.FZ;

  if not Assigned(Result) then
    raise Exception.CreateFmt( ERROR_DATASET, [DataSetName]);

end;

procedure TCustomFatExpression.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) then
  begin
    if AComponent = FDataSetList.A      then FDataSetList.A := nil
    else if AComponent = FDataSetList.B then FDataSetList.B := nil
    else if AComponent = FDataSetList.C then FDataSetList.C := nil
    else if AComponent = FDataSetList.D then FDataSetList.D := nil
    else if AComponent = FDataSetList.E then FDataSetList.E := nil
    else if AComponent = FDataSetList.F then FDataSetList.F := nil
    else if AComponent = FDataSetList.G then FDataSetList.G := nil
    else if AComponent = FDataSetList.H then FDataSetList.H := nil
    else if AComponent = FDataSetList.I then FDataSetList.I := nil
    else if AComponent = FDataSetList.J then FDataSetList.J := nil
    else if AComponent = FDataSetList.K then FDataSetList.K := nil
    else if AComponent = FDataSetList.L then FDataSetList.L := nil
    else if AComponent = FDataSetList.M then FDataSetList.M := nil
    else if AComponent = FDataSetList.N then FDataSetList.N := nil
    else if AComponent = FDataSetList.O then FDataSetList.O := nil
    else if AComponent = FDataSetList.P then FDataSetList.P := nil
    else if AComponent = FDataSetList.Q then FDataSetList.Q := nil
    else if AComponent = FDataSetList.R then FDataSetList.R := nil
    else if AComponent = FDataSetList.S then FDataSetList.S := nil
    else if AComponent = FDataSetList.T then FDataSetList.T := nil
    else if AComponent = FDataSetList.U then FDataSetList.U := nil
    else if AComponent = FDataSetList.V then FDataSetList.V := nil
    else if AComponent = FDataSetList.W then FDataSetList.W := nil
    else if AComponent = FDataSetList.X then FDataSetList.X := nil
    else if AComponent = FDataSetList.Y then FDataSetList.Y := nil
    else if AComponent = FDataSetList.Z then FDataSetList.Z := nil;
  end;
end;

function TCustomFatExpression.RunLine( var Index:Integer):String;
var
  Line: String;
  Ident: TIdent;
  bExecute: Boolean;
  i: Integer;
begin

  Line   := UpperCase(FText[Index]);
  Result := '';

  if (Line = 'BEGIN SEQUENCE') then
  begin

    bExecute := True;

    if (Parser.FIdentList.Count > 0) then
      bExecute := Parser.IdentLast.FExecute and
                  (Parser.IdentLast.FCondicion <> Parser.IdentLast.FIfElse);

    Ident := TIdent.Create;

    with Ident do
    begin
      FType := ttBegin;
      FSuspend := False;
      FLine := Index;
      FIfElse := False;
      FCondicion := True;
      FExecute := bExecute;
    end;

    Parser.FIdentList.Add(Ident);

  end else if (Line = 'BREAK') then
  begin

    bExecute := False;

    for i := Parser.FIdentList.Count - 1 downto 0 do
      if (Parser.Idents[i].FType = ttBegin) then
      begin
        bExecute := True;
        Break;
      end;

    if not bExecute then
      raise Exception.Create('BREAK command not found BEGIN SEQUENCE');

    if Parser.IdentLast.FExecute and
       (Parser.IdentLast.FCondicion <> Parser.IdentLast.FIfElse) then
      for i := Parser.FIdentList.Count - 1 downto 0 do
      begin
        Parser.Idents[i].FExecute := False;
        if Parser.Idents[i].FType = ttBegin then
          Break;
      end;

  end else if (Line = 'END SEQUENCE') then
  begin

    if (Parser.FIdentList.Count = 0) then
      raise Exception.Create('END SEQUENCE not found BEGIN SEQUENCE');

    if (Parser.IdentLast.FType <> ttBegin) then
      raise Exception.Create('compiler error: END SEQUENCE');

    Parser.FIdentList.Delete(Parser.FIdentList.Count-1);

  end else if (Copy(Line, 1, 3) = 'IF ') then
  begin

    bExecute := True;

    if (Parser.FIdentList.Count > 0) then
      bExecute := Parser.IdentLast.FExecute and
                  (Parser.IdentLast.FCondicion <> Parser.IdentLast.FIfElse);

    Ident := TIdent.Create;

    with Ident do
    begin
      FType := ttIf;
      FSuspend := True;
      FLine := Index;
      FIfElse := False;
      FCondicion := False;
      FExecute := bExecute;
    end;

    Parser.FIdentList.Add(Ident);

    if bExecute then
      Result := Copy(Line, 4, Length(Line));

  end else if (Line = 'ELSE') then
  begin

    if Parser.FIdentList.Count = 0 then
      raise Exception.Create('ELSE not found IF');

    if Parser.IdentLast.FIfElse then
      raise Exception.Create('ELSE duplicate');

    Parser.IdentLast.FIfElse := True;

  end else if (Line = 'ENDIF') then
  begin

    if (Parser.FIdentList.Count = 0) then
      raise Exception.Create('ENDIF not found IF');

    Parser.FIdentList.Delete(Parser.FIdentList.Count-1);

  end else if (Copy(Line, 1, 9) = 'DO WHILE ') then
  begin

    bExecute := True;

    if (Parser.FIdentList.Count > 0) then
      bExecute := Parser.IdentLast.FExecute and
                  (Parser.IdentLast.FCondicion <> Parser.IdentLast.FIfElse);

    Ident := TIdent.Create;

    with Ident do
    begin
      FType := ttWhile;
      FSuspend := True;
      FLine := Index;
      FIfElse := False;
      FCondicion := False;
      FExecute := bExecute;
    end;

    Parser.FIdentList.Add(Ident);

    if bExecute then
      Result := Copy( Line, 10, Length(Line));

  end else if (Line = 'EXIT') then
  begin

    bExecute := False;

    for i := Parser.FIdentList.Count - 1 downto 0 do
      if (Parser.Idents[i].FType = ttWhile) then
      begin
        bExecute := True;
        Break;
      end;

    if not bExecute then
      raise Exception.Create('EXIT command not found DO WHILE');

    if Parser.IdentLast.FExecute and
       (Parser.IdentLast.FCondicion <> Parser.IdentLast.FIfElse) then
      for i := Parser.FIdentList.Count - 1 downto 0 do
        with Parser.Idents[i] do
        begin
          FExecute := False;
          if FType = ttWhile then
            Break;
        end;  // while

  end else if (Line = 'LOOP') then
  begin

    bExecute := False;

    for i := Parser.FIdentList.Count - 1 downto 0 do
      if (Parser.Idents[i].FType = ttWhile) then
      begin
        bExecute := True;
        Break;
      end;

    if not bExecute then
      raise Exception.Create('LOOP command not found DO WHILE');

    if Parser.IdentLast.FExecute and
      (Parser.IdentLast.FCondicion <> Parser.IdentLast.FIfElse) then
      while (Parser.FIdentList.Count > 0) do
      begin
        if (Parser.IdentLast.FType = ttWhile) then
        begin
          Index := Parser.IdentLast.FLine-1;
          Parser.FIdentList.Delete(Parser.FIdentList.Count-1);
          Break;
        end;
        Parser.FIdentList.Delete(Parser.FIdentList.Count-1);
      end; // while

  end else if (Line = 'ENDDO') then
  begin

    if (Parser.FIdentList.Count = 0) then
      raise Exception.Create('ENDDO not found DO WHILE');

    if (Parser.IdentLast.FType <> ttWhile) then
      raise Exception.Create('Erro: Indent type diferente WHILE');

    if Parser.IdentLast.FCondicion and Parser.IdentLast.FExecute then
      Index := Parser.IdentLast.FLine-1;

    Parser.FIdentList.Delete(Parser.FIdentList.Count-1);

  end else if (Copy(Line, 1, 7) = 'RETURN ') then
  begin

    {f (Index <> FText.Count-1) then
      raise Exception.Create('RETURN not found the end.');}

    if (Parser.FIdentList.Count > 0) then
      raise Exception.Create('Indent not found close.');

    Result := Copy( Line, 8, Length(Line));

  end else if (Parser.FIdentList.Count = 0)  then
    Result := Line

  else if Parser.IdentLast.FExecute and
          (Parser.IdentLast.FCondicion <> Parser.IdentLast.FIfElse) then
    Result := Line;

  Result := Trim(Result);

end;  // RunLine

end.
