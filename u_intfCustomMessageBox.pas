unit u_intfCustomMessageBox;



                                        INTERFACE



uses
  Dialogs, SysUtils, Controls;


  
type
  TStringArray = array of string;
  ICustomMessageBox = interface
  ['{D1AFCD48-37F7-4EC6-A41D-817FAC231A9F}']
    function SetText(message: string): ICustomMessageBox; overload;
    function SetText(message: string; formatparams: array of const): ICustomMessageBox; overload;
    function SetButtons(buttons: array of string): ICustomMessageBox;
    function SetType(&type: TMsgDlgType): ICustomMessageBox;
    function SetDefBtn(default: string; cancel: string = ''): ICustomMessageBox;
    function SetHint(hint: string): ICustomMessageBox;
    function SetVerificationText(txt: string): ICustomMessageBox;
    function SetCaption(caption: string): ICustomMessageBox;    
    function Execute: string;
    function SetBeforeExecute(proc: TProc<ICustomMessageBox>): ICustomMessageBox;
    function GetVerificationValue: Boolean;
    property IsVerificationChecked: Boolean read GetVerificationValue;
    function GetText: string;
    function GetHint: string;
    function GetCaption: string;    
    procedure GetButtons(var arr: TStringArray);
    procedure GetDefBtn(var default, cancel: string);    
    function GetType: TMsgDlgType;    
    function GetUserChoice: string;
    function SetCenter(centeraroundcontrol: TControl): ICustomMessageBox;
  end;
  
resourcestring
  BTN_NO = '&No';
  BTN_YES = '&Yes';
  BTN_OK = '&OK';
  BTN_CANCEL = '&Cancel';
  
function CustomMessageDlg: ICustomMessageBox;
procedure CustomMessageDlg_SetBeforeExecute(callback: TProc<ICustomMessageBox>);
procedure CustomMessageDlg_SetAfterExecute(callback: TProc<ICustomMessageBox>);
type TRefProcOnSetText = reference to procedure(msg: ICustomMessageBox; var text: string);
procedure CustomMessageDlg_OnSetText(callback: TRefProcOnSetText);



///low level
function CreateTaskMessageDlgPosHelp(const ATitle, Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint; X, Y: Integer;
  const HelpFileName: string; DefaultButton: TMsgDlgBtn; sOverrideCaption: string = ''): TCustomTaskDialog;


  
                                        IMPLEMENTATION


                                        
uses
  Consts, Windows, Graphics, Buttons, StdCtrls, MMSystem,
  {$ifdef UNITTESTING}
  TestFramework,
  {$endif UNITTESTING}
  Themes, Math, Classes, Forms;




                                        

function CreateTaskMessageDlgPosHelp(const ATitle, Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint; X, Y: Integer;
  const HelpFileName: string; DefaultButton: TMsgDlgBtn; sOverrideCaption: string = ''): TCustomTaskDialog;
{-----------------------------------------------------------------------------
  Procedure: CreateTaskMessageDlgPosHelp
  Author:    nbi
  Date:      03-May-2012
  Arguments: const Instruction, Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons; HelpCtx: Longint; X, Y: Integer; const HelpFileName: string; DefaultButton: TMsgDlgBtn
  Result:    TCustomTaskDialog
-----------------------------------------------------------------------------}
const
  IconMap: array[TMsgDlgType] of TTaskDialogIcon = (tdiWarning, tdiError,
    tdiInformation, tdiInformation, tdiNone);
  LModalResults: array[TMsgDlgBtn] of Integer = (mrYes, mrNo, mrOk, mrCancel,
    mrAbort, mrRetry, mrIgnore, mrAll, mrNoToAll, mrYesToAll, 0, mrClose);
  ButtonCaptions: array[TMsgDlgBtn] of Pointer = (
    @SMsgDlgYes, @SMsgDlgNo, @SMsgDlgOK, @SMsgDlgCancel, @SMsgDlgAbort,
    @SMsgDlgRetry, @SMsgDlgIgnore, @SMsgDlgAll, @SMsgDlgNoToAll, @SMsgDlgYesToAll,
    @SMsgDlgHelp, @SMsgDlgClose);
  Captions: array[TMsgDlgType] of Pointer = (@SMsgDlgWarning, @SMsgDlgError,
    @SMsgDlgInformation, @SMsgDlgConfirm, nil);
  IconIDs: array[TMsgDlgType] of PChar = (IDI_EXCLAMATION, IDI_HAND,
    IDI_ASTERISK, IDI_QUESTION, nil);
