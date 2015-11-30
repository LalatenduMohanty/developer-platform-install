; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define AppName "Red Hat Developer Platform"
#define AppVersion "1.0.Alpha1"
#define AppPublisher "Red Hat"
#define AppURL "http://www.redhat.com/"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{C72362A0-26F3-49D6-8ED1-8214644255DD}
AppName={#AppName}
AppVersion={#AppVersion}
;AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
CreateAppDir=yes
DefaultDirName={pf}\{#AppName}
DefaultGroupName={#AppName}
OutputBaseFilename=developer_platform_setup
Compression=lzma
SolidCompression=yes
;WizardSmallImageFile=blank.bmp
BackColor=clWhite
BackSolid=yes
DisableWelcomePage=yes
DisableDirPage=yes
DisableReadyPage=no
DisableFinishedPage=yes
ExtraDiskSpaceRequired=1048576

[Files]
Source: "EfTidy.dll"; Flags: dontcopy;
Source: "InstallConfigRecord.xml"; Flags: dontcopy;

#include "idp_source\idp.iss"

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Registry]
Root: HKLM; Subkey: "Software\Red Hat";            Flags: uninsdeletekeyifempty
Root: HKLM; Subkey: "Software\Red Hat\{#AppName}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Red Hat\{#AppName}"; ValueType: string; ValueName: "InstallDir"; ValueData: "{app}"

[Code]
#IFDEF UNICODE
  #DEFINE AW "W"
#ELSE
  #DEFINE AW "A"
#ENDIF

type
  ComponentGroup = record
    Container: TPanel;
    Content: TPanel;
  end;
  BcLabelArray = array[1..4] of TLabel;

  Component = record
    Name: String;
    DownloadUrl: String;
    Install: Boolean;
  end;

  SAMLFormParams = record
    Action: String;
    SAMLRequest: String;
    SAMLResponse: String;
    RelayState: String;
  end;

  TShellExecuteInfo = record
    cbSize: DWORD;
    fMask: Cardinal;
    Wnd: HWND;
    lpVerb: string;
    lpFile: string;
    lpParameters: string;
    lpDirectory: string;
    nShow: Integer;
    hInstApp: THandle;    
    lpIDList: DWORD;
    lpClass: string;
    hkeyClass: THandle;
    dwHotKey: DWORD;
    hMonitor: THandle;
    hProcess: THandle;
  end;

const
  JBDS_URL = 'https://access.redhat.com/jbossnetwork/restricted/softwareDownload.html?softwareId=40371';
  JBDS_FILENAME = 'jboss-devstudio-installer-standalone.jar';
  WAIT_TIMEOUT = $00000102;
  SEE_MASK_NOCLOSEPROCESS = $00000040;  

var 
  // Page IDs
  AuthPageID, ComponentPageID, DownloadPageID, GetStartedPageID, InstallPageID : Integer; 

  UsernameEdit: TNewEdit;
  PasswordEdit: TPasswordEdit;

  AuthLabel: TNewStaticText;

  // "Standard" blue color used throughout the installer
  StdColor: TColor;  

  // Breadcrumb image
  Breadcrumbs: TBitmapImage; 

  // Breadcrumb labels, we store references to these in an array for convenience
  BreadcrumbLabel: BcLabelArray; 

  // Flag indicating whether the user has authenticated successfully
  IsAuthenticated: Boolean;

  // cookie values for downloading JBDS
  RHSSOCookieValue, JSessionIdCookieValue: String;

// Declaration of external windows function calls, for initiating and managing separate processes
function ShellExecuteEx(var lpExecInfo: TShellExecuteInfo): BOOL; 
  external 'ShellExecuteEx{#AW}@shell32.dll stdcall';

function WaitForSingleObject(hHandle: THandle; dwMilliseconds: DWORD): DWORD; 
  external 'WaitForSingleObject@kernel32.dll stdcall';

function TerminateProcess(hProcess: THandle; uExitCode: UINT): BOOL;
  external 'TerminateProcess@kernel32.dll stdcall';

// Converts a color String in the format '$rrggbb' to a TColor value
function StringToColor(Color: String): TColor;
var
    RR, GG, BB: String;
    Dec: Integer;
begin
    { Change string Color from $RRGGBB to $BBGGRR and then convert to TColor }
    if((Length(Color) <> 7) or (Color[1] <> '$')) then
        Result := $000000
    else
    begin
        RR := Color[2] + Color[3];
        GG := Color[4] + Color[5];
        BB := Color[6] + Color[7];
        Dec := StrToInt('$' + BB + GG + RR);
        Result := TColor(Dec);
    end;
end;

// Converts a value to hex
function DigitToHex(Digit: Integer): Char;
begin
  if (Digit >= 0) and (Digit <= 9) then
    Result := Chr(Digit + Ord('0'))
  else if (Digit >= 10) and (Digit <= 15) then
    Result := Chr(Digit - 10 + Ord('A'))
  else
    Result := '0';
end;

// URL-encodes the provided string
function URLEncode(const S: string): string;
var
  i, idx, len: Integer;
begin
  len := 0;
  for i := 1 to Length(S) do
    if ((S[i] >= '0') and (S[i] <= '9')) or
    ((S[i] >= 'A') and (S[i] <= 'Z')) or
    ((S[i] >= 'a') and (S[i] <= 'z')) or (S[i] = ' ') or
    (S[i] = '_') or (S[i] = '*') or (S[i] = '-') or (S[i] = '.') then
      len := len + 1
    else
      len := len + 3;

  SetLength(Result, len);
  idx := 1;

  for i := 1 to Length(S) do
    if S[i] = ' ' then
      begin
        Result[idx] := '+';
        idx := idx + 1;
      end
    else if ((S[i] >= '0') and (S[i] <= '9')) or
      ((S[i] >= 'A') and (S[i] <= 'Z')) or
      ((S[i] >= 'a') and (S[i] <= 'z')) or
      (S[i] = '_') or (S[i] = '*') or (S[i] = '-') or (S[i] = '.') then
      begin
        Result[idx] := S[i];
        idx := idx + 1;
      end
    else
    begin
      Result[idx] := '%';
      Result[idx + 1] := DigitToHex(Ord(S[i]) div 16);
      Result[idx + 2] := DigitToHex(Ord(S[i]) mod 16);
      idx := idx + 3;
    end;
end;

function Split(const Value: String; const Delimiter: String): TStringList;
var
   dx: integer;
   ns: String;
   txt: String;
   delta: integer;
begin
   delta := Length(Delimiter);
   txt := value + Delimiter;
   Result := TStringList.Create();

   while Length(txt) > 0 do
   begin
     dx := Pos(delimiter, txt);
     ns := Copy(txt, 0, dx-1);
     Result.Add(ns);
     txt := Copy(txt, dx+delta, MaxInt);
   end;
end;

// Tests whether a String value starts with another String value, returns true if it does
function StartsWith(const Text: String; const Value: String): boolean;
var
  I: Integer;
begin
  if Length(Text) < Length(Value) then
  begin
    Result := False;
  end else begin
    for I := 1 to Length(Value) do
    begin
      if Value[I] <> Text[I] then
      begin
        Result := False;
        Exit;
      end;
    end;
    Result := True;
  end;
end;

// Replaces a String value in a file
function FileReplaceString(const FileName, SearchString, ReplaceString: string): boolean;
var
  MyFile : TStrings;
  MyText : string;
begin
  MyFile := TStringList.Create;

  try
    result := true;

    try
      MyFile.LoadFromFile(FileName);
      MyText := MyFile.Text;

      if StringChangeEx(MyText, SearchString, ReplaceString, True) > 0 then //Only save if text has been changed.
      begin;
        MyFile.Text := MyText;
        MyFile.SaveToFile(FileName);
      end;
    except
      result := false;
    end;
  finally
    MyFile.Free;
  end;
end;

// Extracts a particular cookie value from the Set-Cookie response header
function GetCookieValue(const CookieText: String; const CookieName: String): String;  
var
  Cookies: TStringList;
  I: integer;
begin
  Cookies := Split(CookieText, ';');

  for I := 0 to Cookies.Count - 1 do
  begin
    if StartsWith(Cookies.Strings[I], CookieName + '=') then
    begin
      Result := Split(Cookies.Strings[I], '=')[1];
      Exit;
    end;
  end;
end;

function ExtractSAMLFormValues(ResponseText: String): SAMLFormParams;
var
  I, J, K: Integer;
  XMLDoc, NodeList, FormNode, InputNode: Variant;
begin
  XMLDoc := CreateOleObject('MSXML2.DOMDocument');
  XMLDoc.async := False;
  XMLDoc.resolveExternals := False;
  XMLDoc.validateOnParse := False;
  XMLDoc.setProperty('ProhibitDTD', False);
  XMLDoc.loadXML(ResponseText);

  if XMLDoc.parseError.errorCode <> 0 then
  begin
    MsgBox('Error on line ' + IntToStr(XMLDoc.parseError.line) + ', position ' + 
      IntToStr(XMLDoc.parseError.linepos) + ': ' + XMLDoc.parseError.reason, mbInformation, MB_OK);
  end else begin
    NodeList := XMLDoc.getElementsByTagName('form');

    for I := 0 to NodeList.length - 1 do 
    begin
      FormNode := NodeList.item(i);

      Result.Action := FormNode.attributes.getNamedItem('action').nodeValue;

      for J := 0 to FormNode.childNodes.length - 1 do
      begin
        if FormNode.childNodes.item(J).nodeName = 'input' then
        begin
          InputNode := FormNode.childNodes.item[J];

          if InputNode.attributes.getNamedItem('name').nodeValue = 'SAMLRequest' then
            Result.SAMLRequest := InputNode.attributes.getNamedItem('value').nodeValue;
          if InputNode.attributes.getNamedItem('name').nodeValue = 'SAMLResponse' then
            Result.SAMLResponse := InputNode.attributes.getNamedItem('value').nodeValue;
          if InputNode.attributes.getNamedItem('name').nodeValue = 'RelayState' then
            Result.RelayState := InputNode.attributes.getNamedItem('value').nodeValue;
        end;       
      end;
    end;
  end;
end;

procedure LoginButtonOnClick(Sender: TObject);
var
  Url, Resource, ResponseText, RequestText: String;                                                       
  Page: TWizardPage;
  WinHttpReq, EfTidy: Variant;
  SAMLValues: SAMLFormParams;
begin
  Page := PageFromID(AuthPageID);

  AuthLabel.Caption := 'Authenticating, please wait...';
  AuthLabel.Font.Color := clBlack;
  AuthLabel.Visible := True;
  AuthLabel.Refresh;

  Url := 'https://idp.redhat.com/idp/authUser?j_username=' + UsernameEdit.Text + '&j_password=' + PasswordEdit.Text +
    '&redirect=' + JBDS_URL;

  // Perform a SAML authentication for redhat.com
  WinHttpReq := CreateOleObject('WinHttp.WinHttpRequest.5.1');
  WinHttpReq.Open('GET', Url, false);
  WinHttpReq.SetClientCertificate('LOCAL_MACHINE\Personal\My Certificate');
  WinHttpReq.SetRequestHeader('Content-Type', 'application/x-www-form-urlencoded');

  // Temporary - set proxy so Fiddler can inspect the traffic
  //WinHttpReq.SetProxy( 2, '127.0.0.1:8888');

  WinHttpReq.Send();

  // Extract the JSESSIONID cookie
  JSessionIdCookieValue := 'JSESSIONID=' + GetCookieValue(WinHttpReq.getResponseHeader('Set-Cookie'), 'JSESSIONID');

  if WinHttpReq.Status <> 200 then
  begin
     AuthLabel.Caption := 'Authentication Failed.';
     AuthLabel.Font.Color := clRed;
     Exit;    
  end else begin
    // Set the authenticated flag to true 
    IsAuthenticated := True;

    AuthLabel.Caption := 'Authentication Successful.';
    AuthLabel.Font.Color := clGreen;

    // Register the EfTidy dll so that we can call its functions
    ExtractTemporaryFile('EfTidy.dll');
    RegisterServer(True, ExpandConstant('{tmp}\EfTidy.dll'), False);

    Try 
      // We are going to tidy up the (non well-formed) response with EfTidy -
      // the first step is to create the EfTidy object

      EfTidy := CreateOleObject('EfTidy.tidyCom');
      EfTidy.Option.Clean := True;
      EfTidy.Option.OutputType := 1; // XhtmlOut
      EfTidy.Option.DoctypeMode := 3; // DoctypeLoose

      // Tidy up the response to make it valid XML so we can parse it
      ResponseText := EfTidy.TidyMemToMem(WinHttpReq.ResponseText);

      Log('Got response: ' + ResponseText);

      // Parse the now-valid XML response and extract the values we're interested in
      SAMLValues := ExtractSAMLFormValues(ResponseText);

      RequestText := 'SAMLRequest=' + URLEncode(SAMLValues.SAMLRequest) + 
                     '&RelayState=' + URLEncode(SAMLValues.RelayState);

      // POST the SAMLRequest and RelayState to the URL specified in the returned action attribute,
      // which in this case should be the IdP
      WinHttpReq.Open('POST', SAMLValues.Action, false);
      WinHttpReq.SetRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      WinHttpReq.SetRequestHeader('Content-Length', IntToStr(Length(RequestText)));
      WinHttpReq.Send(RequestText);

      Log('Sending request: ' + RequestText);

      if WinHttpReq.Status <> 200 then
      begin
        AuthLabel.Caption := 'Authentication Failed.';
        AuthLabel.Font.Color := clRed;
        Exit;    
      end else begin
        // Tidy up the response to make it valid XML so we can parse it
        ResponseText := EfTidy.TidyMemToMem(WinHttpReq.ResponseText);

        Log('Got response: ' + ResponseText);

        // Extract the Action, SAMLResponse and RelayState parameter values from the response
        SAMLValues := ExtractSAMLFormValues(ResponseText);

        Log('Posting SAMLResponse to ' + SAMLValues.Action + ', Request length: ' + 
               IntToStr(Length(SAMLValues.SAMLResponse)) + 
               ', SAMLResponse: ' + Copy(SAMLValues.SAMLResponse, 1, 1000) +             
               ', RelayState: ' + SAMLValues.RelayState);

        RequestText := 'SAMLResponse=' + URLEncode(SAMLValues.SAMLResponse) + 
                       '&RelayState=' + URLEncode(SAMLValues.RelayState);

        WinHttpReq.Open('POST', SAMLValues.Action, false);

        // Do not follow redirects here
        WinHttpReq.Option(6) := False;

        WinHttpReq.SetRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        WinHttpReq.SetRequestHeader('Content-Length', IntToStr(Length(RequestText)));
        WinHttpReq.Send(RequestText);

        if WinHttpReq.Status <> 302 then
        begin
          AuthLabel.Caption := 'Authentication Failed.';
          AuthLabel.Font.Color := clRed;
          Exit;
        end else begin        
          RHSSOCookieValue := 'rh_sso=' + GetCookieValue(WinHttpReq.getResponseHeader('Set-Cookie'), 'rh_sso');    
          Log('Got rh_sso cookie: ' + RHSSOCookieValue);

          //idpAddFile(JBDS_URL, ExpandConstant('{tmp}\jboss-devstudio-9.0.0.GA-installer-standalone.jar'));
          //idpSetCookie(JBDS_URL, 'http://access.redhat.com/', JSessionIdCookieValue);
          //idpSetCookie(JBDS_URL, 'http://access.redhat.com/', RHSSOCookieValue);
          
        end;
      end;
    Finally
      UnregisterServer(True, ExpandConstant('{tmp}\EfTidy.dll'), False);
      CoFreeUnusedLibraries();
    End;

    // Simulate a click of the Next button
    WizardForm.NextButton.OnClick(nil);
  end; 
end;

procedure ForgotLabelOnClick(Sender: TObject);
var
  ErrorCode: Integer;
begin
  ShellExecAsOriginalUser('open', 'http://www.redhat.com/', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
end;

// Create the welcome page - this page allows the user to log in to their Red Hat account
function createWelcomePage: TWizardPage;
var
  Page: TWizardPage;
  LoginLabel: TNewStaticText;
  ForgotLabel: TNewStaticText;
  Button: TNewButton;
begin
  Page := CreateCustomPage(wpWelcome, '', '');

  // The page has a unique id, we store it in the AuthPageID variable here so that we can refer to it elsewhere
  AuthPageID := Page.ID;

  // Create the label for the user's login name
  LoginLabel := TNewStaticText.Create(Page);
  LoginLabel.Caption := 'Log in to your Red Hat account';
  LoginLabel.Parent := Page.Surface;
  LoginLabel.Color := clWhite;
  LoginLabel.Font.Style := LoginLabel.Font.Style + [fsBold];
  LoginLabel.Font.Size := 10;
  
  // Create an edit control for the user's login name
  UsernameEdit := TNewEdit.Create(Page);
  UsernameEdit.Top := LoginLabel.Top + LoginLabel.Height + ScaleY(8);
  UsernameEdit.Width := Page.SurfaceWidth div 2 - ScaleX(8);
  UsernameEdit.Text := 'Red Hat Login';
  UsernameEdit.Parent := Page.Surface;

  // Create a password control for the user's password
  PasswordEdit := TPasswordEdit.Create(Page);
  PasswordEdit.Top := UsernameEdit.Top +UsernameEdit.Height + ScaleY(8);
  PasswordEdit.Width := UsernameEdit.Width;
  PasswordEdit.Text := 'Password';
  PasswordEdit.Parent := Page.Surface;

  // Create the 'LOG IN' button
  Button := TNewButton.Create(Page);
  Button.Width := ScaleX(75);
  Button.Height := ScaleY(23);
  Button.Caption := 'LOG IN';
  Button.Top := PasswordEdit.Top + PasswordEdit.Height + ScaleY(8);
  Button.OnClick := @LoginButtonOnClick;
  Button.Parent := Page.Surface;

  // Create the 'forgot password' link
  ForgotLabel := TNewStaticText.Create(Page);
  ForgotLabel.Caption := 'Forgot your login or password?';
  ForgotLabel.Cursor := crHand;
  ForgotLabel.OnClick := @ForgotLabelOnClick;
  ForgotLabel.Parent := Page.Surface;
  ForgotLabel.Color := clWhite;
  { Alter Font *after* setting Parent so the correct defaults are inherited first }
  //ForgotLabel.Font.Style := URLLabel.Font.Style + [fsUnderline];
  ForgotLabel.Font.Style := ForgotLabel.Font.Style + [fsBold];
  ForgotLabel.Font.Color := StdColor;
  ForgotLabel.Top := Button.Top + ((Button.Height - ForgotLabel.Height) / 2) + ScaleY(0);
  ForgotLabel.Left := Button.Left + Button.Width + ScaleX(20);

  // Create the authentication label.  We set its visibility to false at first, then display it later when needed
  AuthLabel := TNewStaticText.Create(Page);
  AuthLabel.Parent := Page.Surface;
  AuthLabel.Color := clWhite;
  AuthLabel.Visible := False;
  AuthLabel.Top := Button.Top + Button.Height + ScaleY(8);

  result := Page;
end;

function createComponentGroup(Page: TWizardPage; Top: integer; ComponentName: String; ComponentVersion: String; 
    ComponentDescription: String; ContentHeight: integer): ComponentGroup;
var
  Panel, PanelHeader, PanelContent: TPanel;
  NameLabel, VersionLabel, DescriptionLabel: TNewStaticText;
begin
  Panel := TPanel.Create(Page);
  Panel.Parent := Page.Surface;
  Panel.Top := Top;
  Panel.BorderStyle := bsNone;
  Panel.Color := StringToColor('$d3d3d3');
  Panel.Width := 840;
  Panel.Height := ContentHeight + 40;
  Panel.BevelInner := bvNone;
  Panel.BevelOuter := bvNone;
  
  PanelHeader := TPanel.Create(Page);
  PanelHeader.Parent := Panel;
  PanelHeader.Top := 1;
  PanelHeader.Left := 1;
  PanelHeader.BorderStyle := bsNone;
  PanelHeader.Color := StringToColor('$f6f6f6');
  PanelHeader.Width := 838;
  PanelHeader.Height := 39;
  PanelHeader.BevelInner := bvNone;
  PanelHeader.BevelOuter := bvNone;

  NameLabel := TNewStaticText.Create(Page);
  NameLabel.Caption := ComponentName;
  NameLabel.Parent := PanelHeader;
  NameLabel.Left := 12;
  NameLabel.Top := 2;
  NameLabel.Font.Size := 11;
  NameLabel.Font.Color := StringToColor('$cc0000');
  NameLabel.Font.Style := NameLabel.Font.Style + [fsBold];

  VersionLabel := TNewStaticText.Create(Page);
  VersionLabel.Caption := ComponentVersion;
  VersionLabel.Parent := PanelHeader;
  VersionLabel.Left := NameLabel.Left + NameLabel.Width + ScaleX(4);
  VersionLabel.Top := 8;
  VersionLabel.Font.Size := 7;
  VersionLabel.Font.Color := StringToColor('$797979');

  DescriptionLabel := TNewStaticText.Create(Page);
  DescriptionLabel.Caption := ComponentDescription;
  DescriptionLabel.Parent := PanelHeader;
  DescriptionLabel.Left := 12;
  DescriptionLabel.Top := NameLabel.Top + NameLabel.Height + ScaleY(2);
  DescriptionLabel.Font.Size := 7;
  DescriptionLabel.Font.Color := StringToColor('$797979');

  PanelContent := TPanel.Create(Page);
  PanelContent.Parent := Panel;
  PanelContent.Top := 41;
  PanelContent.Left := 1;
  PanelContent.BorderStyle := bsNone;
  PanelContent.Color := clWhite;
  PanelContent.Width := 838;
  PanelContent.Height := ContentHeight - 2;
  PanelContent.BevelInner := bvNone;
  PanelContent.BevelOuter := bvNone;  

  Result.Container := Panel;
  Result.Content := PanelContent;
end;

// Create the welcome page - this page allows the user to log in to their Red Hat account
function createComponentPage: TWizardPage;
var
  Page: TWizardPage;
  HeadingLabel: TNewStaticText;
  Entry: ComponentGroup;
begin
  Page := PageFromID(wpReady);

  // The page has a unique id, we store it in the AuthPageID variable here so that we can refer to it elsewhere
  //ComponentPageID := Page.ID;

  // Create the heading label for the component selection list
  HeadingLabel := TNewStaticText.Create(Page);
  HeadingLabel.Caption := 'Select the products and tools you want to install.';
  HeadingLabel.Parent := Page.Surface;
  HeadingLabel.Font.Size := 8;

  Entry := createComponentGroup(Page, HeadingLabel.Top + HeadingLabel.Height + ScaleY(8), 
    'RED HAT ENTERPRISE LINUX ATOMIC PLATFORM', 'v2.0', 
    'Host Linux containers in a minimal version of Red Hat Enterprise Linux.', 80);

  Entry := createComponentGroup(Page, Entry.Container.Top + Entry.Container.Height + ScaleY(8), 
    'RED HAT JBOSS DEVELOPER STUDIO', 'v9.0', 
    'An IDE with tooling that will help you easily code, test, and deploy your projects.', 60);

  Entry := createComponentGroup(Page, Entry.Container.Top + Entry.Container.Height + ScaleY(8), 
    'RED HAT OPENSHIFT ENTERPRISE', 'v3.0', 
    'DevOps tooling that helps you easily build and deploy your projects in a PaaS environment.', 40);
end;

// Create the Get Started page
function createGetStartedPage: TWizardPage;
var
  Page: TWizardPage;
begin
  Page := CreateCustomPage(wpInstalling, '', '');

  // The page has a unique id, we store it in the AuthPageID variable here so that we can refer to it elsewhere
  GetStartedPageID := Page.ID;
end;

procedure CreateWizardPages;
begin
  createWelcomePage;
  createComponentPage;
  createGetStartedPage;       
end;

function createDownloadForm(PreviousPageId: Integer): Integer;
begin
    IDPForm.Page := CreateCustomPage(PreviousPageId, ExpandConstant('{cm:IDP_FormCaption}'), ExpandConstant('{cm:IDP_FormDescription}'));

    IDPForm.TotalProgressBar := TNewProgressBar.Create(IDPForm.Page);
    with IDPForm.TotalProgressBar do
    begin
        Parent := IDPForm.Page.Surface;
        Left := ScaleX(0);
        Top := ScaleY(16);
        Width := ScaleX(410);
        Height := ScaleY(20);
        Min := 0;
        Max := 100;
    end;

    IDPForm.TotalProgressLabel := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.TotalProgressLabel do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := ExpandConstant('{cm:IDP_TotalProgress}');
        Left := ScaleX(0);
        Top := ScaleY(0);
        Width := ScaleX(200);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 1;
    end;

    IDPForm.CurrentFileLabel := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.CurrentFileLabel do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := ExpandConstant('{cm:IDP_CurrentFile}');
        Left := ScaleX(0);
        Top := ScaleY(48);
        Width := ScaleX(200);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 2;
    end;

    IDPForm.FileProgressBar := TNewProgressBar.Create(IDPForm.Page);
    with IDPForm.FileProgressBar do
    begin
        Parent := IDPForm.Page.Surface;
        Left := ScaleX(0);
        Top := ScaleY(64);
        Width := ScaleX(410);
        Height := ScaleY(20);
        Min := 0;
        Max := 100;
    end;

    IDPForm.TotalDownloaded := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.TotalDownloaded do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := '';
        Left := ScaleX(290);
        Top := ScaleY(0);
        Width := ScaleX(120);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 4;
    end;

    IDPForm.FileDownloaded := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.FileDownloaded do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := '';
        Left := ScaleX(290);
        Top := ScaleY(48);
        Width := ScaleX(120);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 5;
    end;

    IDPForm.FileNameLabel := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.FileNameLabel do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := ExpandConstant('{cm:IDP_File}');
        Left := ScaleX(0);
        Top := ScaleY(100);
        Width := ScaleX(116);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 6;
    end;

    IDPForm.SpeedLabel := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.SpeedLabel do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := ExpandConstant('{cm:IDP_Speed}');
        Left := ScaleX(0);
        Top := ScaleY(116);
        Width := ScaleX(116);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 7;
    end;

    IDPForm.StatusLabel := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.StatusLabel do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := ExpandConstant('{cm:IDP_Status}');
        Left := ScaleX(0);
        Top := ScaleY(132);
        Width := ScaleX(116);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 8;
    end;

    IDPForm.ElapsedTimeLabel := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.ElapsedTimeLabel do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := ExpandConstant('{cm:IDP_ElapsedTime}');
        Left := ScaleX(0);
        Top := ScaleY(148);
        Width := ScaleX(116);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 9;
    end;

    IDPForm.RemainingTimeLabel := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.RemainingTimeLabel do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := ExpandConstant('{cm:IDP_RemainingTime}');
        Left := ScaleX(0);
        Top := ScaleY(164);
        Width := ScaleX(116);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 10;
    end;

    IDPForm.FileName := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.FileName do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := '';
        Left := ScaleX(120);
        Top := ScaleY(100);
        Width := ScaleX(280);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 11;
    end;

    IDPForm.Speed := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.Speed do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := '';
        Left := ScaleX(120);
        Top := ScaleY(116);
        Width := ScaleX(280);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 12;
    end;

    IDPForm.Status := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.Status do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := '';
        Left := ScaleX(120);
        Top := ScaleY(132);
        Width := ScaleX(280);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 13;
    end;

    IDPForm.ElapsedTime := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.ElapsedTime do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := '';
        Left := ScaleX(120);
        Top := ScaleY(148);
        Width := ScaleX(280);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 14;
    end;

    IDPForm.RemainingTime := TNewStaticText.Create(IDPForm.Page);
    with IDPForm.RemainingTime do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := '';
        Left := ScaleX(120);
        Top := ScaleY(164);
        Width := ScaleX(280);
        Height := ScaleY(14);
        AutoSize := False;
        TabOrder := 15;
    end;

    IDPForm.DetailsButton := TNewButton.Create(IDPForm.Page);
    with IDPForm.DetailsButton do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := ExpandConstant('{cm:IDP_DetailsButton}');
        Left := ScaleX(336);
        Top := ScaleY(184);
        Width := ScaleX(75);
        Height := ScaleY(23);
        TabOrder := 16;
        OnClick := @idpDetailsButtonClick;
    end;        
    
    IDPForm.InvisibleButton := TNewButton.Create(IDPForm.Page);
    with IDPForm.InvisibleButton do
    begin
        Parent := IDPForm.Page.Surface;
        Caption := ExpandConstant('You must not see this button');
        Left := ScaleX(0);
        Top := ScaleY(0);
        Width := ScaleX(10);
        Height := ScaleY(10);
        TabOrder := 17;
        Visible := False;
        OnClick := @idpReportErrorHelper;
    end;
  
    with IDPForm.Page do
    begin
        OnActivate          := @idpFormActivate;
        OnShouldSkipPage    := @idpShouldSkipPage;
        OnBackButtonClick   := @idpBackButtonClick;
        OnNextButtonClick   := @idpNextButtonClick;
        OnCancelButtonClick := @idpCancelButtonClick;
    end;
  
    Result := IDPForm.Page.ID;
end;

procedure CustomWpInstallingPage;
var
  Page: TWizardPage;
  HeadingLabel: TNewStaticText;
begin
  Page := CreateCustomPage(wpReady, '', '');

  // Create the heading label for the component selection list
  HeadingLabel := TNewStaticText.Create(Page);
  HeadingLabel.Caption := 'Installing components';
  HeadingLabel.Parent := Page.Surface;
  HeadingLabel.Font.Size := 8;

  // Render the page

  Page.Surface.Show;
  Page.Surface.Update;
end;

procedure SelectBreadcrumb(Index: Integer);
var
  I: Integer;
  ItemColor: TColor;
begin
  for I := 1 to 4 do
  begin
    if (I = Index) then
      begin     
        ItemColor := StdColor;
        BreadcrumbLabel[I].Font.Style := BreadcrumbLabel[I].Font.Style + [fsBold];
      end
    else
      begin
        ItemColor := StringToColor('$cccccc');
        BreadcrumbLabel[I].Font.Style := BreadcrumbLabel[I].Font.Style - [fsBold];
      end;

    BreadcrumbLabel[I].Font.Color := ItemColor;
    BreadcrumbLabel[I].Width := 120;
    BreadcrumbLabel[I].Alignment := taCenter;

    with Breadcrumbs.Bitmap.Canvas do
    begin
      Brush.Color := ItemColor;
      Brush.Style := bsSolid;
      Pen.Color := ItemColor;;
      Ellipse(BreadcrumbLabel[I].Left + 54, 22, BreadcrumbLabel[I].Left + 64, 12);
    end;
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if (CurPageID = AuthPageID) then 
  begin
    SelectBreadcrumb(1);
    WizardForm.NextButton.Visible := False;
  end else if (CurPageID = wpReady) then
  begin
    SelectBreadcrumb(2);    
  end else if (CurPageID = DownloadPageID) then
  begin
    SelectBreadcrumb(3);
    WizardForm.NextButton.Visible := False;
  end else if (CurPageID = GetStartedPageID) then
  begin 
    SelectBreadcrumb(4);
    WizardForm.NextButton.Visible := True;
    WizardForm.BackButton.Visible := False;
    WizardForm.NextButton.Caption := 'Finish';
  end;

  if (CurPageID = wpInstalling) then
  begin
    CustomWpInstallingPage();
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ErrorCode: Integer;
  ExecInfo: TShellExecuteInfo;
begin
  if CurStep = ssInstall then
  begin
    // Install Zulu JDK
    ShellExec('', 'msiexec', ExpandConstant('/i {tmp}\zulu1.8.0_60-8.9.0.4-win64.msi INSTALLDIR="{app}\zulu-8" /passive /norestart'), 
        '', SW_SHOW, ewWaitUntilTerminated, ErrorCode);

    // Extract the install config and batch file for JBDS
    ExtractTemporaryFile('InstallConfigRecord.xml');

    // Replace the {installDir} token in the XML config file with the application directory
    FileReplaceString(ExpandConstant('{tmp}\InstallConfigRecord.xml'), '{installDir}', ExpandConstant('{app}'));

    // Install JBDS
    ExecInfo.cbSize := SizeOf(ExecInfo);
    ExecInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
    ExecInfo.Wnd := 0;

    ExecInfo.lpFile := ExpandConstant('{app}\zulu-8\bin\javaw.exe');
    ExecInfo.lpParameters := ExpandConstant('-jar {tmp}\' + JBDS_FILENAME + ' {tmp}\InstallConfigRecord.xml');

    ExecInfo.nShow := SW_SHOW; // SW_HIDE

    if ShellExecuteEx(ExecInfo) then
    begin
      if WaitForSingleObject(ExecInfo.hProcess, 10 * 60 * 1000 {10 minutes}) = WAIT_TIMEOUT then
      begin
        TerminateProcess(ExecInfo.hProcess, 666);
        Log('JBoss Developer Studio Installer Failed');
      end;
    end;


    // Extract the VirtualBox msi files from the downloaded exe
    Shellexec('', ExpandConstant('{tmp}\VirtualBox-5.0.2-102096-Win.exe'), ExpandConstant('--extract -path {tmp} --silent'),
        '', SW_SHOW, ewWaitUntilTerminated, ErrorCode);

    // Install VirtualBox
    ShellExec('', 'msiexec', ExpandConstant('/i {tmp}\VirtualBox-5.0.2-r102096-MultiArch_amd64.msi INSTALLDIR="{app}\VirtualBox" /passive /norestart'), 
        '', SW_SHOW, ewWaitUntilTerminated, ErrorCode);


    // Install Vagrant
    ShellExec('', 'msiexec', ExpandConstant('/i {tmp}\vagrant_1.7.4.msi VAGRANTAPPDIR="{app}\Vagrant" /passive /norestart'), 
        '', SW_SHOW, ewWaitUntilTerminated, ErrorCode);
  end;

end;

procedure CreateBreadcrumbLabel(Index: Integer; Caption: String);
begin
  BreadcrumbLabel[Index] := TLabel.Create(WizardForm.MainPanel);
  BreadcrumbLabel[Index].Caption := Caption;
  BreadcrumbLabel[Index].Parent := WizardForm.MainPanel;
  BreadcrumbLabel[Index].Font.Color := StringToColor('$cccccc');
  BreadcrumbLabel[Index].Font.Size := 8;
  BreadcrumbLabel[Index].Top := 24;
  BreadcrumbLabel[Index].Left := 36 + ((Index - 1) * 120);
  BreadcrumbLabel[Index].Width := 120;
  BreadcrumbLabel[Index].Alignment := taCenter;
end;             

procedure InitializeWizard();
var
  BackgroundBitmapImage: TBitmapImage;
  BackgroundBitmapText: TNewStaticText;
  BitmapFileName: String;
begin
  StdColor := StringToColor('$0093d9');

  { Custom wizard pages }

  WizardForm.PageNameLabel.Visible := False;
  WizardForm.PageDescriptionLabel.Visible := False;

  WizardForm.OuterNotebook.Width := 880;
  WizardForm.OuterNotebook.Height := 460;

  WizardForm.InnerNotebook.Width := 880;
  WizardForm.InnerNotebook.Height := 460;

  // Set the width of the top panel
  WizardForm.MainPanel.Width := 920;

  WizardForm.WizardSmallBitmapImage.Visible := false;

  Breadcrumbs := TBitmapImage.Create(WizardForm.MainPanel);
  Breadcrumbs.Parent := WizardForm.MainPanel;
  Breadcrumbs.Top := 0;
  Breadcrumbs.Left := 0;
  Breadcrumbs.Width := 600;
  Breadcrumbs.Height := 50;
  Breadcrumbs.AutoSize := True;

  Breadcrumbs.Bitmap.Height := 50;
  Breadcrumbs.Bitmap.Width := 600;

  with Breadcrumbs.Bitmap.Canvas do
  begin
    Pen.Color := StringToColor('$cccccc');
    MoveTo(1, 16);
    LineTo(460,16);
  end;

  // Create the breadcrumb labels
  CreateBreadcrumbLabel(1, 'Install Setup');
  CreateBreadcrumbLabel(2, 'Confirmation');
  CreateBreadcrumbLabel(3, 'Download && Install');
  CreateBreadcrumbLabel(4, 'Get Started');

  WizardForm.BorderStyle := bsSingle;
  WizardForm.Color := clWhite;

  // These lines change the width and height of the wizard window, but components need to be repositioned
  WizardForm.Width := 940;
  WizardForm.Height := 565;
  WizardForm.Position := poScreenCenter;

  // Let's just hide the cancel button, if the user wishes to cancel they can just close the installer window
  WizardForm.CancelButton.Visible := False;
  //WizardForm.CancelButton.Top := 500;
  //WizardForm.CancelButton.Left := 32;

  WizardForm.NextButton.Top := 500;
  WizardForm.NextButton.Left := 840;

  WizardForm.BackButton.Top := 500;
  WizardForm.BackButton.Left := 32;

  WizardForm.Bevel.Visible := False;
  WizardForm.Bevel1.Visible := False;

  // Sets the background color of the inner panel to white
  WizardForm.InnerPage.Color := clWhite;

  CreateWizardPages;

  // Show details by default
  idpSetOption('DetailedMode', '1');

  // Hide the 'Details' button
  idpSetOption('DetailsButton', '0');

  // Zulu
  idpSetOption('Referer', 'http://www.azulsystems.com/products/zulu/downloads');
  idpAddFile('http://cdn.azulsystems.com/zulu/bin/zulu1.8.0_60-8.9.0.4-win64.msi', ExpandConstant('{tmp}\zulu1.8.0_60-8.9.0.4-win64.msi'));
  //idpAddFile('http://192.168.1.114/~shane/zulu1.8.0_60-8.9.0.4-win64.msi', ExpandConstant('{tmp}\zulu1.8.0_60-8.9.0.4-win64.msi'));

  // JBDS - JBoss Developer Studio
  idpAddFile('https://devstudio.redhat.com/9.0/snapshots/builds/devstudio.product_9.0.mars/latest/all/jboss-devstudio-9.1.0.Beta1-v20151122-1948-B143-installer-standalone.jar',
             ExpandConstant('{tmp}\jboss-devstudio-installer-standalone.jar'));
  //idpAddFile('http://192.168.1.114/~shane/' + JBDS_FILENAME, ExpandConstant('{tmp}\') + JBDS_FILENAME);
               
  // VirtualBox
  idpAddFile('http://download.virtualbox.org/virtualbox/5.0.2/VirtualBox-5.0.2-102096-Win.exe', ExpandConstant('{tmp}\VirtualBox-5.0.2-102096-Win.exe'));
  //idpAddFile('http://192.168.1.114/~shane/VirtualBox-5.0.2-102096-Win.exe', ExpandConstant('{tmp}\VirtualBox-5.0.2-102096-Win.exe'));
  
  // Vagrant
  idpAddFile('https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.4.msi', ExpandConstant('{tmp}\vagrant_1.7.4.msi'));
  //idpAddFile('http://192.168.1.114/~shane/vagrant_1.7.4.msi', ExpandConstant('{tmp}\vagrant_1.7.4.msi'));

  idpDownloadAfter(wpReady);

  DownloadPageID := createDownloadForm(wpReady);

  idpConnectControls;
  idpInitMessages;
end;


