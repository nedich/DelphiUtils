# DelphiUtils

u_multicast.pas 
- multicast events for delphi. in contract to the regular event this is a list of events which means that multiple subscribers would be called when an event is to be fired. due to the use of interfaces the unsubscribing is automatic but a subscription token needs to be kept while subscribed. Dependency: IEntity which is not yet shared here. IEntity is list/map structure storing pairs name->value.

u_qrXslxExport.pas 
- QuickReports Microsoft Excel (XLSX) export filter. Dependency: [zexmlss](http://avemey.com/zexmlss/index.php?lang=en). Zexmlss uses Abbrevia.

u_intfCustomMessageBox.pas

allows creating Windows MessageBoxes like this:


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
end;
