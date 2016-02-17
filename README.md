# DelphiUtils

u_multicast.pas 
- multicast events for delphi. in contract to the regular event this is a list of events which means that multiple subscribers would be called when an event is to be fired. due to the use of interfaces the unsubscribing is automatic but a subscription token needs to be kept while subscribed. Dependency: IEntity which is not yet shared here. IEntity is list/map structure storing pairs name->value.

u_qrXslxExport.pas 
- QuickReports Microsoft Excel (XLSX) export filter. Dependency: [zexmlss](http://avemey.com/zexmlss/index.php?lang=en). Zexmlss uses Abbrevia.

u_intfCustomMessageBox.pas

- allows creating Windows MessageBoxes like this:

```Pascal
procedure TTestCustomMessageDialog.test_CustomMessageDlg;
var
  dlg: ICustomMessageBox;
  answer: string;
const
  button1 = 'button1';
  button2 = 'Show an error in next dlg';
begin
  dlg := CustomMessageDlg.SetText(
           'Testing mtWarning '+sLineBreak+
           'line2.1')
         .SetType(mtWarning)
         .SetButtons([button1,button2])
         .SetDefBtn(button1);
  
  answer := dlg.Execute;
  
  dlg.SetText(
           'Testing mtError '+sLineBreak+
           'line2.2'+sLineBreak+
           'You selected: '+answer);
           
  if(answer=button1) then
    dlg.SetType(mtError);
    
  dlg.Execute;
  
  dlg.SetType(mtInformation);
  dlg.SetText(
           'Testing mtInformation '+sLineBreak+
           'line2.3');
  dlg.Execute;
end;
```

Advantages: saves a lot of intermediate variables and makes dialog showing a LOT more flexible.