var
  DlgBtn: TMsgDlgBtn;
  LTaskDialog: TCustomTaskDialog;
begin
  LTaskDialog := TCustomTaskDialog.Create(nil);
  try
    // Assign buttons
    for DlgBtn := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
      if DlgBtn in Buttons then
        with LTaskDialog.Buttons.Add do
        begin
          Caption := LoadResString(ButtonCaptions[DlgBtn]);
          Default := DlgBtn = DefaultButton;
          ModalResult := LModalResults[DlgBtn];
        end;

    // Set dialog properties
    with LTaskDialog do
    begin
      if(sOverrideCaption<>'') then
        Caption := sOverrideCaption
      else
      if DlgType <> mtCustom then
        Caption := LoadResString(Captions[DlgType])
      else
        Caption := Application.Title;
      CommonButtons := [];
      if Application.UseRightToLeftReading then
        Flags := Flags + [tfRtlLayout];
      HelpContext := HelpCtx;
      MainIcon :=  IconMap[DlgType];
      Text := Msg;
      Title := ATitle;
    end;

    // Show dialog and return result
    Result := LTaskDialog;//mrNone;
//    if LTaskDialog.Execute then
//      Result := LTaskDialog.ModalResult;
  finally
    //LTaskDialog.Free;
  end;
end;




var
  g_callbackCustomMessageDlg_BeforeExecute: TProc<ICustomMessageBox> = nil;
  g_callbackCustomMessageDlg_AfterExecute: TProc<ICustomMessageBox> = nil;
  g_callbackCustomMessageDlgOnSetText: TRefProcOnSetText = nil;


  
procedure CustomMessageDlg_SetBeforeExecute(callback: TProc<ICustomMessageBox>);
{-----------------------------------------------------------------------------
  Procedure: CustomMessageDlg_SetBeforeExecute
  Author:    nbi
  Date:      20-Jun-2012
  Arguments: callback: TProc<ICustomMessageBox>
  Result:    None
-----------------------------------------------------------------------------}
begin
  g_callbackCustomMessageDlg_BeforeExecute := callback;
end;



procedure CustomMessageDlg_SetAfterExecute(callback: TProc<ICustomMessageBox>);
{-----------------------------------------------------------------------------
  Procedure: CustomMessageDlg_SetAfterExecute
  Author:    nbi
  Date:      06-Nov-2015
  Arguments: callback: TProc<ICustomMessageBox>
  Result:    None
-----------------------------------------------------------------------------}
begin
  g_callbackCustomMessageDlg_AfterExecute := callback;
end;



procedure CustomMessageDlg_OnSetText(callback: TRefProcOnSetText);
{-----------------------------------------------------------------------------
  Procedure: CustomMessageDlg_OnSetText
  Author:    nbi
  Date:      06-Nov-2015
  Arguments: callback: TProc<ICustomMessageBox>
  Result:    None
-----------------------------------------------------------------------------}
begin
  g_callbackCustomMessageDlgOnSetText := callback;
end;



type
  TCustomMessageBox = class(TInterfacedObject, ICustomMessageBox)
  private
    m_text: string;
    m_buttons: array of string;
    m_type: TMsgDlgType;
    m_dlg: TForm;
    m_tskdlg: TCustomTaskDialog;
    m_procBeforeExecute: TProc<ICustomMessageBox>;
    m_defbtn: string;
    m_cancelbtn: string;
    m_hint: string;
    m_vertext: string;
    m_bVerificationValue: Boolean;
    m_sOverrideCaption: string;
    m_answer: string;
    m_centeraroundcontrol: TControl;
    procedure OnVerificationClicked(Sender: TObject);
    procedure OnTaskDialogConstructed_CenterDlg(Sender: TObject);
    procedure DoBeforeExecute;
    procedure DoAfterExecute;
  public
    function SetText(message: string): ICustomMessageBox; overload;
    function SetText(message: string; formatparams: array of const): ICustomMessageBox; overload;
    function SetCaption(caption: string): ICustomMessageBox;
    function SetButtons(buttons: array of string): ICustomMessageBox;
    function SetType(&type: TMsgDlgType): ICustomMessageBox;
    function Execute: string;  
    function ExecuteUsingTaskDialog: string;
    function SetDefBtn(defaultbutton: string; cancelbutton: string): ICustomMessageBox;
    function SetBeforeExecute(proc: TProc<ICustomMessageBox>): ICustomMessageBox;
    constructor Create;
    destructor Destroy; override;
    function setHint(hint: string): ICustomMessageBox;
    function setVerificationText(txt: string): ICustomMessageBox;
    function GetVerificationValue: Boolean;
    //n@2015-11-06
    function GetText: string;
    function GetHint: string;
    function GetCaption: string;    
    procedure GetButtons(var arr: TStringArray);
    procedure GetDefBtn(var default, cancel: string);    
    function GetType: TMsgDlgType;
    function GetUserChoice: string;
    function SetCenter(centeraroundcontrol: TControl): ICustomMessageBox;
  end;


  
