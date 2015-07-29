unit u_multicast;
{
    Copyright (c) 2014 Nedko Ivanov

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the Software
    is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
    OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}


                           INTERFACE


                           
uses
  OnlyInterfaces, SysUtils;

type
  IMulticastSubscriptionToken = interface(IInterface)
  end;
  
  IMultiCastEventBase = interface
    ['{2008A157-9126-4E95-B1CC-0CD3FD6C4B40}']
    procedure Unsubscribe(token: IMulticastSubscriptionToken);
  end;
  
  IMultiCastEvent = interface(IMultiCastEventBase)
    ['{0B52BD2C-B666-46B0-A37F-586EBAC935B2}']
    function Subscribe(callback: TProc): IMulticastSubscriptionToken;
  end;

  IMultiCastEventE = interface(IMultiCastEventBase)
    ['{2933A455-40D5-415F-96D8-BD2BB80D7F67}']
    function Subscribe(callback: TEntParamedRef): IMulticastSubscriptionToken;
  end;

  IMultiCastEventFirer = interface
    ['{F8C3610C-A5E2-4D37-AE9C-27951D2D0BB2}']
    procedure DoEvent(ent: IEntity = nil);
  end;


function newMulticast: IMultiCastEvent;
function newMulticastE: IMultiCastEventE;

procedure fireMC(mc: IMultiCastEvent);
  
                         IMPLEMENTATION




uses
  Windows
  {$ifdef UNITTESTING}, TestFramework{$endif}
  , u_utlLeakMonitor, u_utlEntityTheory, u_Ini;

type
  TMultiCastEvent = class(TInterfacedObject, IMultiCastEvent, IMultiCastEventE, IMultiCastEventFirer)
  private
    m_nId: Integer;
    m_subscribers: IEntity;
    m_subscribers2: IEntity;
    {$ifdef STACKTRACES}m_st: string;{$endif STACKTRACES}
  public
    constructor Create;
    destructor Destroy; override;
    function Subscribe(callback: TEntParamedRef): IMulticastSubscriptionToken; overload;
    function Subscribe(callback: TProc): IMulticastSubscriptionToken; overload;
    procedure Unsubscribe(token: IMulticastSubscriptionToken);
    procedure DoEvent(ent: IEntity);
  end;


  TSubscriptionId = string;
  IMulticastSubscriptionTokenInternal = interface(IMulticastSubscriptionToken)
    ['{9AF33996-C068-4D57-B8DE-B7953AE94EF1}']
    function GetId: TSubscriptionId;
  end;
  
type
  TMulticastSubscriptionToken = class(TInterfacedObject, IMulticastSubscriptionToken, IMulticastSubscriptionTokenInternal)
  private
    m_sId: TSubscriptionId;
    m_owner: IMultiCastEvent;
    {$ifdef STACKTRACES}m_st: string;{$endif STACKTRACES}
  public
    constructor Create(AOwner: IMultiCastEvent; id: TSubscriptionId);
    destructor Destroy; override;
    function GetId: TSubscriptionId;
  end;


function newSubscrToken(AOwner: IMultiCastEvent; id: Integer): IMulticastSubscriptionTokenInternal;
{-----------------------------------------------------------------------------
  Procedure: newSubscrToken
  Author:    nbi
  Date:      26-Sep-2014
  Arguments: id: Integer
  Result:    IMulticastSubscriptionTokenInternal
-----------------------------------------------------------------------------}
begin
  Result := TMulticastSubscriptionToken.Create(AOwner, IntToHex(id, 4));
end;


  
constructor TMulticastSubscriptionToken.Create(AOwner: IMultiCastEvent; id: TSubscriptionId);
{-----------------------------------------------------------------------------
  Procedure: Create
  Author:    nbi
  Date:      26-Sep-2014
  Arguments: id: TSubscriptionId
  Result:    None
-----------------------------------------------------------------------------}
begin
  m_sId := id;
  {$ifdef STACKTRACES}m_st := stacktrace;{$endif STACKTRACES}
  m_owner := AOwner;
