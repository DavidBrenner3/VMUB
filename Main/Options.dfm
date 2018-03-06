object frmOptions: TfrmOptions
  Left = 287
  Top = 76
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'Options'
  ClientHeight = 711
  ClientWidth = 586
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poDesigned
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  DesignSize = (
    586
    711)
  PixelsPerInch = 96
  TextHeight = 13
  object pnlAll: TPanel
    Left = 8
    Top = 8
    Width = 571
    Height = 667
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelInner = bvLowered
    BevelOuter = bvSpace
    DoubleBuffered = True
    FullRepaint = False
    ParentBackground = False
    ParentDoubleBuffered = False
    TabOrder = 0
    DesignSize = (
      571
      667)
    object gbGeneral: TGroupBox
      Left = 8
      Top = 10
      Width = 554
      Height = 193
      Anchors = [akLeft, akTop, akRight]
      Caption = 'General'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      DesignSize = (
        554
        193)
      object lblWaitTime: TLabel
        Left = 8
        Top = 21
        Width = 324
        Height = 16
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Wait time to flush system data before dismounting (ms):'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        Transparent = True
      end
      object lblLanguage: TLabel
        Left = 8
        Top = 166
        Width = 157
        Height = 16
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Choose interface language:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        Transparent = True
      end
      object lblDefaultVMType: TLabel
        Left = 8
        Top = 81
        Width = 244
        Height = 16
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Default VM type when adding a new entry:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblKeyCombination: TLabel
        Left = 8
        Top = 140
        Width = 239
        Height = 16
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Hotkey to start the current selected entry:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object cbLock: TCheckBox
        Left = 8
        Top = 43
        Width = 536
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 
          'Lock the volumes on the drive before dismounting (safe but somet' +
          'imes slow)'
        Checked = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        State = cbChecked
        TabOrder = 1
        OnKeyDown = AllKeyDown
      end
      object cbSecondDrive: TCheckBox
        Left = 8
        Top = 62
        Width = 536
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Show a second drive option'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnKeyDown = AllKeyDown
      end
      object edtWaitTime: TEdit
        Left = 344
        Top = 18
        Width = 200
        Height = 24
        Anchors = [akTop, akRight]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        MaxLength = 5
        ParentFont = False
        TabOrder = 0
        Text = '500'
        OnKeyDown = AllKeyDown
        OnKeyPress = edtWaitTimeKeyPress
      end
      object cbListOnlyUSBDrives: TCheckBox
        Left = 8
        Top = 100
        Width = 357
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'List only USB drives'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 5
        OnKeyDown = AllKeyDown
      end
      object cbAutomaticFont: TCheckBox
        Left = 8
        Top = 119
        Width = 357
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Font size, style and color will be set automatically'
        Checked = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        State = cbChecked
        TabOrder = 7
        OnClick = cbAutomaticFontClick
        OnKeyDown = AllKeyDown
      end
      object cmbLanguage: TComboBox
        Left = 172
        Top = 163
        Width = 372
        Height = 24
        Style = csDropDownList
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 9
        OnKeyDown = AllKeyDown
      end
      object btnChooseFont: TPngBitBtn
        Left = 428
        Top = 110
        Width = 116
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Choose font'
        Enabled = False
        TabOrder = 6
        OnClick = btnChooseFontClick
        OnKeyDown = AllKeyDown
        PngImage.Data = {
          89504E470D0A1A0A0000000D49484452000000110000001108060000003B6D47
          FA00000006624B474400FF00FF00FFA0BDA793000000097048597300000EC400
          000EC401952B0E1B0000000774494D4507E001060327282FAD63880000001D69
          545874436F6D6D656E7400000000004372656174656420776974682047494D50
          642E6507000001A14944415478DA63FCFFFF3F03A58091E68630CA859830089A
          B8FEBF58D14EBE21FA53EA1958FEC933FC383FE9FFD5F91748368491915192C1
          68622B98F3E70BFBFF8B55D1A41B62DA53C0F0F52D23031BBF2DC3BFEF420C1F
          AEB6FF7FB46627698618B42F61B8D85CC1609CD7C0F08B5D85E1CFEF17FFAFB5
          45106D08A376860703B3A4FBFF4BF5858C0A91560C926A6D0C5F81126F8ED4FD
          7FB6F7107186E835F7333C3934EFFFBBDD97C17C8BDAAD0CDF98B8193E3DBAF4
          FFC1FC3C8286300AE82B328844F632707C78C7F0E52D03038F3050905592E1FB
          076E867F3F8518EEAF89FEFFFFDD65FC86E8D65531B0FF106378B8651103AB20
          0FC387FF7F18185F7F6790F4E867E0041AF2E1D381FF8F57E4E134849191479C
          C1AC682EE7A99EF46FFFBF3D8589DB69314A1EFE999CC0F09F2992E1DFDFCFFF
          1FCCB5C66A08A3A0A10283B87332C3AF6F860C8CB73FFCBFBB3B06AE48DE238C
          8199A786815B0822F0F935D0A0F5D6988688294A307C17116160616461F8F59E
          F1FFD7DBE7618A040519153EFC931163F8F4899181938599E1F7F7FFFF7F7F3B
          4E309D9002068F21003D01C7DFE491BBE20000000049454E44AE426082}
        PngOptions = [pngBlendOnDisabled, pngGrayscaleOnDisabled]
      end
      object pnlQEMU: TPanel
        Left = 441
        Top = 79
        Width = 103
        Height = 25
        Anchors = [akTop, akRight]
        BevelInner = bvLowered
        DoubleBuffered = False
        ParentDoubleBuffered = False
        TabOrder = 4
        TabStop = True
        OnEnter = pnlQEMUEnter
        OnExit = pnlQEMUExit
        object sbQEMU: TPngSpeedButton
          Left = 2
          Top = 2
          Width = 99
          Height = 21
          Align = alClient
          AllowAllUp = True
          GroupIndex = 2
          Caption = '  QEMU'
          Flat = True
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          OnClick = sbQEMUClick
          OnMouseActivate = sbQEMUMouseActivate
          ExplicitWidth = 100
          ExplicitHeight = 22
        end
      end
      object pnlVirtualBox: TPanel
        Left = 335
        Top = 79
        Width = 107
        Height = 25
        Anchors = [akTop, akRight]
        BevelInner = bvLowered
        DoubleBuffered = False
        ParentDoubleBuffered = False
        TabOrder = 3
        TabStop = True
        OnEnter = pnlVirtualBoxEnter
        OnExit = pnlVirtualBoxExit
        object sbVirtualBox: TPngSpeedButton
          Left = 2
          Top = 2
          Width = 103
          Height = 21
          Align = alClient
          AllowAllUp = True
          GroupIndex = 1
          Down = True
          Caption = '  VirtualBox'
          Flat = True
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          OnClick = sbVirtualBoxClick
          OnMouseActivate = sbVirtualBoxMouseActivate
          ExplicitWidth = 104
          ExplicitHeight = 22
        end
      end
      object hkStart: THotKey
        Left = 335
        Top = 139
        Width = 209
        Height = 19
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        HotKey = 0
        Modifiers = []
        TabOrder = 8
      end
    end
    object gbVirtualBox: TGroupBox
      Left = 8
      Top = 206
      Width = 554
      Height = 314
      Anchors = [akLeft, akTop, akRight]
      Caption = '     VirtualBox'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      DesignSize = (
        554
        314)
      object lblVBExePath: TLabel
        Left = 8
        Top = 21
        Width = 54
        Height = 16
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Exe path:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object btnBrowseForVBExe: TPngSpeedButton
        Left = 519
        Top = 18
        Width = 26
        Height = 24
        Hint = 'click to browse for exe'
        Anchors = [akTop, akRight]
        Flat = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        OnClick = btnBrowseForVBExeClick
      end
      object imgVB: TImage
        Left = 3
        Top = 2
        Width = 17
        Height = 16
        Transparent = True
      end
      object edtVBExePath: TEdit
        Left = 71
        Top = 18
        Width = 473
        Height = 24
        Anchors = [akTop, akRight]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        MaxLength = 1024
        ParentFont = False
        TabOrder = 0
        OnKeyDown = AllKeyDown
      end
      object gbUpdateMethod: TGroupBox
        Left = 8
        Top = 48
        Width = 537
        Height = 84
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Method to update the VM configuration file (*.vbox)'
        TabOrder = 1
        DesignSize = (
          537
          84)
        object cbUseVboxmanage: TCheckBox
          Left = 8
          Top = 40
          Width = 513
          Height = 17
          Anchors = [akLeft, akTop, akRight]
          Caption = 'use VBoxManage.exe command line (slower)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          OnClick = cbUseVboxmanageClick
          OnKeyDown = AllKeyDown
        end
        object cbDirectly: TCheckBox
          Left = 8
          Top = 59
          Width = 517
          Height = 17
          Anchors = [akLeft, akTop, akRight]
          Caption = 'directly (faster, but VB Manager must be closed)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 2
          OnClick = cbDirectlyClick
          OnKeyDown = AllKeyDown
        end
        object cbAutoDetect: TCheckBox
          Left = 8
          Top = 21
          Width = 517
          Height = 17
          Anchors = [akLeft, akTop, akRight]
          Caption = 'try to autodetect the most appropriate for the given situation'
          Checked = True
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          State = cbChecked
          TabOrder = 0
          OnClick = cbAutoDetectClick
          OnKeyDown = AllKeyDown
        end
      end
      object cbRemoveDrive: TCheckBox
        Left = 8
        Top = 289
        Width = 537
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Remove the drive(s) from the VM after closing'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 4
        WordWrap = True
        OnKeyDown = AllKeyDown
      end
      object gbPortable: TGroupBox
        Left = 8
        Top = 135
        Width = 537
        Height = 83
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Portable VirtualBox'
        TabOrder = 2
        DesignSize = (
          537
          83)
        object cbLoadUSBPortable: TCheckBox
          Left = 8
          Top = 59
          Width = 517
          Height = 17
          Anchors = [akLeft, akTop, akRight]
          Caption = 'Load the USB driver and services'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 2
          WordWrap = True
          OnKeyDown = AllKeyDown
        end
        object cbLoadNetPortable: TCheckBox
          Left = 8
          Top = 40
          Width = 517
          Height = 17
          Anchors = [akLeft, akTop, akRight]
          Caption = 'Load network drivers and services'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          WordWrap = True
          OnKeyDown = AllKeyDown
        end
        object cbuseLoadedFromInstalled: TCheckBox
          Left = 8
          Top = 21
          Width = 517
          Height = 17
          Anchors = [akLeft, akTop, akRight]
          Caption = 
            'Use the already loaded dlls/drivers/services from the installed ' +
            'version (if found)'
          Checked = True
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          State = cbChecked
          TabOrder = 0
          WordWrap = True
          OnClick = cbuseLoadedFromInstalledClick
          OnKeyDown = AllKeyDown
        end
      end
      object gbApplicationStartup: TGroupBox
        Left = 8
        Top = 221
        Width = 537
        Height = 64
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Application startup'
        TabOrder = 3
        DesignSize = (
          537
          64)
        object cbPrecacheVBFiles: TCheckBox
          Left = 8
          Top = 21
          Width = 517
          Height = 17
          Anchors = [akLeft, akTop, akRight]
          Caption = 'Precache the VirtualBox files'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          WordWrap = True
          OnKeyDown = AllKeyDown
        end
        object cbPrestartVBExeFiles: TCheckBox
          Left = 8
          Top = 40
          Width = 517
          Height = 17
          Anchors = [akLeft, akTop, akRight]
          Caption = 'Prestart the VirtualBox exe files'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          WordWrap = True
          OnKeyDown = AllKeyDown
        end
      end
    end
    object gbQemu: TGroupBox
      Left = 8
      Top = 525
      Width = 554
      Height = 129
      Anchors = [akLeft, akTop, akRight]
      Caption = '     QEMU'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      DesignSize = (
        554
        129)
      object lblQExePath: TLabel
        Left = 8
        Top = 21
        Width = 54
        Height = 16
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Exe path:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblDefaultParameters: TLabel
        Left = 8
        Top = 72
        Width = 224
        Height = 16
        Anchors = [akLeft, akTop, akRight]
        Caption = 'The default command line parameters:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object imgQEMU: TImage
        Left = 6
        Top = 1
        Width = 17
        Height = 16
        Anchors = [akLeft, akTop, akRight]
        Transparent = True
      end
      object btnBrowseForQExe: TPngSpeedButton
        Left = 519
        Top = 18
        Width = 26
        Height = 24
        Hint = 'click to browse for exe'
        Anchors = [akTop, akRight]
        Flat = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        OnClick = btnBrowseForQExeClick
      end
      object lblEmulationBusType: TLabel
        Left = 238
        Top = 51
        Width = 113
        Height = 16
        Anchors = [akTop]
        Caption = 'Emulation bus type:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object edtQExePath: TEdit
        Left = 71
        Top = 18
        Width = 251
        Height = 24
        Anchors = [akLeft, akTop, akRight]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        MaxLength = 1024
        ParentFont = False
        TabOrder = 0
        OnKeyDown = AllKeyDown
      end
      object edtDefaultParameters: TEdit
        Left = 8
        Top = 94
        Width = 536
        Height = 24
        Hint = 'Basic parameters for x86/x64 version'
        Anchors = [akLeft, akTop, akRight]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        MaxLength = 10240
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
        Text = '-name "USB Boot Test" -boot c -m 512 -soundhw sb16'
        OnChange = edtDefaultParametersChange
        OnKeyDown = AllKeyDown
      end
      object cmbExeVersion: TComboBox
        Left = 328
        Top = 18
        Width = 215
        Height = 24
        Style = csDropDownList
        Anchors = [akLeft, akTop, akRight]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        MaxLength = 1024
        ParentFont = False
        TabOrder = 1
        OnKeyDown = AllKeyDown
      end
      object cbHideConsoleWindow: TCheckBox
        Left = 8
        Top = 50
        Width = 177
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Hide the console window'
        Checked = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        State = cbChecked
        TabOrder = 2
        WordWrap = True
        OnKeyDown = AllKeyDown
      end
      object cbEmulationBusType: TComboBox
        Left = 357
        Top = 48
        Width = 187
        Height = 24
        Style = csDropDownList
        Anchors = [akTop, akRight]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ItemIndex = 1
        MaxLength = 1024
        ParentFont = False
        TabOrder = 4
        Text = 'SCSI (fast, less compatible)'
        OnKeyDown = AllKeyDown
        Items.Strings = (
          'IDE (slow, compatible)'
          'SCSI (fast, less compatible)')
      end
    end
  end
  object btnOK: TPngBitBtn
    Left = 129
    Top = 681
    Width = 90
    Height = 25
    Anchors = [akBottom]
    Caption = 'OK'
    Default = True
    Spacing = 10
    TabOrder = 1
    OnClick = btnOKClick
    OnKeyDown = AllKeyDown
  end
  object btnCancel: TPngBitBtn
    Left = 375
    Top = 681
    Width = 90
    Height = 25
    Anchors = [akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    Spacing = 10
    TabOrder = 2
    OnKeyDown = AllKeyDown
  end
  object odSearchQExe: TOpenDialog
    Filter = 'Exe files (*.exe)|*.exe|All files (*.*)|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Title = 'Open'
    Left = 376
    Top = 48
  end
  object fdListViewFont: TFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Left = 407
    Top = 328
  end
  object xmlTemp: TXMLDocument
    Left = 184
    Top = 48
    DOMVendorDesc = 'MSXML'
  end
  object odSearchVBExe: TOpenDialog
    Filter = 'Exe files (*.exe)|*.exe|All files (*.*)|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Title = 'Open'
    Left = 384
    Top = 56
  end
end