constructor TCustomMessageBox.Create;
{-----------------------------------------------------------------------------
  Procedure: Create
  Author:    nbi
  Date:      20-Apr-2012
  Arguments: None
  Result:    None
-----------------------------------------------------------------------------}
begin
  m_procBeforeExecute := nil;
  m_dlg := nil;
  m_tskdlg := nil;
  m_centeraroundcontrol := nil;
  m_text := '';
  m_cancelbtn := '';
  m_defbtn := '';
  SetLength(m_buttons, 0);
  m_type := mtCustom;
  m_vertext := '';
  m_bVerificationValue := False;
  m_sOverrideCaption := '';
  m_answer := '';
  inherited;
end;



destructor TCustomMessageBox.Destroy;
{-----------------------------------------------------------------------------
  Procedure: Destroy
  Author:    nbi
  Date:      20-Apr-2012
  Arguments: None
  Result:    None
-----------------------------------------------------------------------------}
begin
  if(m_dlg<>nil) then 
    m_dlg.Free;
  if(m_tskdlg<>nil) then 
    m_tskdlg.Free;
  inherited;
end;



procedure TCustomMessageBox.DoBeforeExecute;
{-----------------------------------------------------------------------------
  Procedure: DoBeforeExecute
  Author:    nbi
  Date:      20-Jun-2012
  Arguments: None
  Result:    None
-----------------------------------------------------------------------------}
begin
  if(Assigned(m_procBeforeExecute)) then
    m_procBeforeExecute(Self)
  else
  if(Assigned(g_callbackCustomMessageDlg_BeforeExecute)) then
    g_callbackCustomMessageDlg_BeforeExecute(Self);
end;




procedure TCustomMessageBox.DoAfterExecute;
{-----------------------------------------------------------------------------
  Procedure: DoAfterExecute
  Author:    nbi
  Date:      20-Jun-2012
  Arguments: None
  Result:    None
-----------------------------------------------------------------------------}
begin
  if(Assigned(g_callbackCustomMessageDlg_AfterExecute)) then
    g_callbackCustomMessageDlg_AfterExecute(Self);
end;




function TCustomMessageBox.Execute: string;
{-----------------------------------------------------------------------------
  Procedure: Execute
  Author:    nbi
  Date:      20-Apr-2012
  Arguments: None
  Result:    string
-----------------------------------------------------------------------------}

    function GetAveCharSize(Canvas: TCanvas): TPoint;
    var
      I: Integer;
      Buffer: array[0..51] of Char;
    begin
      for I := 0 to 25 do Buffer[I] := Chr(I + Ord('A'));
      for I := 0 to 25 do Buffer[I + 26] := Chr(I + Ord('a'));
      GetTextExtentPoint(Canvas.Handle, Buffer, 52, TSize(Result));
      Result.X := Result.X div 52;
    end;


var
  DialogUnits: TPoint;
  btns: TMsgDlgButtons;
  res: Integer;
  i: Integer;
  j: Integer;
  btn: TButton;
  b1: boolean;
  b2: boolean;
  ButtonCount: Integer;
  ButtonWidth: Integer;
  ButtonSpacing: Integer;
  ButtonGroupWidth: Integer;
  x: Integer;
  HorzMargin: Integer;
  ButtonHeight: Integer;
const
  mcHorzMargin = 8;
