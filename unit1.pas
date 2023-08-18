unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Menus, Process, IniFiles;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    ExitItem: TMenuItem;
    PauseItem: TMenuItem;
    StartItem: TMenuItem;
    StopItem: TMenuItem;
    Separator1: TMenuItem;
    PopupMenu1: TPopupMenu;
    Timer1: TTimer;
    Timer2: TTimer;
    TrayIcon1: TTrayIcon;
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure CheckHTTP;
    procedure WriteToLog(response: String);
    procedure ExitItemClick(Sender: TObject);
    procedure StartItemClick(Sender: TObject);
    procedure StopItemClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure TrayIcon1MouseUp(Sender: TObject; Button: TMouseButton);
  private

  public
    StartDir, ConfigFile, URL: String;
    icon1, icon2: TIcon;
    IsAllowFormClose, IsChangeColor: Boolean;
  end;

var
  Form1: TForm1;


implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  ini: TIniFile;
  StartFile: String;
begin
  StartDir := ExtractFilePath(ParamStr(0));
  StartFile := copy(ExtractFileName(ParamStr(0)), 0, length(ExtractFileName(ParamStr(0))) - 4);
  ConfigFile := StartDir + StartFile + '.ini';

  ini := TIniFile.Create(ConfigFile);
  Timer1.Interval := ini.ReadInteger('Main', 'Interval', 5) * 1000 * 60;
  ini.Free;
  IsAllowFormClose := False;
  icon1 := TIcon.Create;
  icon2 := TIcon.Create;
  icon1.LoadFromFile(StartDir + 'icons\0.ico');
  if not FileExists(StartDir + 'logs') then CreateDir(StartDir + 'logs');
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  Hide;
  StartItem.Enabled := False;
  Timer1.Enabled := True;
  Timer2.Enabled := False;
  CheckHTTP;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := IsAllowFormClose;
  Hide;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  CheckHTTP;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  IsChangeColor := not IsChangeColor;
  if IsChangeColor
     then TrayIcon1.Icon.Assign(icon1)
     else TrayIcon1.Icon.Assign(icon2);
end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
begin
  Show;
end;

procedure TForm1.TrayIcon1MouseUp(Sender: TObject; Button: TMouseButton);
begin
  if Button = mbRight then PopupMenu1.PopUp;
end;

procedure TForm1.Button1Click(Sender: TObject);

begin
  CheckHTTP;
end;

procedure TForm1.CheckHTTP;
var
  OutputLines: TStringList;
  Command, FileIcon: String;
  Process: TProcess;
begin
  OutputLines := TStringList.Create;
  Process := TProcess.Create(nil);

  try
    try
      Command := 'curl -K curl.txt';

      Process.Executable := 'cmd';
      Process.Parameters.Add('/c');
      Process.Parameters.Add(Command);

      Process.Options := [poUsePipes, poNoConsole];
      Process.ShowWindow := swoHIDE;

      Process.Execute;

      OutputLines.LoadFromStream(Process.Output);

      TrayIcon1.Hint := TimeToStr(Now) + ' - ' + Trim(OutputLines.Text);
      Memo1.Lines.Add(TrayIcon1.Hint);
      WriteToLog(Trim(OutputLines.Text));
      FileIcon := StartDir + 'icons\' + Trim(OutputLines.Text) + '.ico';
      if FileExists(FileIcon)
         then begin
           Timer2.Enabled := False;
           TrayIcon1.Icon.LoadFromFile(FileIcon);
         end else begin
           Timer2.Enabled := True;
           TrayIcon1.Icon.LoadFromFile(StartDir + 'icons\0.ico');
         end;
    except
      on E: Exception do
        Memo1.Lines.Add('Error: ' + E.Message);
    end;
  finally
    OutputLines.Free;
    Process.Free;
  end;
end;

procedure TForm1.WriteToLog(response: String);
var
  LogFileName: String;
  LogFile: TextFile;
begin
  LogFileName := 'logs\' + FormatDateTime('yyyy-mm-dd', Now) + '.log';
  AssignFile(LogFile, LogFileName);
  try
    if not FileExists(LogFileName) then
      Rewrite(LogFile)
    else
      Append(LogFile);

    WriteLn(LogFile, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + response);
  finally
    CloseFile(LogFile);
  end;
end;

procedure TForm1.ExitItemClick(Sender: TObject);
begin
  Timer1.Enabled := False;
  Timer2.Enabled := False;
  IsAllowFormClose := True;
  Form1.Close;
end;

procedure TForm1.StartItemClick(Sender: TObject);
begin
  StartItem.Enabled := False;
  StopItem.Enabled := True;
  Timer1.Enabled := True;
end;

procedure TForm1.StopItemClick(Sender: TObject);
begin
  StartItem.Enabled := True;
  StopItem.Enabled := False;
  Timer1.Enabled := False;
end;

end.