end;



destructor TMulticastSubscriptionToken.Destroy;
{-----------------------------------------------------------------------------
  Procedure: Destroy
  Author:    nbi
  Date:      26-Sep-2014
  Arguments: None
  Result:    None
-----------------------------------------------------------------------------}
begin
  _addref;  {$message hint 'investigate this, without addref it falls into destroy recursion'}
  if(m_owner<>nil) then
    m_owner.Unsubscribe(self);
  //_release;
  inherited;
end;



function TMulticastSubscriptionToken.GetId: TSubscriptionId;
{-----------------------------------------------------------------------------
  Procedure: GetId
  Author:    nbi
  Date:      26-Sep-2014
  Arguments: None
  Result:    TSubscriptionId
-----------------------------------------------------------------------------}
begin
  Result := m_sId;
end;


  
function newMulticast: IMultiCastEvent;
{-----------------------------------------------------------------------------
  Procedure: newMulticast
  Author:    nbi
  Date:      09-Sep-2014
  Arguments: None
  Result:    IMultiCastEvent
-----------------------------------------------------------------------------}
begin
  Result := TMultiCastEvent.Create;
end;



procedure fireMC(mc: IMultiCastEvent);
{-----------------------------------------------------------------------------
  Procedure: fireMC
  Author:    nbi
  Date:      14-Oct-2014
  Arguments: mc: IMultiCastEvent
  Result:    None
-----------------------------------------------------------------------------}
begin
  (mc as IMultiCastEventFirer).DoEvent();
end;


  
function newMulticastE: IMultiCastEventE;
{-----------------------------------------------------------------------------
  Procedure: newMulticast
  Author:    nbi
  Date:      09-Sep-2014
  Arguments: None
  Result:    IMultiCastEvent
-----------------------------------------------------------------------------}
begin
  Result := TMultiCastEvent.Create;
end;


  
{ TMultiCastEvent }

constructor TMultiCastEvent.Create;
{-----------------------------------------------------------------------------
  Procedure: Create
  Author:    nbi
  Date:      09-Sep-2014
  Arguments: None
  Result:    None
-----------------------------------------------------------------------------}
begin
  m_nId := 1;
  {$ifdef STACKTRACES}m_st := stacktrace;{$endif STACKTRACES}
end;



destructor TMultiCastEvent.Destroy;
{-----------------------------------------------------------------------------
  Procedure: Destroy
  Author:    nbi
  Date:      09-Sep-2014
  Arguments: None
  Result:    None
-----------------------------------------------------------------------------}
begin
  m_subscribers := nil;
  inherited;
end;



procedure TMultiCastEvent.DoEvent(ent: IEntity);
{-----------------------------------------------------------------------------
  Procedure: DoEvent
  Author:    nbi
  Date:      09-Sep-2014
  Arguments: ent: IEntity
  Result:    None
-----------------------------------------------------------------------------}
var
  pr: IEntityProp;
  u: ITProcHolderParamEnt;
  t: ITProcHolder;  
begin
  if(m_subscribers=nil) and (m_subscribers2=nil) then EXIT;

  if(m_subscribers<>nil) then begin
    ASSERT(ent=nil);
    for pr in m_subscribers do begin
      u := pr.ValueAsIntf as ITProcHolderParamEnt;
      (u.gett()).Invoke(ent);
    end;
  end;  

  if(m_subscribers2<>nil) then begin
    for pr in m_subscribers2 do begin
      t := pr.ValueAsIntf as ITProcHolder;
      (t.gett()).Invoke();
    end;
  end;  
end;




function TMultiCastEvent.Subscribe(callback: TProc): IMulticastSubscriptionToken;
{-----------------------------------------------------------------------------
  Procedure: Subscribe
  Author:    nbi
  Date:      09-Sep-2014
  Arguments: None
  Result:    IMulticastSubscriptionToken
-----------------------------------------------------------------------------}
var
  t: IMulticastSubscriptionTokenInternal;