begin
  if(Length(m_buttons)=0) then begin
    if(m_type=mtConfirmation) then begin
      SetLength(m_buttons, 2);
      m_buttons[0] := BTN_YES;
      m_buttons[1] := BTN_NO;
    end else begin
      SetLength(m_buttons, 1);
      m_buttons[0] := BTN_OK;
    end;
  end;

  ASSERT(Length(m_buttons)>0, 'No TCustomMessageBox.SetButtons called');
  if(m_defbtn='') then m_defbtn := m_buttons[0];
  if(m_cancelbtn='') and (Length(m_buttons)=1) then m_cancelbtn := m_buttons[0];
  if(m_cancelbtn='') and (Length(m_buttons)=2) then begin
    i := 1; /// cancel e wtoria buton
    if(m_defbtn=m_buttons[1]) then i := 0; /// ako default e wtoria - neka cancel e pyrwiq 
    m_cancelbtn := m_buttons[i];
  end;

  /// some heuristic:
  if(m_type=mtCustom) then begin
    if(Length(m_buttons)>1) then
      m_type := mtConfirmation
    else
      m_type := mtInformation;
  end;

  if(m_type in [mtWarning, mtError]) then 
    PlaySound(PChar('SystemExclamation'), 0, SND_ALIAS or SND_ASYNC or SND_NOWAIT);
  

  //////////////////////////  DEFLECT TO TASKDIALOG ///////////////////
  if (Win32MajorVersion>=6) and UseLatestCommonDialogs and ThemeServices.ThemesEnabled then
    EXIT(ExecuteUsingTaskDialog);
  /////////////////////////////////////////////////////////////////////

  // go on with classic xp dialog:
    
  ButtonCount := Length(m_buttons);
  ButtonWidth := 0;
  
  btns := [mbYes];
  if(ButtonCount>1) then btns := btns + [mbNo];
  if(ButtonCount>2) then btns := btns + [mbOk];
  if(ButtonCount>3) then btns := btns + [mbCancel];
  if(ButtonCount>4) then btns := btns + [mbAbort];

  if(m_hint<>'') then
    m_text := m_text + sLineBreak + sLineBreak + 'Hint:'+ sLineBreak + m_hint;
  
  m_dlg := CreateMessageDialog(m_text, m_type, btns, mbClose);

  /// shits stolen from dialogs.pas:
  DialogUnits := GetAveCharSize(m_dlg.Canvas);
  HorzMargin := MulDiv(mcHorzMargin, DialogUnits.X, 4);
  
  for I := Low(m_buttons) to high(m_buttons) do
    ButtonWidth := Max(ButtonWidth, m_dlg.Canvas.TextExtent('__'+m_buttons[i]+'__').cx);

  if(ButtonWidth<(HorzMargin*6)) then
    ButtonWidth := HorzMargin*6;

  ButtonHeight := trunc(m_dlg.Canvas.TextExtent(' '+m_buttons[0]+' ').cy * 2);

  ButtonSpacing := m_dlg.Canvas.textextent('__').cx;
    
  ButtonGroupWidth := ButtonWidth * ButtonCount + ButtonSpacing * (ButtonCount - 1);

  if(ButtonGroupWidth>m_dlg.ClientWidth) then
    m_dlg.ClientWidth := Max(32, ButtonGroupWidth) + HorzMargin * 2; //predpolagame che shirinata na ikonata e 32px
  /// end of stolen shits

  j := 0;
  b1 := False;
  b2 := False;
  x := 0;
        
  for i := 0 to m_dlg.ControlCount-1 do
   if(m_dlg.Controls[i] is TButton) then begin
     btn := TButton(m_dlg.Controls[i]);
     btn.Caption := m_buttons[j];
     
     btn.default := ((x=0) and (m_defbtn='')) or (AnsiSameText(m_buttons[j],m_defbtn));
     if(btn.default) then
       m_dlg.ActiveControl := btn;
       
     btn.Cancel := (m_buttons[j]=m_cancelbtn);

     if(x=0) then begin
       x := m_dlg.ClientWidth div 2 - ButtonGroupWidth div 2;// - HorzMargin div 2;//(m_dlg.ClientWidth - ButtonGroupWidth) div 2;
     end;
       
     btn.Width := ButtonWidth;
     btn.top := btn.top - (ButtonHeight-btn.Height);
     btn.Height := ButtonHeight;
     btn.Left := x;

     x := x + ButtonWidth + ButtonSpacing;
     
     b1 := b1 or (m_defbtn='') or (AnsiSameText(m_buttons[j],m_defbtn));
     b2 := b2 or (m_cancelbtn='') or (AnsiSameText(m_buttons[j],m_cancelbtn));
     
     Inc(j);
   end;

  ASSERT(b1, 'TCustomMessageBox: Default button not amongst the button set');
  ASSERT(b2, 'TCustomMessageBox: Cancel button not amongst the button set');

  DoBeforeExecute;
  
  try
    res := m_dlg.ShowModal;
  
    if(res=mrCancel) then EXIT('');

    for i := 0 to m_dlg.ControlCount-1 do if(m_dlg.Controls[i] is TButton) then 
    begin
      btn := TButton(m_dlg.Controls[i]);
     
      if(btn.ModalResult=res) then
        EXIT(btn.Caption);
    end;

    EXIT('');

  finally
    m_answer := Result;
    DoAfterExecute;
  end;
  
