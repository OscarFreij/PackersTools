[Code]
var
    ChoicePage: TWizardPage;
    RadioDefault, RadioFolder, RadioURL, RadioIgnore: TRadioButton;
    DirPage: TInputDirWizardPage;
    UrlPage: TInputQueryWizardPage;
    UrlInput: string;
    DefaultPSADTTemplateURL: string;

// Helper function to copy directories recursively
function CopyDir(const Source, Dest: string; const Recurse: Boolean): Boolean;
var
    FindRec: TFindRec;
    SourceFile, DestFile: string;
begin
    Result := True;
    if not DirExists(Dest) then
        ForceDirectories(Dest);

    if FindFirst(Source + '\*', FindRec) then
    begin
        repeat
        if (FindRec.Attributes and FILE_ATTRIBUTE_DIRECTORY) = FILE_ATTRIBUTE_DIRECTORY then
        begin
            if (FindRec.Name <> '.') and (FindRec.Name <> '..') and Recurse then
            begin
            Result := Result and CopyDir(Source + '\' + FindRec.Name, Dest + '\' + FindRec.Name, True);
            end;
        end
        else
        begin
            SourceFile := Source + '\' + FindRec.Name;
            DestFile := Dest + '\' + FindRec.Name;
            Result := Result and CopyFile(SourceFile, DestFile, False);
        end;
        until not FindNext(FindRec);
        FindClose(FindRec);
    end;
end;

function DownloadZip(const Url, DestZip: string): Boolean;
var
  ResultCode: Integer;
begin
  Result :=
    Exec(
      'powershell.exe',
      '-NoProfile -ExecutionPolicy Bypass -Command ' +
      '"Invoke-WebRequest -Uri ''' + Url + ''' -OutFile ''' + DestZip + '''"',
      '',
      SW_HIDE,
      ewWaitUntilTerminated,
      ResultCode
    )
    and (ResultCode = 0);
end;

function ExtractZip(const ZipFile, DestDir: string): Boolean;
var
  ResultCode: Integer;
begin
  ForceDirectories(DestDir);

  Result :=
    Exec(
      'powershell.exe',
      '-NoProfile -ExecutionPolicy Bypass -Command ' +
      '"Expand-Archive -Force ''' + ZipFile + ''' ''' + DestDir + '''"',
      '',
      SW_HIDE,
      ewWaitUntilTerminated,
      ResultCode
    )
    and (ResultCode = 0);
end;

procedure SetInstallStatus(const Msg: string);
begin
  WizardForm.StatusLabel.Caption := Msg;
  WizardForm.StatusLabel.Refresh;
end;



procedure InitializeWizard();
begin

    DefaultPSADTTemplateURL := 'https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases/latest/download/PSAppDeployToolkit_Template_v4.zip';
    
    ChoicePage := CreateCustomPage(
        wpSelectDir,
        'Add Template',
        'Choose how you want to add a template or skip this step.'
    );

    // Radio buttons
    RadioDefault := TRadioButton.Create(ChoicePage.Surface);
    RadioDefault.Parent := ChoicePage.Surface;
    RadioDefault.Caption := 'Download PSADT v4 Latest Template (default)';
    RadioDefault.Top := 0;
    RadioDefault.Left := 0;
    RadioDefault.Width := 400;
    RadioDefault.Checked := True;


    RadioFolder := TRadioButton.Create(ChoicePage.Surface);
    RadioFolder.Parent := ChoicePage.Surface;
    RadioFolder.Caption := 'Select a folder to copy';
    RadioFolder.Top := 24;
    RadioFolder.Left := 0;
    RadioFolder.Width := 400;

    RadioURL := TRadioButton.Create(ChoicePage.Surface);
    RadioURL.Parent := ChoicePage.Surface;
    RadioURL.Caption := 'Download from .ZIP from weblink';
    RadioURL.Top := 48;
    RadioURL.Left := 0;
    RadioURL.Width := 400;

    RadioIgnore := TRadioButton.Create(ChoicePage.Surface);
    RadioIgnore.Parent := ChoicePage.Surface;
    RadioIgnore.Caption := 'Skip (Requires manual update after install)';
    RadioIgnore.Top := 72;
    RadioIgnore.Left := 0;
    RadioIgnore.Width := 400;

    DirPage := CreateInputDirPage(
        ChoicePage.ID, // insert after our choice page
        'Select Template Source',
        'Select a folder to copy templates from',
        'Choose a folder to copy into your templates directory',
        False,
        'Browse...'
    );
    DirPage.Add('');

    UrlPage := CreateInputQueryPage(
        ChoicePage.ID, // insert after our choice page
        'Enter Template URL',
        'Enter the URL to download the template from. (default is latest PSADT v4 template)',
        'Please provide a valid URL to download the template zip file from.'
    );
    UrlPage.Add('&Template URL:', False);
    UrlPage.Values[0] := 'https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases/latest/download/PSAppDeployToolkit_Template_v4.zip';
    UrlInput := UrlPage.Values[0];
end;

// Skip the folder page if "Folder" is not selected
function ShouldSkipPage(PageID: Integer): Boolean;
begin
    Result := False;

    if PageID = DirPage.ID then
    begin
        if not RadioFolder.Checked then
        Result := True; // skip folder selection
    end;
    if PageID = UrlPage.ID then
    begin
        if not RadioURL.Checked then
        Result := True; // skip URL input
    end;
end;


procedure CurStepChanged(CurStep: TSetupStep);
var
  DestDir, ZipPath: string;
begin
    if CurStep = ssPostInstall then
    begin
        DestDir := ExpandConstant('{app}\template');
        ZipPath := ExpandConstant('{tmp}\templates.zip');
        if RadioDefault.Checked then
        begin
            // Download default PSADT v4 template
            SetInstallStatus('Downloading template...');
            DownloadZip(DefaultPSADTTemplateURL, ZipPath);
            SetInstallStatus('Extracting template...');
            ExtractZip(ZipPath, DestDir);

        end
        else if RadioFolder.Checked then
        begin
        if DirPage.Values[0] <> '' then
            SetInstallStatus('Copying templates from local folder...');
            CopyDir(DirPage.Values[0], DestDir, True);
            SetInstallStatus('Templates copied successfully.');
        end
        else if RadioURL.Checked then
        begin
            if UrlInput <> '' then
            begin
            SetInstallStatus('Downloading template...');
            DownloadZip(UrlInput, ZipPath);
            SetInstallStatus('Extracting template...');
            ExtractZip(ZipPath, DestDir);
            end
        end
        else if RadioIgnore.Checked then
        begin
        // do nothing
        end;
    end;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  ExtraText: string;
begin
    if CurPageID = wpReady then
    begin
        ExtraText := '';

        if RadioDefault.Checked then
            ExtraText := ExtraText + #13#10 + 'Templates will be downloaded from the default source.' + #13#10;

        if RadioFolder.Checked then
            ExtraText := ExtraText + #13#10 + 'Templates will be copied from:' + #9 + DirPage.Values[0] + #13#10;

        if RadioURL.Checked then
            ExtraText := ExtraText + #13#10 + 'Templates will be downloaded from: ' + #9 + UrlInput + #13#10;

        if RadioIgnore.Checked then
            ExtraText := ExtraText + #13#10 + 'No templates will be added during installation.' + #13#10;

        WizardForm.ReadyMemo.Lines.Add(ExtraText);
    end;
end;

