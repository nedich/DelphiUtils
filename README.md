# DelphiUtils

u_multicast.pas 
- multicast events for delphi. in contract to the regular event this is a list of events which means that multiple subscribers would be called when an event is to be fired. due to the use of interfaces the unsubscribing is automatic but a subscription token needs to be kept while subscribed. Dependency: IEntity which is not yet shared here. IEntity is list/map structure storing pairs name->value.

u_qrXslxExport.pas 
- QuickReports Microsoft Excel (XLSX) export filter. Dependency: [zexmlss](http://avemey.com/zexmlss/index.php?lang=en). Zexmlss uses Abbrevia.