end;





function TCustomMessageBox.ExecuteUsingTaskDialog: string;
{-----------------------------------------------------------------------------
  Procedure: ExecuteUsingTaskDialog
  Author:    nbi
  Date:      03-May-2012
  Arguments: None
  Result:    string
-----------------------------------------------------------------------------}
var
  btns: TMsgDlgButtons;
  j: Integer;  
  btn: TTaskDialogBaseButtonItem;
  b1: boolean;
  defbtn: TMsgDlgBtn;
  it: TCollectionItem;

  k: Integer;
  procedure addbtn(btn: TMsgDlgBtn); begin
    if(k >= length(m_buttons)) then EXIT;
    Include(btns, btn);
    if(AnsiSameText(m_defbtn, m_buttons[k])) then defbtn:=btn;
    Inc(k);
  end;

const
  BTNROW : array [0..4] of TTaskDialogCommonButton = (tcbOk, tcbYes, tcbNo, tcbCancel, tcbRetry);
  
begin
  ASSERT ((Win32MajorVersion >= 6) and UseLatestCommonDialogs and ThemeServices.ThemesEnabled);

  btns := []; k := 0; defbtn := mbYes;
  addbtn(mbOk);
  addbtn(mbYes);
  addbtn(mbNo);
  addbtn(mbCancel);
  addbtn(mbRetry);
  
  ASSERT(Length(m_buttons)>0, 'No TCustomMessageBox.SetButtons called');
  if(m_defbtn='') then m_defbtn := m_buttons[0];
  if(m_cancelbtn='') and (Length(m_buttons)=1) then m_cancelbtn := m_buttons[0];
  if(m_cancelbtn='') and (Length(m_buttons)=2) then begin
    j := 1; /// cancel e wtoria buton
    if(m_defbtn=m_buttons[1]) then j := 0; /// ako default e wtoria - neka cancel e pyrwiq 
    m_cancelbtn := m_buttons[j];
  end;
  assert( (m_cancelbtn<>'') or (Length(m_buttons)<2), '[Dlg] No cancel btn and more than 2 buttons: It is best if you invoke SetDefBtn in this case...');
  
  m_tskdlg := CreateTaskMessageDlgPosHelp('', m_text, m_type, btns, 0, -1, -1, '', defbtn, m_sOverrideCaption);//CreateMessageDialog(m_text, m_type, btns, mbClose);

  if(m_centeraroundcontrol<>nil) then
    m_tskdlg.OnDialogConstructed := OnTaskDialogConstructed_CenterDlg;

  j := 0;
  b1 := False;
        
  for it in m_tskdlg.buttons do begin
    btn := TTaskDialogBaseButtonItem(it);
    btn.Caption := m_buttons[j];
    if(AnsiSameText(m_buttons[j],m_defbtn)) then begin
      btn.default := true;
      m_tskdlg.Buttons.DefaultButton := btn;
      m_tskdlg.DefaultButton := BTNROW[j];
    end;
    b1 := b1 or (m_defbtn='') or (btn.default);
    Inc(j);
  end;

  ASSERT(b1, 'TCustomMessageBox: Default button not amongst the button set');
  //ASSERT(b2, 'TCustomMessageBox: Cancel button not amongst the button set');}

  if(m_hint<>'') then
    m_tskdlg.ExpandedText := m_hint;
  
  DoBeforeExecute();

  m_tskdlg.VerificationText := m_vertext;
  m_tskdlg.OnVerificationClicked := Self.OnVerificationClicked;
  
  if(not m_tskdlg.Execute) or (m_tskdlg.Button=nil) then 
    EXIT(m_cancelbtn);

  m_answer := m_tskdlg.Button.Caption;

  Result := m_answer;

  DoAfterExecute;

end;




