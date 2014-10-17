unit u_qrXslxExport;

interface

uses
  QRExport, Classes, qrprntr, zexmlss, zeodfs, zexmlssutils, zeformula, zsspxml;

type
  TQRXLSXFilter = class(TQRXLSFilter)
  private
  protected
    function GetFilterName : string; override;
    function GetDescription : string; override;
    function GetExtension : string; override;
    function GetStreaming : boolean; override;
    procedure CreateStream(Filename : string); override;
    procedure CloseStream; override;
  public
    procedure StorePage; override;
  end;


  
type
  TQRExportFilter_XLSX = class(TComponent)
  private
     function GetEncoding : TTextEncoding;
     procedure SetEncoding( value : TTextEncoding);
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
  published
    property TextEncoding : TTextencoding read GetEncoding write SetEncoding;
  end;


procedure Register;

implementation

uses
  SysUtils, zexlsx, zeZippy, zeSave, zeSaveXLSX, zeZippyAB, Graphics;

{ TQRXLSXFilter }

procedure TQRXLSXFilter.CloseStream;
begin
  //inherited;
end;

procedure TQRXLSXFilter.CreateStream(Filename: string);
begin
  //inherited;
end;

function TQRXLSXFilter.GetDescription: string;
begin
  Result := 'Excel file format';
end;

function TQRXLSXFilter.GetExtension: string;
begin
  Result := 'XLSX';
end;

function TQRXLSXFilter.GetFilterName: string;
begin
  Result := 'Excel spreadsheet';
end;

function TQRXLSXFilter.GetStreaming: boolean;
begin
  Result := true;
end;

procedure TQRXLSXFilter.StorePage;
{-----------------------------------------------------------------------------
  Procedure: StorePage
  Author:    nbi
  Date:      29-Jul-2015
  Arguments: None
  Result:    None
-----------------------------------------------------------------------------}
var
  XMLSS: TZEXMLSS;
  sh: TZSheet;
  serstyles: TStringList;
  e: TTextEntry;
  i: Integer;
  x: Integer;
  y: Integer;
  bmp: TBitmap;

  function GetTextEntryKey(e: TTextEntry): string;
  begin
    Result := Format('font %s size %d style %d %d %d %d color %x al %d', [e.TextFont.Name, e.TextFont.size
      , Ord(fsBold in e.TextFont.Style)
      , Ord(fsItalic in e.TextFont.Style)
      , Ord(fsUnderline in e.TextFont.Style)
      , Ord(fsStrikeOut in e.TextFont.Style)
      , e.TextFont.color
      , Ord(e.FAlignment)
      ]);
  end;
  
  procedure SetupStyles;
  var
    i: Integer;
    e: TTextEntry;
    sKey: string;
    st: TZStyle;
  begin
    //sl := TStringList.Create;
    //try
      //TQRAbstractExportFilter(Self).TheEntries;
      for i := 0 to TheEntries.Count-1 do begin
        e := TTextEntry(TheEntries[i]);
        sKey := GetTextEntryKey(e);
        if(serstyles.IndexOf(sKey)<>-1) then
          continue;
        
        serstyles.AddObject(sKey, e);
      end;

      XMLSS.Styles.Count := serstyles.count;
      for i := 0 to serstyles.count-1 do begin
        e := TTextEntry(serstyles.Objects[i]);
        
        st := XMLSS.Styles[i];
        st.Font.assign(e.textfont);
        st.BGColor := e.BackColor;
        st.CellPattern := ZPSolid;

        case e.FAlignment of 
          taLeftJustify: st.Alignment.Horizontal := ZHLeft;
          taRightJustify: st.Alignment.Horizontal := ZHRight;
          taCenter: st.Alignment.Horizontal := ZHCenter;
        end;
        
        XMLSS.Styles[i].Alignment.Vertical := ZVCenter;
        XMLSS.Styles[i].Alignment.WrapText := False;
      end;
    //finally
      //sl.Free;
    //end;
  end;
  
var
  Canvas: TCanvas;
  
begin
  if(TheEntries.count=0) then //QR initially calls newpage -> endpage -> export.storepage
    EXIT;
  
  XMLSS := TZEXMLSS.Create(nil);
  serstyles := TStringList.Create;
  bmp := TBitmap.Create;
  Canvas := bmp.Canvas;
  try
  
    XMLSS.Sheets.Count := 1;
    sh := XMLSS.Sheets[0];
    sh.Title := '»ме на лист';
    sh.RowCount := 1;
    sh.ColCount := 1;

    SetupStyles;
  
    for i := 0 to TheEntries.count-1 do begin
      e := TTextEntry(TheEntries[i]);
      x := trunc(e.xpos);
      y := trunc(e.ypos);      
      
      if(x >= (sh.colcount-1)) then
        sh.colcount := x+1;
        
      if(y >= (sh.RowCount-1)) then
        sh.rowcount := y+1;
        
      sh.Cell[x, y].CellStyle := serstyles.indexof(GetTextEntryKey(e));
      sh.Cell[x, y].Data := e.FText;

      Canvas.Font.Assign(e.TextFont);
      if(sh.Columns[x].WidthPix < Canvas.TextWidth(e.FText)) then begin
        sh.Columns[x].WidthPix := Canvas.TextWidth(e.FText);
        sh.Columns[x].WidthMM := sh.Columns[x].WidthMM + 5;
      end;
    end;

    TZXMLSSave.From(XMLSS).Save(Filename);

  finally
    xmlss.Free;
    serstyles.Free;
    bmp.Free;
  end;
end;

{ TQRExportFilter_XLSX }

constructor TQRExportFilter_XLSX.Create(AOwner: TComponent);
begin
  inherited;
  QRExportFilterLibrary.AddFilter(TQRXLSXFilter);
end;

destructor TQRExportFilter_XLSX.Destroy;
begin
  QRExportFilterLibrary.RemoveFilter(TQRXLSXFilter);
  inherited;
end;

function TQRExportFilter_XLSX.GetEncoding: TTextEncoding;
begin
  result := UnicodeEncoding;
end;

procedure TQRExportFilter_XLSX.SetEncoding(value: TTextEncoding);
begin
  //raise Exception.Create('not implemented');
end;

procedure Register;
begin
  RegisterComponents('Datapark', [TQRExportFilter_XLSX]);
end;

end.
