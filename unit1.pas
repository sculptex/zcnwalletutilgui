unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Process,
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

const
  BUF_SIZE = 2048;

  {$IFDEF WINDOWS}
    {$IFDEF WIN64}
      OS = 'W64';
    {$ELSE}
      OS = 'W32';
    {$ENDIF}
    DEFPATH = '%HOMEPATH%\.zcn';
    DEFZBOX = 'zbox.exe';
    DEFZWALLET = 'zwallet.exe';
    DEFZCNWALUTIL = 'zzcwalletutil.exe';
    DEFGETHHDWALLET = 'geth-hdwallet.exe';
    PS = '\';
  {$ELSE}
    {$IFDEF DARWIN}
      OS = 'OSX';
      DEFPATH = '$HOME/.zcn/';
      DEFZBOX = 'zbox';
      DEFZWALLET = 'zwallet';
      DEFZCNWALUTIL = 'zcwalletutil';
      DEFGETHHDWALLET = 'geth-hdwallet';
      PS = '/';
    {$ELSE}
      OS = 'L64';
      DEFPATH = '~/.zcn';
      DEFZBOX = 'zbox';
      DEFZWALLET = 'zwallet';
      DEFZCNWALUTIL = 'zcnwalletutil';
      DEFGETHHDWALLET = 'geth-hdwallet';
      PS = '/';
    {$ENDIF}
  {$ENDIF}

type

  { TfrmZcnWalletUtil }

  TfrmZcnWalletUtil = class(TForm)
    btnGetWalletData: TButton;
    btnNewWalletData: TButton;
    cbEthgethhdwallet: TCheckBox;
    cbZwalletcli: TCheckBox;
    cbZcnwalletutil: TCheckBox;
    edETHprivkey: TEdit;
    edSeedPhrase: TEdit;
    edZCNwaladdr: TEdit;
    edETHwaladdr: TEdit;
    edZCNcmd: TEdit;
    edETHcmd: TEdit;
    edZCNprivkey: TEdit;
    edZCNpubkey: TEdit;
    gbZCNwalletcli: TGroupBox;
    gbETHcli: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Memo2: TMemo;
    Panel1: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    procedure btnGetWalletDataClick(Sender: TObject);
    procedure btnNewWalletDataClick(Sender: TObject);
    procedure cbZcnwalletutilChange(Sender: TObject);
    procedure cbZcnwalletutilClick(Sender: TObject);
    procedure cbZwalletcliClick(Sender: TObject);
    procedure edSeedPhraseChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  frmZcnWalletUtil: TfrmZcnWalletUtil;

implementation

{$R *.lfm}

{ TfrmZcnWalletUtil }

function docmd(cmd:string; params:array of string; var fullcmd: string):String;
var
  bin : string;
  AProcess     : TProcess;
  BytesRead    : longint;
  Buffer       : array[1..BUF_SIZE] of byte;
  c : char;
  p : integer;
  OutputString : String;
  ErrorString : String;
  param : String;