procedure TCustomMessageBox.GetButtons(var arr: TStringArray);
{-----------------------------------------------------------------------------
  Procedure: GetButtons
  Author:    nbi
  Date:      06-Nov-2015
  Arguments: var arr: array of string
  Result:    None
-----------------------------------------------------------------------------}
var
  i: Integer;
begin
  setLength(arr, Length(m_buttons));
  for i := low(m_buttons) to high(m_buttons) do 
    arr[i] := m_buttons[i];
end;



function TCustomMessageBox.GetCaption: string;
{-----------------------------------------------------------------------------
  Procedure: GetCaption
  Author:    nbi
  Date:      06-Nov-2015
  Arguments: None
  Result:    string
-----------------------------------------------------------------------------}
begin
  Result := m_sOverrideCaption;
end;



procedure TCustomMessageBox.GetDefBtn(var default, cancel: string);
{-----------------------------------------------------------------------------
  Procedure: GetDefBtn
  Author:    nbi
  Date:      06-Nov-2015
  Arguments: var default, cancel: string
  Result:    None
-----------------------------------------------------------------------------}
begin
  default := m_defbtn;
  cancel := m_cancelbtn;  
end;



function TCustomMessageBox.GetHint: string;
{-----------------------------------------------------------------------------
  Procedure: GetHint
  Author:    nbi
  Date:      06-Nov-2015
  Arguments: None
  Result:    string
-----------------------------------------------------------------------------}
begin
  Result := m_hint;
end;



function TCustomMessageBox.GetText: string;
{-----------------------------------------------------------------------------
  Procedure: GetText
  Author:    nbi
  Date:      06-Nov-2015
  Arguments: None
  Result:    string
-----------------------------------------------------------------------------}
begin
  Result := m_text;
end;



function TCustomMessageBox.GetType: TMsgDlgType;
{-----------------------------------------------------------------------------
  Procedure: GetType
  Author:    nbi
  Date:      06-Nov-2015
  Arguments: None
  Result:    TMsgDlgType
-----------------------------------------------------------------------------}
begin
  Result := m_type;
end;



function TCustomMessageBox.GetUserChoice: string;
{-----------------------------------------------------------------------------
  Procedure: GetUserChoice
  Author:    nbi
  Date:      06-Nov-2015
  Arguments: None
  Result:    string
-----------------------------------------------------------------------------}
begin
  Result := m_answer;
end;



function TCustomMessageBox.GetVerificationValue: Boolean;
{-----------------------------------------------------------------------------
  Procedure: GetVerificationValue
  Author:    nbi
  Date:      25-Jul-2014
  Arguments: None
  Result:    Boolean
-----------------------------------------------------------------------------}
begin
  Result := m_bVerificationValue;
end;



procedure TCustomMessageBox.OnTaskDialogConstructed_CenterDlg(Sender: TObject);
{-----------------------------------------------------------------------------
  Procedure: OnTaskDialogConstructed
  Author:    nbi
  Date:      06-Nov-2015
  Arguments: Sender: TObject
  Result:    None
-----------------------------------------------------------------------------}
var
  origin: TPoint;
  c1: TPoint;
  r: TRect;
  c2: TPoint;
  p: TPoint;  

  function CenterOf(b: TRect): TPoint;
  begin
    Result.x := (b.Right-b.Left) div 2;
    Result.y:= (b.Bottom-b.Top) div 2;
  end;
  
begin
  if(m_centeraroundcontrol.Parent<>nil) then
    origin := m_centeraroundcontrol.Parent.ClientToScreen(m_centeraroundcontrol.BoundsRect.TopLeft)
  else
    origin := m_centeraroundcontrol.ClientToScreen(m_centeraroundcontrol.ClientRect.TopLeft);

  c1 := CenterOf(m_centeraroundcontrol.ClientRect);

  GetWindowRect(m_tskdlg.Handle, r);
  c2 := CenterOf(r);
  
  p.x := origin.x + c1.x - c2.x;
  p.y := origin.y + c1.y - c2.y;

  SetWindowPos(m_tskdlg.Handle, 0, p.x, p.y, 0, 0, SWP_NOREDRAW or SWP_NOSIZE or SWP_NOZORDER);
end;



procedure TCustomMessageBox.OnVerificationClicked(Sender: TObject);
{-----------------------------------------------------------------------------
  Procedure: OnVerificationClicked
  Author:    nbi
  Date:      25-Jul-2014
  Arguments: Sender: TObject
  Result:    None
-----------------------------------------------------------------------------}
begin
  m_bVerificationValue := tfVerificationFlagChecked in m_tskdlg.Flags;
