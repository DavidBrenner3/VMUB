object frmAddEdit: TfrmAddEdit
  Left = 311
  Top = 204
  BorderIcons = [biSystemMenu]
  BorderStyle = bsToolWindow
  Caption = 'Add'
  ClientHeight = 350
  ClientWidth = 594
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  DesignSize = (
    594
    350)
  PixelsPerInch = 96
  TextHeight = 13
  object pnlAll: TPanel
    Left = 8
    Top = 8
    Width = 576
    Height = 302
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelInner = bvLowered
    TabOrder = 0
    DesignSize = (
      576
      302)
    object lblType: TLabel
      Left = 13
      Top = 12
      Width = 41
      Height = 19
      Caption = 'Type:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblExeParams: TLabel
      Left = 13
      Top = 108
      Width = 115
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'Exe parameters:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
      Visible = False
      ExplicitTop = 76
    end
    object lblFirstDrive: TLabel
      Left = 13
      Top = 140
      Width = 194
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'First drive to add and boot:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblRun: TLabel
      Left = 13
      Top = 236
      Width = 34
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'Run:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblSecondDrive: TLabel
      Left = 13
      Top = 172
      Width = 221
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'Second drive to add (optional):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblVMName: TLabel
      Left = 13
      Top = 108
      Width = 74
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'VM Name:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblPriority: TLabel
      Left = 13
      Top = 268
      Width = 92
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'CPU priority:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblVMPath: TLabel
      Left = 13
      Top = 108
      Width = 64
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'VM Path:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
      Visible = False
    end
    object lblMode: TLabel
      Left = 13
      Top = 44
      Width = 152
      Height = 19
      Caption = 'Mode to load the VM:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblEnableCPUVirtualization: TLabel
      Left = 13
      Top = 204
      Width = 148
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'Enable VT-x/AMD-V:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object lblAudio: TLabel
      Left = 13
      Top = 204
      Width = 48
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'Audio:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
      Visible = False
    end
    object lblMemory: TLabel
      Left = 13
      Top = 172
      Width = 101
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'Memory (MB):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
      Visible = False
    end
    object lblHDD: TLabel
      Left = 13
      Top = 108
      Width = 99
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'Internal HDD:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
      Visible = False
    end
    object lblCDROM: TLabel
      Left = 13
      Top = 140
      Width = 114
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'CD/DVD device:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
      Visible = False
    end
    object btnBrowseForHDD: TPngSpeedButton
      Left = 542
      Top = 106
      Width = 26
      Height = 24
      Hint = 'click to browse for HDD image file'
      Anchors = [akRight, akBottom]
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      Visible = False
      OnClick = btnBrowseForHDDClick
      ExplicitLeft = 570
      ExplicitTop = 74
    end
    object btnBrowseForVM: TPngSpeedButton
      Left = 542
      Top = 106
      Width = 26
      Height = 24
      Hint = 'click to browse for VM'
      Anchors = [akRight, akBottom]
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      Visible = False
      OnClick = btnBrowseForVMClick
      ExplicitLeft = 570
      ExplicitTop = 74
    end
    object lblCache: TLabel
      Left = 13
      Top = 76
      Width = 140
      Height = 19
      Anchors = [akLeft, akBottom]
      Caption = 'Use host I/O cache:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object edtExeParams: TEdit
      Left = 245
      Top = 106
      Width = 322
      Height = 24
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxLength = 10240
      ParentFont = False
      TabOrder = 3
      Visible = False
      OnChange = edtExeParamsChange
      OnKeyDown = AllKeyDown
    end
    object cmbWS: TComboBox
      Left = 245
      Top = 234
      Width = 322
      Height = 24
      Style = csOwnerDrawFixed
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 18
      ItemIndex = 0
      ParentFont = False
      TabOrder = 14
      Text = 'Normal'
      OnKeyDown = AllKeyDown
      Items.Strings = (
        'Normal'
        'Minimized'
        'Maximized'
        'Fullscreen')
    end
    object cmbPriority: TComboBox
      Left = 245
      Top = 266
      Width = 322
      Height = 24
      Style = csOwnerDrawFixed
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 18
      ItemIndex = 1
      ParentFont = False
      TabOrder = 15
      Text = 'Normal'
      OnKeyDown = AllKeyDown
      Items.Strings = (
        'BelowNormal'
        'Normal'
        'AboveNormal'
        'High')
    end
    object cmbMode: TComboBox
      Left = 246
      Top = 44
      Width = 322
      Height = 24
      Style = csOwnerDrawFixed
      Anchors = [akTop, akRight]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 18
      ItemIndex = 0
      ParentFont = False
      TabOrder = 2
      Text = 'VM Name'
      OnChange = cmbModeChange
      OnKeyDown = AllKeyDown
      Items.Strings = (
        'VM Name'
        'VM Path'
        'Exe parameters')
    end
    object edtVMPath: TEdit
      Left = 245
      Top = 106
      Width = 291
      Height = 24
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxLength = 1024
      ParentFont = False
      TabOrder = 4
      Visible = False
      OnKeyDown = AllKeyDown
    end
    object cmbFirstDrive: TComboBox
      Left = 245
      Top = 138
      Width = 322
      Height = 24
      Style = csOwnerDrawFixed
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 18
      ItemIndex = 0
      MaxLength = 100
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      Text = 'None'
      OnChange = cmbDriveChange
      OnDrawItem = cmbFirstDriveDrawItem
      OnKeyDown = AllKeyDown
      Items.Strings = (
        'None')
    end
    object cmbSecondDrive: TComboBox
      Left = 245
      Top = 170
      Width = 322
      Height = 24
      Style = csOwnerDrawFixed
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 18
      ItemIndex = 0
      MaxLength = 100
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 7
      Text = 'None'
      OnChange = cmbDriveChange
      OnDrawItem = cmbSecondDriveDrawItem
      OnKeyDown = AllKeyDown
      Items.Strings = (
        'None')
    end
    object cmbVMName: TComboBox
      Left = 245
      Top = 106
      Width = 322
      Height = 24
      Style = csOwnerDrawFixed
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 18
      ParentFont = False
      TabOrder = 5
      OnChange = cmbVMNameChange
      OnDropDown = cmbVMNameDropDown
      OnKeyDown = AllKeyDown
      Items.Strings = (
        'None'
        'Create new VM')
    end
    object cmbEnableCPUVirtualization: TComboBox
      Left = 245
      Top = 202
      Width = 322
      Height = 24
      Style = csOwnerDrawFixed
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 18
      ItemIndex = 0
      ParentFont = False
      TabOrder = 12
      Text = 'Unchanged'
      OnKeyDown = AllKeyDown
      Items.Strings = (
        'Unchanged'
        'On'
        'Off'
        'Switch')
    end
    object cmbAudio: TComboBox
      Left = 245
      Top = 202
      Width = 322
      Height = 24
      Style = csOwnerDrawFixed
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 18
      ItemIndex = 1
      ParentFont = False
      TabOrder = 13
      Text = 'Creative Sound Blaster 16'
      Visible = False
      OnKeyDown = AllKeyDown
      Items.Strings = (
        'None'
        'Creative Sound Blaster 16'
        'PC speaker'
        'Intel HD Audio'
        'Gravis Ultrasound GF1'
        'ENSONIQ AudioPCI ES1370'
        'CS4231A'
        'Yamaha YM3812 (OPL2)'
        'Intel 82801AA AC97 Audio')
    end
    object edtHDD: TEdit
      Left = 245
      Top = 108
      Width = 291
      Height = 24
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxLength = 1024
      ParentFont = False
      TabOrder = 9
      Visible = False
      OnKeyDown = AllKeyDown
    end
    object edtMemory: TSpinEdit
      Left = 245
      Top = 172
      Width = 322
      Height = 26
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxLength = 5
      MaxValue = 65535
      MinValue = 1
      ParentFont = False
      TabOrder = 11
      Value = 512
      Visible = False
      OnKeyDown = edtMemoryKeyDown
    end
    object cmbCDROM: TComboBox
      Left = 245
      Top = 138
      Width = 322
      Height = 24
      Style = csOwnerDrawFixed
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 18
      ItemIndex = 0
      MaxLength = 100
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 10
      Text = 'None'
      Visible = False
      OnChange = cmbCDROMChange
      OnDrawItem = cmbCDROMDrawItem
      OnKeyDown = AllKeyDown
      Items.Strings = (
        'None')
    end
    object pnlVirtualBox: TPanel
      Left = 245
      Top = 10
      Width = 161
      Height = 25
      Anchors = [akTop, akRight]
      BevelInner = bvLowered
      DoubleBuffered = False
      ParentDoubleBuffered = False
      TabOrder = 0
      TabStop = True
      OnEnter = pnlVirtualBoxEnter
      OnExit = pnlVirtualBoxExit
      object sbVirtualBox: TPngSpeedButton
        Left = 2
        Top = 2
        Width = 157
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
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 160
        ExplicitHeight = 25
      end
    end
    object pnlQEMU: TPanel
      Left = 405
      Top = 10
      Width = 161
      Height = 25
      Anchors = [akTop, akRight]
      BevelInner = bvLowered
      DoubleBuffered = False
      ParentDoubleBuffered = False
      TabOrder = 1
      TabStop = True
      OnEnter = pnlQEMUEnter
      OnExit = pnlQEMUExit
      object sbQEMU: TPngSpeedButton
        Left = 2
        Top = 2
        Width = 157
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
        ExplicitLeft = 5
        ExplicitTop = 5
      end
    end
    object cmbCache: TComboBox
      Left = 247
      Top = 76
      Width = 322
      Height = 24
      Style = csOwnerDrawFixed
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 18
      ItemIndex = 0
      MaxLength = 100
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 8
      Text = 'Off'
      OnKeyDown = AllKeyDown
      Items.Strings = (
        'Off'
        'On')
    end
  end
  object btnOK: TPngBitBtn
    Left = 141
    Top = 318
    Width = 101
    Height = 25
    Anchors = [akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    Spacing = 10
    TabOrder = 1
    OnClick = btnOKClick
    OnKeyDown = AllKeyDown
  end
  object btnCancel: TPngBitBtn
    Left = 369
    Top = 318
    Width = 101
    Height = 25
    Anchors = [akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    Spacing = 10
    TabOrder = 2
    OnKeyDown = AllKeyDown
  end
  object odSearchVM: TOpenDialog
    Filter = 'VirtualBox VM (*.vbox)|*.vbox|All files (*.*)|*.*'
    Title = 'Load'
    Left = 216
    Top = 96
  end
  object odSearchHDD: TOpenDialog
    Filter = 
      'QEMU disk images|*.img;*.qcow;*.qcow2;*.qed;*.qcow;*.cow;*.vdi;*' +
      '.vmdk;*.vpc|All files|*.*'
    Title = 'Load'
    Left = 216
    Top = 128
  end
  object odOpenISO: TOpenDialog
    Filter = 'ISO files|*.iso|All files|*.*'
    Title = 'Load'
    Left = 216
    Top = 168
  end
end