begin

  bin := cmd;

  AProcess := TProcess.Create(nil);
  AProcess.Executable := bin;

  fullcmd := cmd;
  p := Low(params);
  while(p <= High(params)) do
  begin
    AProcess.Parameters.Add(params[p]);
    param := params[p];
    if( (pos(' ',param)>0) OR (pos('''',param)>0) OR (pos('/',param)>0) ) then
      fullcmd := concat(fullcmd,' "',param,'"')
    else
      fullcmd := concat(fullcmd,' ',param);
    inc(p);
  end;

  if( OS = 'W64' ) then
  begin
    AProcess.Options := [poWaitOnExit, poUsePipes,poStderrToOutPut];
  end
  else
  begin
    AProcess.Options := [poUsePipes];
  end;

  AProcess.Execute;

  OutputString := '';
  repeat
    BytesRead := AProcess.Output.Read( Buffer, 1 );
    if(BytesRead > 0) then
    begin
      if(chr(Buffer[1]) = chr(13)) OR (chr(Buffer[1]) = chr(10)) then
      begin
        c := ' '
      end
      else
      begin
        c := chr(Buffer[1]);
      end;
      OutputString := concat(OutputString, c);
    end;
  until (BytesRead = 0);
  ErrorString := '';
  repeat
    BytesRead := AProcess.StdErr.Read(Buffer, 1);
    if(BytesRead > 0) then
    begin
      if(chr(Buffer[1]) = chr(13)) OR (chr(Buffer[1]) = chr(10)) then
      begin
        c := ' '
      end
      else
      begin
        c := chr(Buffer[1]);
      end;
      ErrorString := concat(ErrorString, c);
    end;
  until (BytesRead = 0);

  AProcess.Free;
  Result := OutputString;
end;

function readstream(fnam: string): string;
var
  strm: TFileStream;
  n: longint;
  txt: string;
begin
  txt := '';
  strm := TFileStream.Create(fnam, fmOpenRead or fmShareDenyWrite);
  try
    n := strm.Size;
    SetLength(txt, n);
    strm.Read(txt[1], n);
  finally
    strm.Free;
  end;
  result := txt;
end;

function getfilecontents(filename:string):string;
var
  contents : string;
begin
  contents := readstream(filename);
  Result := contents;
end;

procedure TfrmZcnWalletUtil.btnGetWalletDataClick(Sender: TObject);
var
  cmd : string;
  waljson : string;
  zcnaddr : string;
  zcnpubkey : string;
  zcnprivkey : string;
  ethres : string;
  ethaddr : string;
  ethprivkey : string;
  walfile : string;
begin
  walfile := 'walutil.json';
  if(fileexists(walfile)) then
    DeleteFile(walfile);
  if(cbZwalletcli.Checked) then
  begin
    docmd( DEFZWALLET, [ 'recoverwallet', '--wallet', walfile, '--mnemonic', edSeedPhrase.Text ], cmd );
    waljson := getfilecontents(walfile);
  end
  else
  begin
    waljson := docmd( DEFZCNWALUTIL, [ '--mnemonic', edSeedPhrase.Text, '--json' ], cmd );
  end;
  edZCNcmd.Text := cmd;

  zcnaddr := waljson;
  zcnaddr := copy( zcnaddr, pos('"client_id":', zcnaddr));
  zcnaddr := StringReplace( zcnaddr, '"client_id":"', '', [ rfReplaceAll ] );
  zcnaddr := copy( zcnaddr, 1, 64 );

  zcnprivkey := waljson;
  zcnprivkey := copy( zcnprivkey, pos('"private_key"', zcnprivkey));
  zcnprivkey := StringReplace( zcnprivkey, '"private_key":"', '', [ rfReplaceAll ] );
  zcnprivkey := copy( zcnprivkey, 1, 64 );

  zcnpubkey := waljson;
  zcnpubkey := copy( zcnpubkey, pos('"public_key"', zcnpubkey));
  zcnpubkey := StringReplace( zcnpubkey, '"public_key":"', '', [ rfReplaceAll ] );
  zcnpubkey := copy( zcnpubkey, 1, 128 );

  edZCNwaladdr.Text := zcnaddr;
  edZCNprivkey.Text := zcnprivkey;
  edZCNpubkey.Text := zcnpubkey;
  if(fileexists(walfile)) then
    DeleteFile(walfile);

  if(cbEthgethhdwallet.Checked) then
  begin
    ethres := docmd( DEFGETHHDWALLET, [ '--mnemonic', edSeedPhrase.Text, '-path', 'm/44''/60''/0''/0/0' ], cmd );
    edETHcmd.Text := cmd;

    ethaddr := ethres;
    ethaddr := StringReplace( ethaddr, 'public address: ', '', [ rfReplaceAll ] );
    ethaddr := copy( ethaddr, 1, 42 );

    ethprivkey := ethres;
    ethprivkey := copy( ethprivkey, pos('private key: ', ethprivkey));
    ethprivkey := StringReplace( ethprivkey, 'private key: ', '', [ rfReplaceAll ] );
    ethprivkey := copy( ethprivkey, 1, 64 );

    edETHwaladdr.Text := ethaddr;
    edETHprivkey.Text := ethprivkey;
  end
  else
  begin
    edETHcmd.Text := '';
    edETHwaladdr.Text := '';
    edETHprivkey.Text := '';
  end;
end;

procedure TfrmZcnWalletUtil.btnNewWalletDataClick(Sender: TObject);
var
  cmd : string;
  waljson : string;
  zcnaddr : string;
  zcnpubkey : string;
  zcnprivkey : string;
  mnemonic : string;
  ethres : string;
  ethaddr : string;
  ethprivkey : string;
  walfile : string;
  p : integer;
begin
  walfile := 'walutil.json';
  if(fileexists(walfile)) then
    DeleteFile(walfile);
  if(cbZwalletcli.Checked) then
  begin
    docmd( DEFZWALLET, [ 'getbalance', '--wallet', walfile ], cmd );
    waljson := getfilecontents(walfile);
  end
  else
  begin
    waljson := docmd( DEFZCNWALUTIL, [ '--json' ], cmd );
  end;
  edZCNcmd.Text := cmd;

  zcnaddr := waljson;
  zcnaddr := copy( zcnaddr, pos('"client_id":', zcnaddr));
  zcnaddr := StringReplace( zcnaddr, '"client_id":"', '', [ rfReplaceAll ] );
  zcnaddr := copy( zcnaddr, 1, 64 );

  zcnprivkey := waljson;
  zcnprivkey := copy( zcnprivkey, pos('"private_key"', zcnprivkey));
  zcnprivkey := StringReplace( zcnprivkey, '"private_key":"', '', [ rfReplaceAll ] );
  zcnprivkey := copy( zcnprivkey, 1, 64 );

  zcnpubkey := waljson;
  zcnpubkey := copy( zcnpubkey, pos('"public_key"', zcnpubkey));
  zcnpubkey := StringReplace( zcnpubkey, '"public_key":"', '', [ rfReplaceAll ] );
  zcnpubkey := copy( zcnpubkey, 1, 128 );

  mnemonic := waljson;
  mnemonic := StringReplace( mnemonic, '"mnemonics":"', '"mnemonic":"', [ rfReplaceAll ] );
  p := pos('"mnemonic":"', mnemonic);
  mnemonic := copy( mnemonic, p );
  mnemonic := StringReplace( mnemonic, '"mnemonic":"', '', [ rfReplaceAll ] );
  mnemonic := copy( mnemonic, 1, pos('"', mnemonic)-1 );

  edSeedPhrase.Text := mnemonic;

  edZCNwaladdr.Text := zcnaddr;
  edZCNprivkey.Text := zcnprivkey;
  edZCNpubkey.Text := zcnpubkey;
  if(fileexists(walfile)) then
    DeleteFile(walfile);

  if(cbEthgethhdwallet.Checked) then
  begin
    ethres := docmd( DEFGETHHDWALLET, [ '--mnemonic', edSeedPhrase.Text, '-path', 'm/44''/60''/0''/0/0' ], cmd );

    ethaddr := ethres;
    ethaddr := StringReplace( ethaddr, 'public address: ', '', [ rfReplaceAll ] );
    ethaddr := copy( ethaddr, 1, 42 );

    ethprivkey := ethres;
    ethprivkey := copy( ethprivkey, pos('private key: ', ethprivkey));
    ethprivkey := StringReplace( ethprivkey, 'private key: ', '', [ rfReplaceAll ] );
    ethprivkey := copy( ethprivkey, 1, 64 );

    edETHcmd.Text := cmd;
    edETHwaladdr.Text := ethaddr;
    edETHprivkey.Text := ethprivkey;
  end
  else
  begin
    edETHcmd.Text := '';
    edETHwaladdr.Text := '';
    edETHprivkey.Text := '';
  end;
end;

procedure TfrmZcnWalletUtil.cbZcnwalletutilChange(Sender: TObject);
begin

end;

procedure TfrmZcnWalletUtil.cbZcnwalletutilClick(Sender: TObject);
begin
  cbZwalletcli.Checked := NOT(cbZcnwalletutil.Checked) AND cbZwalletcli.Enabled;
end;

procedure TfrmZcnWalletUtil.cbZwalletcliClick(Sender: TObject);
begin
  cbZcnwalletutil.Checked := NOT(cbZwalletcli.Checked) AND cbZcnwalletutil.Enabled;
end;

function wcount(s: string) : integer;
var
  n, i: Integer;
begin
  s := ' ' + s + ' ';
  n := -1;
  i := 1;
  while( i <= length(s)) do
  begin
    while(s[i] = ' ') AND (i <= length(s)) do
      inc(i);
    while(s[i] <> ' ') AND (i <= length(s)) do
      inc(i);
    inc( n );
  end;
  Result := n;
end;

procedure TfrmZcnWalletUtil.edSeedPhraseChange(Sender: TObject);
var
  c : integer;
begin
  c := wcount(edSeedPhrase.Text);
  btnGetWalletData.Enabled := (c=24) OR (c=12);
end;

procedure TfrmZcnWalletUtil.FormCreate(Sender: TObject);
begin
  chdir(ExpandFileName(DEFPATH));

  cbZwalletcli.Enabled := FileExists(DEFZWALLET);
  cbZcnwalletutil.Enabled := FileExists(DEFZCNWALUTIL);
  if(NOT(FileExists(DEFZCNWALUTIL))) then
    cbZcnwalletutil.Checked := FALSE;
  cbEthgethhdwallet.Enabled := FileExists(DEFGETHHDWALLET);
  cbEthgethhdwallet.Checked := FileExists(DEFGETHHDWALLET);
end;

end.