end;




function TCustomMessageBox.SetText(message: string; formatparams: array of const): ICustomMessageBox;
{-----------------------------------------------------------------------------
  Procedure: SetText
  Author:    nbi
  Date:      09-May-2012
  Arguments: message: string; formatparams: array of const
  Result:    ICustomMessageBox
-----------------------------------------------------------------------------}  
begin
  if(Assigned(g_callbackCustomMessageDlgOnSetText)) then
    g_callbackCustomMessageDlgOnSetText(Self, message);
    
  Result := SetText(Format(message,formatparams));
end;



function TCustomMessageBox.SetCaption(caption: string): ICustomMessageBox;
{-----------------------------------------------------------------------------
  Procedure: SetCaption
  Author:    nbi
  Date:      22-Jul-2015
  Arguments: caption: string
  Result:    ICustomMessageBox
-----------------------------------------------------------------------------}
begin
  m_sOverrideCaption := Caption;
  
  Result := Self;
end;



function TCustomMessageBox.SetCenter(centeraroundcontrol: TControl): ICustomMessageBox;
{-----------------------------------------------------------------------------
  Procedure: SetCenter
  Author:    nbi
  Date:      06-Nov-2015
  Arguments: centeraroundcontrol: TControl
  Result:    ICustomMessageBox
-----------------------------------------------------------------------------}
begin
  m_centeraroundcontrol := centeraroundcontrol;

  Result := Self;
end;




function TCustomMessageBox.SetType(&type: TMsgDlgType): ICustomMessageBox;
{-----------------------------------------------------------------------------
  Procedure: SetType
  Author:    nbi
  Date:      20-Apr-2012
  Arguments: &type: TMsgDlgType
  Result:    ICustomMessageBox
-----------------------------------------------------------------------------}
begin
  m_type := &type;
  Result := Self;
end;




function TCustomMessageBox.setVerificationText(txt: string): ICustomMessageBox;
{-----------------------------------------------------------------------------
  Procedure: setVerificationText
  Author:    nbi
  Date:      25-Jul-2014
  Arguments: txt: string
  Result:    ICustomMessageBox
-----------------------------------------------------------------------------}
begin
  m_vertext := txt;
  Result := Self;
end;




function TCustomMessageBox.SetButtons(buttons: array of string): ICustomMessageBox;
{-----------------------------------------------------------------------------
  Procedure: SetButtons
  Author:    nbi
  Date:      20-Apr-2012
  Arguments: buttons: array of string
  Result:    ICustomMessageBox
-----------------------------------------------------------------------------}
var
  i: integer;
  ofs: Integer;
begin
  ofs := Length(m_buttons);
  SetLength(m_buttons, ofs+Length(buttons));
  for i := low(buttons) to High(buttons) do
    m_buttons[ofs+i] := buttons[i];
  Result := Self;
end;




function TCustomMessageBox.SetDefBtn(defaultbutton: string; cancelbutton: string): ICustomMessageBox;
{-----------------------------------------------------------------------------
  Procedure: SetDefBtn
  Author:    nbi
  Date:      20-Apr-2012
  Arguments: defaultbutton: string
  Result:    ICustomMessageBox
-----------------------------------------------------------------------------}
begin
  Result := Self;
  m_defbtn := defaultbutton;
  m_cancelbtn := cancelbutton;
end;




function TCustomMessageBox.setHint(hint: string): ICustomMessageBox;
{-----------------------------------------------------------------------------
  Procedure: setHint
  Author:    nbi
  Date:      28-Nov-2012
  Arguments: hint: string
  Result:    ICustomMessageBox
-----------------------------------------------------------------------------}
begin
  m_hint := hint;
  Result := Self;
end;




function TCustomMessageBox.SetText(message: string): ICustomMessageBox;
{-----------------------------------------------------------------------------
  Procedure: SetText
  Author:    nbi
  Date:      20-Apr-2012
  Arguments: message: string
  Result:    ICustomMessageBox
-----------------------------------------------------------------------------}
begin
  if(assigned(g_callbackCustomMessageDlgOnSetText)) then
    g_callbackCustomMessageDlgOnSetText(Self, message);
  m_text := message;
  Result := Self;
end;