begin
  if(m_subscribers2=nil) then m_subscribers2:=newent;

  m_subscribers2.Add(IntToHex(m_nId,4), newTProcHolder(callback));

  t := newSubscrToken(Self, m_nId);
  InterlockedIncrement(m_nId);
  Result := t;
end;




function TMultiCastEvent.Subscribe(callback: TEntParamedRef): IMulticastSubscriptionToken;
{-----------------------------------------------------------------------------
  Procedure: Subscribe
  Author:    nbi
  Date:      09-Sep-2014
  Arguments: callback: TEntParamedRef
  Result:    IMulticastSubscriptionToken
-----------------------------------------------------------------------------}
var
  t: IMulticastSubscriptionTokenInternal;
begin
  if(m_subscribers=nil) then m_subscribers:=newent;
  
  m_subscribers.Add(IntToHex(m_nId,4), newTProcHolder3(callback));

  t := newSubscrToken(Self, m_nId);
  InterlockedIncrement(m_nId);

  Result := t;
end;




procedure TMultiCastEvent.Unsubscribe(token: IMulticastSubscriptionToken);
{-----------------------------------------------------------------------------
  Procedure: Unsubscribe
  Author:    nbi
  Date:      09-Sep-2014
  Arguments: id: IMulticastSubscriptionToken
  Result:    None
-----------------------------------------------------------------------------}
var
  t: IMulticastSubscriptionTokenInternal;
begin
  ASSERT((m_subscribers<>nil) or (m_subscribers2<>nil));

  if(m_subscribers<>nil) then begin
    t := token as IMulticastSubscriptionTokenInternal;
    m_subscribers.Del( t.GetId );
  end;
    
  if(m_subscribers2<>nil) then
    m_subscribers2.Del((token as IMulticastSubscriptionTokenInternal).getid);
end;


{$region 'TTest_Multicast'}
{$ifdef UNITTESTING}

////
/// this test case uses mockup units: Test\mockup\u_Card.pas Test\mockup\u_clsDmManager.pas Test\mockup\u_dm.pas
///

type
  TTest_Multicast = class(TTestCase)
  strict private
//    m_stz: TSTZ;
//    procedure entryAt(dt: TDateTime);
//    procedure exitAt(dt: TDateTime);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure test_normal();
    procedure test_unsubscr();
  end;

procedure TTest_Multicast.SetUp; 
begin

end;

procedure TTest_Multicast.TearDown; 
begin

end;



procedure TTest_Multicast.test_normal();
{-----------------------------------------------------------------------------
  Procedure: test_normal
  Author:    nbi
  Date:      09-Sep-2014
  Arguments: 
  Result:    None
-----------------------------------------------------------------------------}
var
  mc: IMultiCastEventE;
  i: integer;
begin
  i := 0;

  mc := newmulticastE;
  
  mc.subscribe(procedure(e: IEntity) begin 
    Inc(i);
  end);

  mc.subscribe(procedure(e: IEntity) begin 
    Inc(i);
  end);

  (mc as IMultiCastEventFirer).DoEvent(nil);
  
  checktrue(i=2);
end;




procedure TTest_Multicast.test_unsubscr();
var
  mc: IMultiCastEventE;
  i: integer;
  token1: IMulticastSubscriptionToken;
  token2: IMulticastSubscriptionToken;  
begin
  i := 0;

  mc := newmulticastE;
  
  token1 := mc.subscribe(procedure(e: IEntity) begin 
    Inc(i);
  end);

  token2 := mc.subscribe(procedure(e: IEntity) begin 
    Inc(i);
  end);

  mc.Unsubscribe(token1);
  
  (mc as IMultiCastEventFirer).DoEvent(nil);
  //mc := nil;
  
  checktrue(i=1);
end;



{$endif}
{$endregion 'UNITTESTING'}


initialization
  {$ifdef UNITTESTING}
  RegisterTest('Utility classes/Multicast', TTest_Multicast.Suite);
  {$endif}
end.