function TCustomMessageBox.SetBeforeExecute(proc: TProc<ICustomMessageBox>): ICustomMessageBox;
{-----------------------------------------------------------------------------
  Procedure: BeforeExecute
  Author:    nbi
  Date:      20-Apr-2012
  Arguments: proc: TProc
  Result:    ICustomMessageBox
-----------------------------------------------------------------------------}
begin
  m_procBeforeExecute := proc;
  Result := Self;
end;




function CustomMessageDlg: ICustomMessageBox;
begin
  Result := TCustomMessageBox.Create;
end;



{$ifdef UNITTESTING}
type
  TTestCustomMessageDialog = class(TTestCase)
  strict private
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure test_CustomMessageDlg();
    procedure test_CustomMessageDlg_Center();
    procedure test_CustomMessageDlg_OtherDefaultButton();
    procedure test_CustomMessageDlg_3Buttons();
    procedure test_CustomMessageDlg_NoSetDefBtn_NoSetType;
  end;

{ TTestCustomMessageDialog }

procedure TTestCustomMessageDialog.SetUp;
begin
  inherited;
  
end;

procedure TTestCustomMessageDialog.TearDown;
begin
  inherited;

end;

procedure TTestCustomMessageDialog.test_CustomMessageDlg;
var
  dlg: ICustomMessageBox;
begin
  dlg := CustomMessageDlg.SetText(
           'Testing mtWarning '+sLineBreak+
           'line2.1')
         .SetType(mtWarning)
         .SetButtons(['button1','button2'])
         .SetDefBtn('button1');
  
  dlg.Execute;
  
  dlg.settype(mtError);
  dlg.SetText(
           'Testing mtError '+sLineBreak+
           'line2.2');
  dlg.Execute;
  
  dlg.settype(mtInformation);
  dlg.SetText(
           'Testing mtInformation '+sLineBreak+
           'line2.3');
  dlg.Execute;
  //ShowMessage(res);
end;




procedure TTestCustomMessageDialog.test_CustomMessageDlg_Center;
var
  dlg: ICustomMessageBox;
  frm: TForm;
begin
  frm := TForm.Create(nil);
  frm.Left := 30;
  frm.top := 30;  
  frm.width := 530;
  frm.height := 430;  
  frm.show;
  
  dlg := CustomMessageDlg.SetText(
           'Testing CustomMessageDlg '+sLineBreak+
           'line2')
         .SetType(mtWarning)
         .SetButtons(['button1','button2'])
         .SetDefBtn('button1')
         .setcenter(frm);

  dlg.Execute;

  frm.Left := Screen.Width - frm.Width;
  dlg.Execute;

  frm.Left := Screen.Width div 2 - frm.Width div 2;
  frm.top := Screen.Height - frm.Height;
  dlg.Execute;
         
  //res := dlg.Execute;
  //ShowMessage(res);

  frm.Free;
end;




procedure TTestCustomMessageDialog.test_CustomMessageDlg_OtherDefaultButton;
var
  res: string;
begin
  res := CustomMessageDlg.SetText(
           'Lorem Ipsum ............ '+sLineBreak+
           'testing setting second button to be default')
         .SetType(mtWarning)
         .SetButtons(['nondefault button','default button'])
         .SetDefBtn('default button')
         .Execute;
  ShowMessage(res);
end;


procedure TTestCustomMessageDialog.test_CustomMessageDlg_3Buttons;
var
  res: string;
begin
  res := CustomMessageDlg.SetText(
           'Lorem Ipsum ............ '+sLineBreak+
           'testing 3 buttons')
         .SetType(mtWarning)
         .SetButtons(['cancel button','default button', 'button3'])
         .SetDefBtn('default button','cancel button')
         .Execute;
  ShowMessage(res);
end;


procedure TTestCustomMessageDialog.test_CustomMessageDlg_NoSetDefBtn_NoSetType;
var
  res: string;
begin
  res := CustomMessageDlg.SetText(
           'Lorem Ipsum ............ '+sLineBreak+
           'testing 2 buttons, no type set, should be confirmation, 1st button should be default, 2nd should be cancel')
         .SetButtons(['default button', 'nondefault button'])
         .Execute;
         
  res := CustomMessageDlg.SetText(
           'Lorem Ipsum ............ '+sLineBreak+
           'testing 1 button only, no type set - should be info')
         .SetButtons(['sole button'])
         .Execute;
end;
{$endif UNITTESTING}
    

    
initialization
{$ifdef UNITTESTING}
  RegisterTest('With Interactive UI', TTestCustomMessageDialog.Suite);
{$endif UNITTESTING}
end.
