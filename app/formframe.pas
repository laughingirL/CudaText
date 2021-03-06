(*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

Copyright (c) Alexey Torgashin
*)
unit FormFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Forms, Controls, Dialogs,
  ExtCtrls, Menus, StdCtrls, StrUtils, ComCtrls, Clipbrd,
  LCLIntf, LCLProc, LCLType, LazUTF8, LazFileUtils, FileUtil,
  LConvEncoding,
  GraphUtil,
  ATTabs,
  ATGroups,
  ATSynEdit,
  ATSynEdit_Finder,
  ATSynEdit_Keymap_Init,
  ATSynEdit_Adapters,
  ATSynEdit_Adapter_EControl,
  ATSynEdit_Adapter_LiteLexer,
  ATSynEdit_Carets,
  ATSynEdit_Gaps,
  ATSynEdit_Markers,
  ATSynEdit_CanvasProc,
  ATSynEdit_Commands,
  ATSynEdit_Bookmarks,
  ATStrings,
  ATStringProc,
  ATStringProc_HtmlColor,
  ATFileNotif,
  ATButtons,
  ATPanelSimple,
  ATBinHex,
  ATStreamSearch,
  ATImageBox,
  proc_globdata,
  proc_editor,
  proc_cmd,
  proc_colors,
  proc_files,
  proc_msg,
  proc_str,
  proc_py,
  proc_py_const,
  proc_miscutils,
  ec_SyntAnal,
  ec_proc_lexer,
  formlexerstylemap,
  at__jsonconf,
  math,
  LazUTF8Classes;

type
  TEditorFramePyEvent = function(AEd: TATSynEdit; AEvent: TAppPyEvent; const AParams: array of string): string of object;
  TEditorFrameStringEvent = procedure(Sender: TObject; const S: string) of object;

type
  TAppOpenMode = (
    cOpenModeNone,
    cOpenModeEditor,
    cOpenModeViewText,
    cOpenModeViewBinary,
    cOpenModeViewHex,
    cOpenModeViewUnicode
    );

type
  { TEditorFrame }

  TEditorFrame = class(TFrame)
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    Splitter: TSplitter;
    TimerChange: TTimer;
    procedure TimerChangeTimer(Sender: TObject);
  private
    { private declarations }
    Adapter1: TATAdapterEControl;
    Adapter2: TATAdapterEControl;
    FTabCaption: string;
    FTabCaptionUntitled: string;
    FTabCaptionFromApi: boolean;
    FTabImageIndex: integer;
    FTabId: integer;
    FFileName: string;
    FFileName2: string;
    FFileWasBig: boolean;
    FNotif: TATFileNotif;
    FTextCharsTyped: integer;
    FActivationTime: Int64;
    FCodetreeFilter: string;
    FCodetreeFilterHistory: TStringList;
    FEnabledCodeTree: array[0..1] of boolean;
    FOnChangeCaption: TNotifyEvent;
    FOnProgress: TATFinderProgress;
    FOnUpdateStatus: TNotifyEvent;
    FOnEditorClickMoveCaret: TATSynEditClickMoveCaretEvent;
    FOnEditorClickEndSelect: TATSynEditClickMoveCaretEvent;
    FOnFocusEditor: TNotifyEvent;
    FOnEditorCommand: TATSynEditCommandEvent;
    FOnEditorChangeCaretPos: TNotifyEvent;
    FOnSaveFile: TNotifyEvent;
    FOnAddRecent: TEditorFrameStringEvent;
    FOnPyEvent: TEditorFramePyEvent;
    FOnInitAdapter: TNotifyEvent;
    FSplitPos: double;
    FSplitHorz: boolean;
    FActiveSecondaryEd: boolean;
    FLocked: boolean;
    FTabColor: TColor;
    FTabSizeChanged: boolean;
    FFoldTodo: string;
    FTopLineTodo: integer;
    FTabKeyCollectMarkers: boolean;
    FNotInRecents: boolean;
    FMacroRecord: boolean;
    FMacroString: string;
    FImageBox: TATImageBox;
    FBin: TATBinHex;
    FBinStream: TFileStreamUTF8;
    FCheckFilenameOpened: TStrFunction;
    FOnMsgStatus: TStrEvent;
    FSaveDialog: TSaveDialog;
    FReadOnlyFromFile: boolean;
    FWasVisible: boolean;
    FInitialLexer: TecSyntAnalyzer;
    FSaveHistory: boolean;
    FEditorsLinked: boolean;
    FCachedTreeview: array[0..1] of TTreeView;

    procedure BinaryOnKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BinaryOnScroll(Sender: TObject);
    procedure BinaryOnProgress(const ACurrentPos, AMaximalPos: Int64;
      var AContinueSearching: Boolean);
    procedure DoDeactivatePictureMode;
    procedure DoDeactivateViewerMode;
    procedure DoFileOpen_AsBinary(const AFileName: string; AMode: TATBinHexMode);
    procedure DoFileOpen_AsPicture(const AFileName: string);
    procedure DoFileOpen_Ex(Ed: TATSynEdit; const AFileName: string;
      AAllowLoadHistory, AAllowErrorMsgBox: boolean; AOpenMode: TAppOpenMode);
    procedure DoImageboxScroll(Sender: TObject);
    procedure DoOnChangeCaption;
    procedure DoOnUpdateStatus;
    procedure EditorClickEndSelect(Sender: TObject; APrevPnt, ANewPnt: TPoint);
    procedure EditorClickMoveCaret(Sender: TObject; APrevPnt, ANewPnt: TPoint);
    procedure EditorDrawMicromap(Sender: TObject; C: TCanvas; const ARect: TRect);
    procedure EditorOnChange(Sender: TObject);
    procedure EditorOnChangeModified(Sender: TObject);
    procedure EditorOnChangeState(Sender: TObject);
    procedure EditorOnClick(Sender: TObject);
    procedure EditorOnClickGap(Sender: TObject; AGapItem: TATGapItem; APos: TPoint);
    procedure EditorOnClickGutter(Sender: TObject; ABand, ALine: integer);
    procedure EditorOnClickDouble(Sender: TObject; var AHandled: boolean);
    procedure EditorOnClickMicroMap(Sender: TObject; AX, AY: integer);
    procedure EditorOnClickMiddle(Sender: TObject; var AHandled: boolean);
    procedure EditorOnCommand(Sender: TObject; ACmd: integer; const AText: string; var AHandled: boolean);
    procedure EditorOnCommandAfter(Sender: TObject; ACommand: integer; const AText: string);
    procedure EditorOnDrawBookmarkIcon(Sender: TObject; C: TCanvas; ALineNum: integer; const ARect: TRect);
    procedure EditorOnEnter(Sender: TObject);
    procedure EditorOnDrawLine(Sender: TObject; C: TCanvas; AX, AY: integer;
      const AStr: atString; ACharSize: TPoint; const AExtent: TATIntArray);
    procedure EditorOnCalcBookmarkColor(Sender: TObject; ABookmarkKind: integer; var AColor: TColor);
    procedure EditorOnChangeCaretPos(Sender: TObject);
    procedure EditorOnHotspotEnter(Sender: TObject; AHotspotIndex: integer);
    procedure EditorOnHotspotExit(Sender: TObject; AHotspotIndex: integer);
    procedure EditorOnKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditorOnPaste(Sender: TObject; var AHandled: boolean; AKeepCaret,
      ASelectThen: boolean);
    procedure EditorOnScroll(Sender: TObject);
    function GetAdapter(Ed: TATSynEdit): TATAdapterEControl;
    function GetCachedTreeview(Ed: TATSynEdit): TTreeView;
    function GetCommentString(Ed: TATSynEdit): string;
    function GetEnabledCodeTree(Ed: TATSynEdit): boolean;
    function GetEnabledFolding: boolean;
    function GetLineEnds(Ed: TATSynEdit): TATLineEnds;
    function GetNotifEnabled: boolean;
    function GetNotifTime: integer;
    function GetPictureScale: integer;
    function GetReadOnly(Ed: TATSynEdit): boolean;
    function GetSplitPosCurrent: double;
    function GetSplitted: boolean;
    function GetTabKeyCollectMarkers: boolean;
    function GetUnprintedEnds: boolean;
    function GetUnprintedEndsDetails: boolean;
    function GetUnprintedShow: boolean;
    function GetUnprintedSpaces: boolean;
    procedure InitEditor(var ed: TATSynEdit);
    function IsCaretInsideCommentOrString(Ed: TATSynEdit; AX, AY: integer): boolean;
    procedure NotifChanged(Sender: TObject);
    procedure SetEnabledCodeTree(Ed: TATSynEdit; AValue: boolean);
    procedure SetEnabledFolding(AValue: boolean);
    procedure SetFileName(const AValue: string);
    procedure SetFileName2(AValue: string);
    procedure SetFileWasBig(AValue: boolean);
    procedure SetLocked(AValue: boolean);
    procedure SetNotifEnabled(AValue: boolean);
    procedure SetNotifTime(AValue: integer);
    procedure SetPictureScale(AValue: integer);
    procedure SetReadOnly(Ed: TATSynEdit; AValue: boolean);
    procedure SetTabColor(AColor: TColor);
    procedure SetTabImageIndex(AValue: integer);
    procedure SetUnprintedEnds(AValue: boolean);
    procedure SetUnprintedEndsDetails(AValue: boolean);
    procedure SetUnprintedShow(AValue: boolean);
    procedure SetSplitHorz(AValue: boolean);
    procedure SetSplitPos(AValue: double);
    procedure SetSplitted(AValue: boolean);
    procedure SetTabCaption(const AValue: string);
    procedure SetLineEnds(Ed: TATSynEdit; AValue: TATLineEnds);
    procedure SetUnprintedSpaces(AValue: boolean);
    procedure SetEditorsLinked(AValue: boolean);
    procedure SplitterMoved(Sender: TObject);
    procedure UpdateEds(AUpdateWrapInfo: boolean=false);
    procedure UpdateCaptionFromFilename;
    function GetLexer(Ed: TATSynEdit): TecSyntAnalyzer;
    function GetLexerLite(Ed: TATSynEdit): TATLiteLexer;
    function GetLexerName(Ed: TATSynEdit): string;
    procedure SetLexer(Ed: TATSynEdit; an: TecSyntAnalyzer);
    procedure SetLexerLite(Ed: TATSynEdit; an: TATLiteLexer);
    procedure SetLexerName(Ed: TATSynEdit; const AValue: string);
    procedure UpdateTabTooltip;
  protected
    procedure DoOnResize; override;
  public
    { public declarations }
    Ed1: TATSynEdit;
    Ed2: TATSynEdit;
    Groups: TATGroups;

    constructor Create(AOwner: TComponent; AApplyCentering: boolean); reintroduce;
    destructor Destroy; override;
    function Editor: TATSynEdit;
    function EditorBro: TATSynEdit;
    property Adapter[Ed: TATSynEdit]: TATAdapterEControl read GetAdapter;
    procedure EditorOnKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DoShow;
    property ReadOnly[Ed: TATSynEdit]: boolean read GetReadOnly write SetReadOnly;
    property ReadOnlyFromFile: boolean read FReadOnlyFromFile write FReadOnlyFromFile;
    property TabCaption: string read FTabCaption write SetTabCaption;
    property TabCaptionUntitled: string read FTabCaptionUntitled write FTabCaptionUntitled;
    property TabImageIndex: integer read FTabImageIndex write SetTabImageIndex;
    property TabCaptionFromApi: boolean read FTabCaptionFromApi write FTabCaptionFromApi;
    property TabId: integer read FTabId;
    property CachedTreeView[Ed: TATSynEdit]: TTreeView read GetCachedTreeview;
    property SaveHistory: boolean read FSaveHistory write FSaveHistory;
    procedure UpdateModified(Ed: TATSynEdit; AWithEvent: boolean= true);
    procedure UpdateReadOnlyFromFile(Ed: TATSynEdit);
    procedure UpdateFrame(AUpdatedText: boolean);
    property NotifEnabled: boolean read GetNotifEnabled write SetNotifEnabled;
    property NotifTime: integer read GetNotifTime write SetNotifTime;

    property FileName: string read FFileName write SetFileName;
    property FileWasBig: boolean read FFileWasBig write SetFileWasBig;
    function GetFileName(Ed: TATSynEdit): string;
    procedure SetFileName(Ed: TATSynEdit; const AFileName: string);

    property Lexer[Ed: TATSynEdit]: TecSyntAnalyzer read GetLexer write SetLexer;
    property LexerLite[Ed: TATSynEdit]: TATLiteLexer read GetLexerLite write SetLexerLite;
    property LexerName[Ed: TATSynEdit]: string read GetLexerName write SetLexerName;
    function LexerNameAtPos(Ed: TATSynEdit; APos: TPoint): string;

    property Locked: boolean read FLocked write SetLocked;
    property CommentString[Ed: TATSynEdit]: string read GetCommentString;
    property TabColor: TColor read FTabColor write SetTabColor;
    property TabSizeChanged: boolean read FTabSizeChanged write FTabSizeChanged;
    property TabKeyCollectMarkers: boolean read GetTabKeyCollectMarkers write FTabKeyCollectMarkers;
    property NotInRecents: boolean read FNotInRecents write FNotInRecents;
    property TopLineTodo: integer read FTopLineTodo write FTopLineTodo; //always use it instead of Ed.LineTop
    property TextCharsTyped: integer read FTextCharsTyped write FTextCharsTyped;
    property EnabledCodeTree[Ed: TATSynEdit]: boolean read GetEnabledCodeTree write SetEnabledCodeTree;
    property CodetreeFilter: string read FCodetreeFilter write FCodetreeFilter;
    property CodetreeFilterHistory: TStringList read FCodetreeFilterHistory;
    property ActivationTime: Int64 read FActivationTime write FActivationTime;
    function IsEmpty: boolean;
    function IsPreview: boolean;
    procedure ApplyTheme;
    procedure SetFocus; reintroduce;
    function IsText: boolean;
    function IsPicture: boolean;
    function IsBinary: boolean;
    function PictureSizes: TPoint;
    property PictureScale: integer read GetPictureScale write SetPictureScale;
    property Binary: TATBinHex read FBin;
    function BinaryFindFirst(AFinder: TATEditorFinder; AShowAll: boolean): boolean;
    function BinaryFindNext(ABack: boolean): boolean;
    //
    property LineEnds[Ed: TATSynEdit]: TATLineEnds read GetLineEnds write SetLineEnds;
    property UnprintedShow: boolean read GetUnprintedShow write SetUnprintedShow;
    property UnprintedSpaces: boolean read GetUnprintedSpaces write SetUnprintedSpaces;
    property UnprintedEnds: boolean read GetUnprintedEnds write SetUnprintedEnds;
    property UnprintedEndsDetails: boolean read GetUnprintedEndsDetails write SetUnprintedEndsDetails;
    property Splitted: boolean read GetSplitted write SetSplitted;
    property SplitHorz: boolean read FSplitHorz write SetSplitHorz;
    property SplitPos: double read FSplitPos write SetSplitPos;
    property EditorsLinked: boolean read FEditorsLinked write SetEditorsLinked;
    property EnabledFolding: boolean read GetEnabledFolding write SetEnabledFolding;
    property SaveDialog: TSaveDialog read FSaveDialog write FSaveDialog;
    //file
    procedure DoFileClose;
    procedure DoFileOpen(const AFileName, AFileName2: string; AAllowLoadHistory,
      AAllowErrorMsgBox: boolean; AOpenMode: TAppOpenMode);
    function DoFileSave(ASaveAs, AAllEditors: boolean): boolean;
    function DoFileSave_Ex(Ed: TATSynEdit; ASaveAs: boolean): boolean;
    procedure DoFileReload_DisableDetectEncoding;
    procedure DoFileReload;
    procedure DoLexerFromFilename(Ed: TATSynEdit; const AFileName: string);
    procedure DoSaveHistory(Ed: TATSynEdit);
    procedure DoSaveHistoryEx(Ed: TATSynEdit; c: TJsonConfig; const path: UnicodeString);
    procedure DoSaveUndo(Ed: TATSynEdit; const AFileName: string);
    procedure DoLoadHistory(Ed: TATSynEdit);
    procedure DoLoadHistoryEx(Ed: TATSynEdit; const AFileName: string; c: TJsonConfig; const path: UnicodeString);
    procedure DoLoadUndo(Ed: TATSynEdit);
    //misc
    function DoPyEvent(AEd: TATSynEdit; AEvent: TAppPyEvent; const AParams: array of string): string;
    procedure DoGotoPos(Ed: TATSynEdit; APosX, APosY: integer);
    procedure DoRestoreFolding;
    procedure DoRemovePreviewStyle;
    procedure DoToggleFocusSplitEditors;
    //macro
    procedure DoMacroStart;
    procedure DoMacroStop(ACancel: boolean);
    property MacroRecord: boolean read FMacroRecord;
    property MacroString: string read FMacroString write FMacroString;

    //events
    property OnProgress: TATFinderProgress read FOnProgress write FOnProgress;
    property OnCheckFilenameOpened: TStrFunction read FCheckFilenameOpened write FCheckFilenameOpened;
    property OnMsgStatus: TStrEvent read FOnMsgStatus write FOnMsgStatus;
    property OnFocusEditor: TNotifyEvent read FOnFocusEditor write FOnFocusEditor;
    property OnChangeCaption: TNotifyEvent read FOnChangeCaption write FOnChangeCaption;
    property OnUpdateStatus: TNotifyEvent read FOnUpdateStatus write FOnUpdateStatus;
    property OnEditorClickMoveCaret: TATSynEditClickMoveCaretEvent read FOnEditorClickMoveCaret write FOnEditorClickMoveCaret;
    property OnEditorClickEndSelect: TATSynEditClickMoveCaretEvent read FOnEditorClickEndSelect write FOnEditorClickEndSelect;
    property OnEditorCommand: TATSynEditCommandEvent read FOnEditorCommand write FOnEditorCommand;
    property OnEditorChangeCaretPos: TNotifyEvent read FOnEditorChangeCaretPos write FOnEditorChangeCaretPos;
    property OnSaveFile: TNotifyEvent read FOnSaveFile write FOnSaveFile;
    property OnAddRecent: TEditorFrameStringEvent read FOnAddRecent write FOnAddRecent;
    property OnPyEvent: TEditorFramePyEvent read FOnPyEvent write FOnPyEvent;
    property OnInitAdapter: TNotifyEvent read FOnInitAdapter write FOnInitAdapter;
  end;

procedure GetFrameLocation(Frame: TEditorFrame;
  out AGroups: TATGroups; out APages: TATPages;
  out ALocalGroupIndex, AGlobalGroupIndex, ATabIndex: integer);

var
  //must be set in FormMain.OnShow
  AllowFrameParsing: boolean = false;


implementation

{$R *.lfm}

const
  cHistory_Lexer       = '/lexer';
  cHistory_Enc         = '/enc';
  cHistory_Top         = '/top';
  cHistory_Wrap        = '/wrap_mode';
  cHistory_RO          = '/ro';
  cHistory_Ruler       = '/ruler';
  cHistory_Minimap     = '/minimap';
  cHistory_Micromap    = '/micromap';
  cHistory_TabSize     = '/tab_size';
  cHistory_TabSpace    = '/tab_spaces';
  cHistory_Nums        = '/nums';
  cHistory_Unpri        = '/unprinted_show';
  cHistory_Unpri_Spaces = '/unprinted_spaces';
  cHistory_Unpri_Ends   = '/unprinted_ends';
  cHistory_Unpri_Detail = '/unprinted_end_details';
  cHistory_Caret       = '/crt';
  cHistory_TabColor    = '/color';
  cHistory_Bookmark    = '/bm';
  cHistory_BookmarkKind = '/bm_kind';
  cHistory_Fold        = '/folded';
  cHistory_CodeTreeFilter = '/codetree_filter';
  cHistory_CodeTreeFilters = '/codetree_filters';

var
  FLastTabId: integer = 0;


procedure GetFrameLocation(Frame: TEditorFrame;
  out AGroups: TATGroups; out APages: TATPages;
  out ALocalGroupIndex, AGlobalGroupIndex, ATabIndex: integer);
var
  C: TWinControl;
begin
  APages:= Frame.Parent as TATPages;

  C:= APages;
  repeat
    C:= C.Parent;
  until C is TATGroups;

  AGroups:= C as TATGroups;
  AGroups.PagesAndTabIndexOfControl(Frame, ALocalGroupIndex, ATabIndex);

  AGlobalGroupIndex:= ALocalGroupIndex;
  if AGroups.Tag<>0 then
    Inc(AGlobalGroupIndex, High(TATGroupsNums) + AGroups.Tag);
end;


{ TEditorFrame }

procedure TEditorFrame.SetTabCaption(const AValue: string);
var
  Upd: boolean;
begin
  if AValue='?' then Exit;
  Upd:= FTabCaption<>AValue;

  FTabCaption:= AValue; //don't check Upd here (for Win32)

  if Upd then
    DoPyEvent(Editor, cEventOnState, [IntToStr(EDSTATE_TAB_TITLE)]);
  DoOnChangeCaption;
end;

procedure TEditorFrame.UpdateCaptionFromFilename;
var
  Name1, Name2: string;
begin
  if EditorsLinked then
  begin
    if FFileName='' then
      Name1:= FTabCaptionUntitled
    else
      Name1:= ExtractFileName_Fixed(FFileName);
    Name1:= msgModified[Ed1.Modified]+Name1;

    TabCaption:= Name1;
  end
  else
  begin
    if (FFileName='') and (FFileName2='') then
      TabCaption:= FTabCaptionUntitled
    else
    begin
      Name1:= ExtractFileName_Fixed(FFileName);
      if Name1='' then Name1:= msgUntitledTab;
      Name1:= msgModified[Ed1.Modified]+Name1;

      Name2:= ExtractFileName_Fixed(FFileName2);
      if Name2='' then Name2:= msgUntitledTab;
      Name2:= msgModified[Ed2.Modified]+Name2;

      TabCaption:= Name1+' | '+Name2;
    end;
  end;

  UpdateTabTooltip;
end;

procedure TEditorFrame.EditorOnClick(Sender: TObject);
var
  Ed: TATSynEdit;
  StateString: string;
begin
  Ed:= Sender as TATSynEdit;

  StateString:= ConvertShiftStateToString(KeyboardStateToShiftState);
  FTextCharsTyped:= 0; //reset count for option "autocomplete_autoshow_chars"

  if UiOps.MouseGotoDefinition<>'' then
    if StateString=UiOps.MouseGotoDefinition then
    begin
      DoPyEvent(Ed, cEventOnGotoDef, []);
      exit;
    end;

  DoPyEvent(Ed, cEventOnClick, ['"'+StateString+'"']);
end;

function TEditorFrame.GetSplitPosCurrent: double;
begin
  if not Splitted then
    Result:= 0
  else
  if FSplitHorz then
    Result:= Ed2.Height/Max(Height, 1)
  else
    Result:= Ed2.Width/Max(Width, 1);
end;

function TEditorFrame.GetSplitted: boolean;
begin
  Result:= Ed2.Visible;
end;

procedure TEditorFrame.EditorOnKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //res=False: block key
  if DoPyEvent(Sender as TATSynEdit,
    cEventOnKey,
    [
      IntToStr(Key),
      '"'+ConvertShiftStateToString(Shift)+'"'
    ]) = cPyFalse then
    begin
      Key:= 0;
      Exit
    end;
end;

procedure TEditorFrame.EditorOnPaste(Sender: TObject; var AHandled: boolean;
  AKeepCaret, ASelectThen: boolean);
const
  cBool: array[boolean] of string = (cPyFalse, cPyTrue);
begin
  if DoPyEvent(Sender as TATSynEdit,
    cEventOnPaste,
    [
      cBool[AKeepCaret],
      cBool[ASelectThen]
    ]) = cPyFalse then
    AHandled:= true;
end;

procedure TEditorFrame.EditorOnScroll(Sender: TObject);
begin
  DoPyEvent(Sender as TATSynEdit, cEventOnScroll, []);
end;

procedure TEditorFrame.EditorOnKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //keyup: only for Ctrl/Shift/Alt
  //no res.
  case Key of
    VK_CONTROL,
    VK_MENU,
    VK_SHIFT,
    VK_RSHIFT:
      DoPyEvent(Sender as TATSynEdit,
        cEventOnKeyUp,
        [
          IntToStr(Key),
          '"'+ConvertShiftStateToString(Shift)+'"'
        ]);
  end;
end;

procedure TEditorFrame.DoShow;
begin
  //analize file, when frame is shown for the 1st time
  if AllowFrameParsing and not FWasVisible then
  begin
    FWasVisible:= true;
    //ShowMessage('show frame: '+FileName); ////debug

    if Assigned(FInitialLexer) then
    begin
      Lexer[Ed1]:= FInitialLexer;
      FInitialLexer:= nil;
    end;
  end;
end;

procedure TEditorFrame.TimerChangeTimer(Sender: TObject);
begin
  TimerChange.Enabled:= false;
  DoPyEvent(Editor, cEventOnChangeSlow, []);
end;

procedure TEditorFrame.EditorOnCalcBookmarkColor(Sender: TObject;
  ABookmarkKind: integer; var AColor: TColor);
begin
  if ABookmarkKind>1 then
    AColor:= AppBookmarkSetup[ABookmarkKind].Color;
end;

procedure TEditorFrame.EditorOnChangeCaretPos(Sender: TObject);
const
  cMaxSelectedLinesForAutoCopy = 200;
var
  Ed: TATSynEdit;
  NFrom, NTo: integer;
begin
  if Assigned(FOnEditorChangeCaretPos) then
    FOnEditorChangeCaretPos(Sender);

  DoOnUpdateStatus;

  Ed:= Sender as TATSynEdit;

  //support Primary Selection on Linux
  {$ifdef linux}
  if Ed.Carets.Count=1 then
  begin
    Ed.Carets[0].GetSelLines(NFrom, NTo, false);
    if (NTo-NFrom)<=cMaxSelectedLinesForAutoCopy then
      SClipboardCopy(Ed.TextSelected, PrimarySelection);
  end;
  {$endif}

  DoPyEvent(Ed, cEventOnCaret, []);
end;

procedure TEditorFrame.EditorOnHotspotEnter(Sender: TObject; AHotspotIndex: integer);
begin
  DoPyEvent(Sender as TATSynEdit, cEventOnHotspot, [
    cPyTrue, //hotspot enter
    IntToStr(AHotspotIndex)
    ]);
end;

procedure TEditorFrame.EditorOnHotspotExit(Sender: TObject; AHotspotIndex: integer);
begin
  DoPyEvent(Sender as TATSynEdit, cEventOnHotspot, [
    cPyFalse, //hotspot exit
    IntToStr(AHotspotIndex)
    ]);
end;

procedure TEditorFrame.EditorOnDrawLine(Sender: TObject; C: TCanvas; AX,
  AY: integer; const AStr: atString; ACharSize: TPoint;
  const AExtent: TATIntArray);
const
  cRegexRGB = 'rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*(,\s*[\.\d]+\s*)?\)';
  cRegexHSL = 'hsla?\(\s*(\d{1,3})\s*,\s*(\d{1,3})%\s*,\s*(\d{1,3})%\s*(,\s*[\.\d%]+\s*)?\)';
var
  X1, X2, Y, NLen: integer;
  NColor: TColor;
  Parts: TRegexParts;
  Ch: atChar;
  ValueR, ValueG, ValueB: byte;
  ValueH, ValueS, ValueL: word;
  i: integer;
begin
  if AStr='' then Exit;
  if not IsFilenameListedInExtensionList(FileName, EditorOps.OpUnderlineColorFiles)
    then exit;

  for i:= 1 to Length(AStr)-3 do
  begin
    Ch:= AStr[i];

    //find #rgb, #rrggbb
    if Ch='#' then
    begin
      NColor:= SHtmlColorToColor(Copy(AStr, i+1, 7), NLen, clNone);
      if NColor=clNone then Continue;

      if i-2>=0 then
        X1:= AX+AExtent[i-2]
      else
        X1:= AX;
      X2:= AX+AExtent[i-1+NLen];
      Y:= AY+ACharSize.Y;

      C.Brush.Color:= NColor;
      C.FillRect(X1, Y-EditorOps.OpUnderlineColorSize, X2, Y);
    end
    else
    //find rgb(...), rgba(...)
    if (Ch='r') and
      (i+6<=Length(AStr)) and
      (AStr[i+1]='g') and
      (AStr[i+2]='b') and
      ((AStr[i+3]='(') or ((AStr[i+3]='a') and (AStr[i+4]='('))) and
      ((i=1) or not IsCharWord(AStr[i-1], '')) //word boundary
    then
    begin
      if SRegexFindParts(cRegexRGB, Copy(AStr, i, MaxInt), Parts) then
        if Parts[0].Pos=1 then //need at i-th char
        begin
          ValueR:= Min(255, StrToIntDef(Parts[1].Str, 0));
          ValueG:= Min(255, StrToIntDef(Parts[2].Str, 0));
          ValueB:= Min(255, StrToIntDef(Parts[3].Str, 0));

          NColor:= RGB(ValueR, ValueG, ValueB);
          NLen:= Parts[0].Len;

          if i-2>=0 then
            X1:= AX+AExtent[i-2]
          else
            X1:= AX;
          X2:= AX+AExtent[i-2+NLen];
          Y:= AY+ACharSize.Y;

          C.Brush.Color:= NColor;
          C.FillRect(X1, Y-EditorOps.OpUnderlineColorSize, X2, Y);
        end;
    end
    else
    //find hsl(...), hsla(...)
    if (Ch='h') and
      (i+6<=Length(AStr)) and
      (AStr[i+1]='s') and
      (AStr[i+2]='l') and
      ((AStr[i+3]='(') or ((AStr[i+3]='a') and (AStr[i+4]='('))) and
      ((i=1) or not IsCharWord(AStr[i-1], '')) //word boundary
      then
      begin
        if SRegexFindParts(cRegexHSL, Copy(AStr, i, MaxInt), Parts) then
          if Parts[0].Pos=1 then //need at i-th char
          begin
            ValueH:= StrToIntDef(Parts[1].Str, 0) * 255 div 360; //degrees -> 0..255
            ValueS:= StrToIntDef(Parts[2].Str, 0) * 255 div 100; //percents -> 0..255
            ValueL:= StrToIntDef(Parts[3].Str, 0) * 255 div 100; //percents -> 0..255

            NColor:= HLStoColor(ValueH, ValueL, ValueS);
            NLen:= Parts[0].Len;

            if i-2>=0 then
              X1:= AX+AExtent[i-2]
            else
              X1:= AX;
            X2:= AX+AExtent[i-2+NLen];
            Y:= AY+ACharSize.Y;

            C.Brush.Color:= NColor;
            C.FillRect(X1, Y-EditorOps.OpUnderlineColorSize, X2, Y);
          end;
      end;
  end;
end;


function TEditorFrame.GetLineEnds(Ed: TATSynEdit): TATLineEnds;
begin
  Result:= Ed.Strings.Endings;
end;

function TEditorFrame.GetNotifEnabled: boolean;
begin
  Result:= FNotif.Timer.Enabled;
end;

function TEditorFrame.GetNotifTime: integer;
begin
  Result:= FNotif.Timer.Interval;
end;

function TEditorFrame.GetPictureScale: integer;
begin
  if Assigned(FImageBox) then
    Result:= FImageBox.ImageZoom
  else
    Result:= 100;
end;

function TEditorFrame.GetReadOnly(Ed: TATSynEdit): boolean;
begin
  Result:= Ed.ModeReadOnly;
end;

function TEditorFrame.GetTabKeyCollectMarkers: boolean;
begin
  Result:= FTabKeyCollectMarkers and (Editor.Markers.Count>0);
end;

function TEditorFrame.GetUnprintedEnds: boolean;
begin
  Result:= Ed1.OptUnprintedEnds;
end;

function TEditorFrame.GetUnprintedEndsDetails: boolean;
begin
  Result:= Ed1.OptUnprintedEndsDetails;
end;

function TEditorFrame.GetUnprintedShow: boolean;
begin
  Result:= Ed1.OptUnprintedVisible;
end;

function TEditorFrame.GetUnprintedSpaces: boolean;
begin
  Result:= Ed1.OptUnprintedSpaces;
end;

procedure TEditorFrame.SetFileName(const AValue: string);
begin
  if SameFileName(FFileName, AValue) then Exit;
  FFileName:= AValue;

  //update Notif obj
  NotifEnabled:= NotifEnabled;
end;

procedure TEditorFrame.UpdateTabTooltip;
var
  Gr: TATGroups;
  Pages: TATPages;
  NLocalGroups, NGlobalGroup, NTab: integer;
  D: TATTabData;
  SHint: string;
begin
  GetFrameLocation(Self, Gr, Pages, NLocalGroups, NGlobalGroup, NTab);
  D:= Pages.Tabs.GetTabData(NTab);
  if Assigned(D) then
  begin
    SHint:= '';
    if EditorsLinked then
    begin
      if FFileName<>'' then
        SHint:= SCollapseHomeDirInFilename(FFileName);
    end
    else
    begin
      if (FFileName<>'') or (FFileName2<>'') then
        SHint:= SCollapseHomeDirInFilename(FFileName) + #10 +
                SCollapseHomeDirInFilename(FFileName2);
    end;

    D.TabHint:= SHint;
    Pages.Tabs.Invalidate;
  end;
end;

procedure TEditorFrame.SetFileName2(AValue: string);
begin
  if SameFileName(FFileName2, AValue) then Exit;
  FFileName2:= AValue;
end;

procedure TEditorFrame.SetFileWasBig(AValue: boolean);
begin
  FFileWasBig:= AValue;
  if AValue then
  begin
    Ed1.OptWrapMode:= cWrapOff;
    Ed2.OptWrapMode:= cWrapOff;
    Ed1.OptMicromapVisible:= false;
    Ed2.OptMicromapVisible:= false;
    Ed1.OptMinimapVisible:= false;
    Ed2.OptMinimapVisible:= false;
  end;
end;

procedure TEditorFrame.SetLocked(AValue: boolean);
begin
  if AValue=FLocked then exit;
  FLocked:= AValue;

  if FLocked then
  begin
    Ed1.BeginUpdate;
    Ed2.BeginUpdate;
  end
  else
  begin
    Ed1.EndUpdate;
    Ed2.EndUpdate;
  end;
end;

procedure TEditorFrame.SetNotifEnabled(AValue: boolean);
begin
  FNotif.Timer.Enabled:= false;
  FNotif.FileName:= '';

  if AValue and IsText and FileExistsUTF8(FileName) then
  begin
    FNotif.FileName:= FileName;
    FNotif.Timer.Enabled:= true;
  end;
end;

procedure TEditorFrame.SetNotifTime(AValue: integer);
begin
  FNotif.Timer.Interval:= AValue;
end;

procedure TEditorFrame.SetPictureScale(AValue: integer);
begin
  if Assigned(FImageBox) then
  begin
    if AValue>0 then
      FImageBox.ImageZoom:= AValue
    else
    if AValue=-1 then
      FImageBox.OptFitToWindow:= true;
  end;
end;

procedure TEditorFrame.SetReadOnly(Ed: TATSynEdit; AValue: boolean);
begin
  Ed.ModeReadOnly:= AValue;
  if (Ed=Ed1) and EditorsLinked then
    Ed2.ModeReadOnly:= AValue;
end;

procedure TEditorFrame.UpdateEds(AUpdateWrapInfo: boolean = false);
begin
  Ed2.OptUnprintedVisible:= Ed1.OptUnprintedVisible;
  Ed2.OptUnprintedSpaces:= Ed1.OptUnprintedSpaces;
  Ed2.OptUnprintedEnds:= Ed1.OptUnprintedEnds;
  Ed2.OptUnprintedEndsDetails:= Ed1.OptUnprintedEndsDetails;

  Ed1.Update(AUpdateWrapInfo);
  Ed2.Update(AUpdateWrapInfo);
end;

function TEditorFrame.GetLexer(Ed: TATSynEdit): TecSyntAnalyzer;
begin
  if Assigned(FInitialLexer) then
    Result:= FInitialLexer
  else
  if Ed.AdapterForHilite is TATAdapterEControl then
    Result:= TATAdapterEControl(Ed.AdapterForHilite).Lexer
  else
    Result:= nil;
end;

function TEditorFrame.GetLexerLite(Ed: TATSynEdit): TATLiteLexer;
begin
  if Ed.AdapterForHilite is TATLiteLexer then
    Result:= TATLiteLexer(Ed.AdapterForHilite)
  else
    Result:= nil;
end;

function TEditorFrame.GetLexerName(Ed: TATSynEdit): string;
var
  CurAdapter: TATAdapterHilite;
  an: TecSyntAnalyzer;
begin
  Result:= '';

  if Assigned(FInitialLexer) then
    exit(FInitialLexer.LexerName);

  CurAdapter:= Ed.AdapterForHilite;
  if CurAdapter=nil then exit;

  if CurAdapter is TATAdapterEControl then
  begin
    an:= TATAdapterEControl(CurAdapter).Lexer;
    if Assigned(an) then
      Result:= an.LexerName;
  end
  else
  if CurAdapter is TATLiteLexer then
  begin
    Result:= TATLiteLexer(CurAdapter).LexerName+msgLiteLexerSuffix;
  end;
end;


procedure TEditorFrame.SetLexerName(Ed: TATSynEdit; const AValue: string);
var
  SName: string;
  anLite: TATLiteLexer;
begin
  if AValue='' then
  begin
    if EditorsLinked then
    begin
      Adapter1.Lexer:= nil;
      Ed1.AdapterForHilite:= nil;
      Ed2.AdapterForHilite:= nil;
      UpdateEds;
    end
    else
    begin
      Lexer[Ed]:= nil;
      Ed.AdapterForHilite:= nil;
      Ed.Update;
    end;
    exit;
  end;

  if SEndsWith(AValue, msgLiteLexerSuffix) then
  begin
    SName:= Copy(AValue, 1, Length(AValue)-Length(msgLiteLexerSuffix));
    anLite:= AppManagerLite.FindLexerByName(SName);
    if Assigned(anLite) then
      LexerLite[Ed]:= anLite
    else
      Lexer[Ed]:= nil;
  end
  else
  begin
    Lexer[Ed]:= AppManager.FindLexerByName(AValue);
  end;
end;


function TEditorFrame.LexerNameAtPos(Ed: TATSynEdit; APos: TPoint): string;
var
  CurAdapter: TATAdapterHilite;
  an: TecSyntAnalyzer;
begin
  Result:= '';
  CurAdapter:= Ed.AdapterForHilite;
  if CurAdapter=nil then exit;

  if CurAdapter is TATAdapterEControl then
  begin
    an:= TATAdapterEControl(CurAdapter).LexerAtPos(APos);
    if Assigned(an) then
      Result:= an.LexerName;
  end
  else
  if CurAdapter is TATLiteLexer then
    Result:= TATLiteLexer(CurAdapter).LexerName+msgLiteLexerSuffix;
end;

procedure TEditorFrame.SetSplitHorz(AValue: boolean);
var
  al: TAlign;
begin
  FSplitHorz:= AValue;
  if not IsText then exit;

  if FSplitHorz then
    al:= alBottom
  else
    al:= alRight;
  Splitter.Align:= al;
  Ed2.Align:= al;

  //restore relative splitter ratio (e.g. 50%)
  SplitPos:= SplitPos;
end;

procedure TEditorFrame.SetSplitPos(AValue: double);
const
  Delta = 70;
var
  N: integer;
begin
  if not IsText then exit;
  if not Splitted then exit;

  AValue:= Max(0.0, Min(1.0, AValue));
  FSplitPos:= AValue;

  if FSplitHorz then
  begin
    N:= Round(AValue*Height);
    Ed2.Height:= Max(Delta, Min(Height-Delta, N));
    Splitter.Top:= 0;
  end
  else
  begin
    N:= Round(AValue*Width);
    Ed2.Width:= Max(Delta, Min(Width-Delta, N));
    Splitter.Left:= 0;
  end;
end;

procedure TEditorFrame.SetSplitted(AValue: boolean);
begin
  if not IsText then exit;
  if GetSplitted=AValue then exit;

  if not AValue and Ed2.Focused then
    if Ed1.CanFocus then
      Ed1.SetFocus;

  Ed2.Visible:= AValue;
  Splitter.Visible:= AValue;

  if AValue then
  begin
    SplitPos:= 0.5;
    //enable linking
    if FEditorsLinked then
      Ed2.Strings:= Ed1.Strings;
  end
  else
  begin
    //disable linking
    Ed2.Strings:= nil;
  end;

  Ed2.Update(true);
end;

procedure TEditorFrame.EditorOnChange(Sender: TObject);
var
  Ed: TATSynEdit;
begin
  Ed:= Sender as TATSynEdit;

  if (Ed=Ed1) and Splitted and EditorsLinked then
  begin
    Ed2.UpdateIncorrectCaretPositions;
    Ed2.Update(true);
  end;

  DoPyEvent(Ed, cEventOnChange, []);

  TimerChange.Enabled:= false;
  TimerChange.Interval:= UiOps.PyChangeSlow;
  TimerChange.Enabled:= true;
end;

procedure TEditorFrame.EditorOnChangeModified(Sender: TObject);
begin
  UpdateModified(Sender as TATSynEdit);
end;

procedure TEditorFrame.EditorOnChangeState(Sender: TObject);
begin
  //
end;

procedure TEditorFrame.UpdateModified(Ed: TATSynEdit; AWithEvent: boolean);
begin
  //when modified, remove "Preview tab" style (italic caption)
  if (Ed=Ed1) and Ed.Modified then
    DoRemovePreviewStyle;

  UpdateCaptionFromFilename;
  DoOnChangeCaption;

  if AWithEvent then
    DoPyEvent(Ed, cEventOnState, [IntToStr(EDSTATE_MODIFIED)]);

  DoOnUpdateStatus;
end;

procedure TEditorFrame.EditorOnEnter(Sender: TObject);
var
  IsEd2: boolean;
begin
  IsEd2:= Sender=Ed2;
  if IsEd2<>FActiveSecondaryEd then
  begin
    FActiveSecondaryEd:= IsEd2;
    DoOnUpdateStatus;
  end;

  if Assigned(FOnFocusEditor) then
    FOnFocusEditor(Sender);

  DoPyEvent(Sender as TATSynEdit, cEventOnFocus, []);

  FActivationTime:= GetTickCount64;
end;

procedure TEditorFrame.EditorOnCommand(Sender: TObject; ACmd: integer;
  const AText: string; var AHandled: boolean);
var
  Ed: TATSynEdit;
  Caret: TATCaretItem;
  Str: atString;
  ch: char;
begin
  Ed:= Sender as TATSynEdit;
  if Ed.Carets.Count=0 then exit;
  Caret:= Ed.Carets[0];

  case ACmd of
    cCommand_TextInsert:
      begin
        //improve auto-closing brackets, avoid duplicate ')' after '('
        if Ed.Strings.IsIndexValid(Caret.PosY) then
          if Length(AText)=1 then
          begin
            ch:= EditorGetPairForCloseBracket(AText[1]);
            if (ch<>#0) and (Pos(ch, UiOps.AutoCloseBrackets)>0) then
            begin
              Str:= Ed.Strings.Lines[Caret.PosY];
              if (Caret.PosX>0) and (Caret.PosX<Length(Str)) then
                if Copy(Str, Caret.PosX, 2) = ch+AText then
                begin
                  Ed.DoCommand(cCommand_KeyRight);
                  AHandled:= true;
                  exit;
                end;
            end;
          end;
      end;

    cCommand_KeyTab,
    cCommand_KeyEnter,
    cCommand_TextDeleteLine,
    cCommand_TextDeleteToLineBegin,
    cCommand_KeyUp,
    cCommand_KeyUp_Sel,
    cCommand_KeyDown,
    cCommand_KeyDown_Sel,
    cCommand_KeyLeft,
    cCommand_KeyLeft_Sel,
    cCommand_KeyRight,
    cCommand_KeyRight_Sel,
    cCommand_KeyHome,
    cCommand_KeyHome_Sel,
    cCommand_KeyEnd,
    cCommand_KeyEnd_Sel,
    cCommand_TextDeleteWordNext,
    cCommand_TextDeleteWordPrev:
      begin
        FTextCharsTyped:= 0;
      end;

    cCommand_ClipboardPaste,
    cCommand_ClipboardPaste_Select,
    cCommand_ClipboardPaste_KeepCaret,
    cCommand_ClipboardPaste_Column,
    cCommand_ClipboardPaste_ColumnKeepCaret:
      begin
        Adapter[Ed].StopTreeUpdate;
        Adapter[Ed].Stop;
      end;
  end;

  if Assigned(FOnEditorCommand) then
    FOnEditorCommand(Sender, ACmd, AText, AHandled);
end;

procedure TEditorFrame.EditorOnCommandAfter(Sender: TObject; ACommand: integer;
  const AText: string);
var
  Ed: TATSynEdit;
  Caret: TATCaretItem;
  SLexerName: string;
  bWordChar, bIdentChar: boolean;
begin
  Ed:= Sender as TATSynEdit;
  if Ed.Carets.Count<>1 then exit;
  Caret:= Ed.Carets[0];
  if not Ed.Strings.IsIndexValid(Caret.PosY) then exit;

  //some commands affect FTextCharsTyped
  if (ACommand=cCommand_KeyBackspace) then
  begin
    if FTextCharsTyped>0 then
      Dec(FTextCharsTyped);
    exit;
  end;

  //autoshow autocompletion
  if (ACommand=cCommand_TextInsert) and
    (Length(AText)=1) then
  begin
    //autoshow by trigger chars
    if (UiOps.AutocompleteTriggerChars<>'') and
      (Pos(AText[1], UiOps.AutocompleteTriggerChars)>0) then
    begin
      //check that we are not inside comment/string
      if IsCaretInsideCommentOrString(Ed, Caret.PosX, Caret.PosY) then exit;

      FTextCharsTyped:= 0;
      Ed.DoCommand(cmd_AutoComplete);
      exit;
    end;

    //other conditions need word-char
    bWordChar:= IsCharWordInIdentifier(AText[1]);
    if not bWordChar then
    begin
      FTextCharsTyped:= 0;
      exit;
    end;

    SLexerName:= LexerNameAtPos(Ed, Point(Caret.PosX, Caret.PosY));

    //autoshow for HTML
    if UiOps.AutocompleteHtml and (Pos('HTML', SLexerName)>0) then
    begin
      if Ed.Strings.LineSub(Caret.PosY, Caret.PosX-1, 1)='<' then
        Ed.DoCommand(cmd_AutoComplete);
      exit;
    end;

    (*
    //autoshow for CSS
    //seems bad, so commented, CSS must work like other lexers with AutoshowCharCount
    if UiOps.AutocompleteCss and (SLexerName='CSS') then
    begin
      if EditorIsAutocompleteCssPosition(Ed, Caret.PosX-1, Caret.PosY) then
        Ed.DoCommand(cmd_AutoComplete);
      exit;
    end;
    *)

    //autoshow for others, when typed N chars
    if (UiOps.AutocompleteAutoshowCharCount>0) then
    begin
      //ignore if number typed
      bIdentChar:= bWordChar and not IsCharDigit(AText[1]);
      if (FTextCharsTyped=0) and (not bIdentChar) then exit;

      //check that we are not inside comment/string
      if IsCaretInsideCommentOrString(Ed, Caret.PosX, Caret.PosY) then exit;

      Inc(FTextCharsTyped);
      if FTextCharsTyped=UiOps.AutocompleteAutoshowCharCount then
      begin
        FTextCharsTyped:= 0;
        Ed.DoCommand(cmd_AutoComplete);
        exit;
      end;
    end
    else
      FTextCharsTyped:= 0;
  end;

  if Ed.LastCommandChangedLines>0 then
    if Assigned(FOnMsgStatus) then
      FOnMsgStatus(Self, Format(msgStatusChangedLinesCount, [Ed.LastCommandChangedLines]));
end;

procedure TEditorFrame.EditorOnClickDouble(Sender: TObject; var AHandled: boolean);
var
  Str: string;
begin
  Str:= DoPyEvent(Sender as TATSynEdit, cEventOnClickDbl,
          ['"'+ConvertShiftStateToString(KeyboardStateToShiftState)+'"']);
  AHandled:= Str=cPyFalse;
end;

procedure TEditorFrame.EditorOnClickMicroMap(Sender: TObject; AX, AY: integer);
var
  Ed: TATSynEdit;
begin
  Ed:= Sender as TATSynEdit;

  AY:= AY * Ed.Strings.Count div Ed.ClientHeight;

  Ed.DoGotoPos(
    Point(0, AY),
    Point(-1, -1),
    UiOps.FindIndentHorz,
    UiOps.FindIndentVert,
    true,
    true
    );
end;

procedure TEditorFrame.EditorOnClickMiddle(Sender: TObject; var AHandled: boolean);
begin
  AHandled:= false;
  if EditorOps.OpMouseMiddleClickPaste then
  begin
    AHandled:= true;
    (Sender as TATSynEdit).DoCommand(cmd_MouseClickAtCursor);
    (Sender as TATSynEdit).DoCommand(cCommand_ClipboardAltPaste); //uses PrimarySelection:TClipboard
    exit;
  end;
end;

procedure TEditorFrame.EditorOnClickGap(Sender: TObject;
  AGapItem: TATGapItem; APos: TPoint);
var
  Ed: TATSynEdit;
  W, H: integer;
begin
  if not Assigned(AGapItem) then exit;
  Ed:= Sender as TATSynEdit;

  if Assigned(AGapItem.Bitmap) then
  begin
    W:= AGapItem.Bitmap.Width;
    H:= AGapItem.Bitmap.Height;
  end
  else
  begin
    W:= 0;
    H:= 0;
  end;

  DoPyEvent(Ed, cEventOnClickGap, [
    '"'+ConvertShiftStateToString(KeyboardStateToShiftState)+'"',
    IntToStr(AGapItem.LineIndex),
    IntToStr(AGapItem.Tag),
    IntToStr(W),
    IntToStr(H),
    IntToStr(APos.X),
    IntToStr(APos.Y)
    ]);
end;


procedure TEditorFrame.DoOnResize;
begin
  inherited;

  //this keeps ratio of splitter (e.g. 50%) on form resize
  SplitPos:= SplitPos;
end;

procedure TEditorFrame.InitEditor(var ed: TATSynEdit);
begin
  ed:= TATSynEdit.Create(Self);
  ed.Parent:= Self;

  ed.DoubleBuffered:= UiOps.DoubleBuffered;
  ed.AutoAdjustLayout(lapDefault, 100, UiOps.ScreenScale, 1, 1);

  ed.Font.Name:= EditorOps.OpFontName;
  ed.FontItalic.Name:= EditorOps.OpFontName_i;
  ed.FontBold.Name:= EditorOps.OpFontName_b;
  ed.FontBoldItalic.Name:= EditorOps.OpFontName_bi;

  ed.Font.Size:= EditorOps.OpFontSize;
  ed.FontItalic.Size:= EditorOps.OpFontSize_i;
  ed.FontBold.Size:= EditorOps.OpFontSize_b;
  ed.FontBoldItalic.Size:= EditorOps.OpFontSize_bi;

  ed.Font.Quality:= EditorOps.OpFontQuality;

  ed.BorderStyle:= bsNone;
  ed.Keymap:= AppKeymap;
  ed.TabStop:= false;
  ed.OptUnprintedVisible:= EditorOps.OpUnprintedShow;
  ed.OptRulerVisible:= EditorOps.OpRulerShow;
  ed.OptScrollbarsNew:= true;

  ed.OnClick:= @EditorOnClick;
  ed.OnClickDouble:= @EditorOnClickDouble;
  ed.OnClickMiddle:= @EditorOnClickMiddle;
  ed.OnClickMoveCaret:= @EditorClickMoveCaret;
  ed.OnClickEndSelect:= @EditorClickEndSelect;
  ed.OnClickGap:= @EditorOnClickGap;
  ed.OnClickMicromap:= @EditorOnClickMicroMap;
  ed.OnEnter:= @EditorOnEnter;
  ed.OnChange:= @EditorOnChange;
  ed.OnChangeModified:= @EditorOnChangeModified;
  ed.OnChangeState:= @EditorOnChangeState;
  ed.OnChangeCaretPos:= @EditorOnChangeCaretPos;
  ed.OnCommand:= @EditorOnCommand;
  ed.OnCommandAfter:= @EditorOnCommandAfter;
  ed.OnClickGutter:= @EditorOnClickGutter;
  ed.OnCalcBookmarkColor:= @EditorOnCalcBookmarkColor;
  ed.OnDrawBookmarkIcon:= @EditorOnDrawBookmarkIcon;
  ed.OnDrawLine:= @EditorOnDrawLine;
  ed.OnKeyDown:= @EditorOnKeyDown;
  ed.OnKeyUp:= @EditorOnKeyUp;
  ed.OnDrawMicromap:= @EditorDrawMicromap;
  ed.OnPaste:=@EditorOnPaste;
  ed.OnScroll:=@EditorOnScroll;
  ed.OnHotspotEnter:=@EditorOnHotspotEnter;
  ed.OnHotspotExit:=@EditorOnHotspotExit;
end;

constructor TEditorFrame.Create(AOwner: TComponent; AApplyCentering: boolean);
begin
  inherited Create(AOwner);

  FFileName:= '';
  FFileName2:= '';
  FActiveSecondaryEd:= false;
  FTabColor:= clNone;
  Inc(FLastTabId);
  FTabId:= FLastTabId;
  FTabImageIndex:= -1;
  FNotInRecents:= false;
  FEnabledCodeTree[0]:= true;
  FEnabledCodeTree[1]:= true;
  FSaveHistory:= true;
  FEditorsLinked:= true;
  FCodetreeFilterHistory:= TStringList.Create;
  FCachedTreeview[0]:= TTreeView.Create(Self);
  FCachedTreeview[1]:= nil;

  InitEditor(Ed1);
  InitEditor(Ed2);

  Ed1.Strings.GutterDecor1:= Ed1.GutterDecor;
  Ed1.Strings.GutterDecor2:= Ed2.GutterDecor;

  Ed2.Visible:= false;
  Splitter.Visible:= false;
  Ed1.Align:= alClient;
  Ed2.Align:= alBottom;

  Ed1.EditorIndex:= 0;
  Ed2.EditorIndex:= 1;

  Splitter.OnMoved:= @SplitterMoved;

  FSplitHorz:= true;
  Splitted:= false;

  Adapter1:= TATAdapterEControl.Create(Self);
  Adapter1.AddEditor(Ed1);
  Adapter1.AddEditor(Ed2);

  //load options
  EditorApplyOps(Ed1, EditorOps, true, true, AApplyCentering);
  EditorApplyOps(Ed2, EditorOps, true, true, AApplyCentering);
  EditorApplyTheme(Ed1);
  EditorApplyTheme(Ed2);

  //newdoc props
  case UiOps.NewdocEnds of
    0: Ed1.Strings.Endings:= {$ifdef windows} cEndWin {$else} cEndUnix {$endif};
    1: Ed1.Strings.Endings:= cEndUnix;
    2: Ed1.Strings.Endings:= cEndWin;
    3: Ed1.Strings.Endings:= cEndMac;
  end;
  Ed2.Strings.Endings:= Ed1.Strings.Endings;

  Ed1.Strings.DoClearUndo;
  Ed1.Strings.EncodingDetectDefaultUtf8:= UiOps.DefaultEncUtf8;

  Ed1.EncodingName:= AppEncodingShortnameToFullname(UiOps.NewdocEnc);

  Ed1.Modified:= false;
  Ed2.Modified:= false;

  //passing lite lexer - crashes (can't solve), so disabled
  if not SEndsWith(UiOps.NewdocLexer, msgLiteLexerSuffix) then
    LexerName[Ed1]:= UiOps.NewdocLexer;

  FNotif:= TATFileNotif.Create(Self);
  FNotif.Timer.Interval:= 1000;
  FNotif.Timer.Enabled:= false;
  FNotif.OnChanged:= @NotifChanged;
end;

destructor TEditorFrame.Destroy;
begin
  if Assigned(FBin) then
  begin
    FBin.OpenStream(nil);
    FreeAndNil(FBinStream);
    FreeAndNil(FBin);
  end;

  Ed1.AdapterForHilite:= nil;
  Ed2.AdapterForHilite:= nil;

  Ed1.Strings.GutterDecor1:= nil;
  Ed1.Strings.GutterDecor2:= nil;
  if not FEditorsLinked then
  begin
    Ed2.Strings.GutterDecor1:= nil;
    Ed2.Strings.GutterDecor2:= nil;
  end;

  if not Application.Terminated then //prevent crash on exit
    DoPyEvent(Ed1, cEventOnClose, []);

  FreeAndNil(FCodetreeFilterHistory);

  inherited;
end;

function TEditorFrame.Editor: TATSynEdit;
begin
  if FActiveSecondaryEd then
    Result:= Ed2
  else
    Result:= Ed1;
end;

function TEditorFrame.EditorBro: TATSynEdit;
begin
  if not FActiveSecondaryEd then
    Result:= Ed2
  else
    Result:= Ed1;
end;

function TEditorFrame.GetAdapter(Ed: TATSynEdit): TATAdapterEControl;
begin
  if (Ed=Ed1) or EditorsLinked then
    Result:= Adapter1
  else
    Result:= Adapter2;
end;

function TEditorFrame.GetCachedTreeview(Ed: TATSynEdit): TTreeView;
begin
  if (Ed=Ed1) or EditorsLinked then
    Result:= FCachedTreeview[0]
  else
  begin
    if FCachedTreeview[1]=nil then
      FCachedTreeview[1]:= TTreeView.Create(Self);
    Result:= FCachedTreeview[1];
  end;
end;

function TEditorFrame.IsEmpty: boolean;
var
  Str: TATStrings;
begin
  //dont check Modified here better
  Str:= Ed1.Strings;
  Result:=
    (FileName='') and
    ((Str.Count=0) or ((Str.Count=1) and (Str.Lines[0]='')));
end;

procedure TEditorFrame.ApplyTheme;
begin
  EditorApplyTheme(Ed1);
  EditorApplyTheme(Ed2);
  Ed1.Update;
  Ed2.Update;

  if Assigned(FBin) then
  begin
    ViewerApplyTheme(FBin);
    FBin.Redraw();
  end;
end;

function TEditorFrame.IsText: boolean;
begin
  Result:=
    not IsPicture and
    not IsBinary;
end;

function TEditorFrame.IsPicture: boolean;
begin
  Result:= Assigned(FImageBox);
end;

function TEditorFrame.IsBinary: boolean;
begin
  Result:= Assigned(FBin);
end;


procedure TEditorFrame.SetLexer(Ed: TATSynEdit; an: TecSyntAnalyzer);
var
  an2: TecSyntAnalyzer;
  ada: TATAdapterEControl;
begin
  ada:= Adapter[Ed];
  if Assigned(ada.Lexer) then
    if not ada.Stop then exit;

  if IsFileTooBigForLexer(GetFileName(Ed)) then
  begin
    if EditorsLinked or (Ed=Ed1) then
      Adapter1.Lexer:= nil
    else
    if Assigned(Adapter2) then
      Adapter2.Lexer:= nil;
    exit;
  end;

  if AllowFrameParsing then
  begin
    if Assigned(an) then
    begin
      if EditorsLinked then
      begin
        Ed1.AdapterForHilite:= Adapter1;
        Ed2.AdapterForHilite:= Adapter1;
      end
      else
      begin
        if Ed=Ed1 then
          Ed1.AdapterForHilite:= Adapter1
        else
        begin
          if Adapter2=nil then
          begin
            Adapter2:= TATAdapterEControl.Create(Self);
            OnInitAdapter(Adapter2);
          end;
          Ed2.AdapterForHilite:= Adapter2;
        end;
      end;

      if not DoApplyLexerStylesMap(an, an2) then
        DoDialogLexerStylesMap(an2);
    end
    else
    begin
      Ed.Fold.Clear;
      Ed.Update;
      if (Ed=Ed1) and EditorsLinked then
      begin
        Ed2.Fold.Clear;
        Ed2.Update;
      end;
    end;

    if Ed.AdapterForHilite is TATAdapterEControl then
    begin
      TATAdapterEControl(Ed.AdapterForHilite).Lexer:= an;
      //if Assigned(an) then
      //  ShowMessage('lexer '+an.LexerName);
    end;
  end
  else
  begin
    FInitialLexer:= an;
    //support on_lexer
    DoPyEvent(Ed, cEventOnLexer, []);
  end;
end;

procedure TEditorFrame.SetLexerLite(Ed: TATSynEdit; an: TATLiteLexer);
begin
  Lexer[Ed]:= nil;

  Ed.AdapterForHilite:= an;
  Ed.Update;

  if (Ed=Ed1) and EditorsLinked then
  begin
    Ed2.AdapterForHilite:= an;
    Ed2.Update;
  end;

  //support event on_lexer
  //we could do DoPyEvent(Ed1, cEventOnLexer, []);
  //but OnLexerChange() does also task to load lexer-specific config
  Adapter[Ed].OnLexerChange(Adapter[Ed]);
end;

procedure TEditorFrame.DoFileOpen_AsBinary(const AFileName: string; AMode: TATBinHexMode);
begin
  FFileName:= AFileName;
  UpdateCaptionFromFilename;

  Ed1.Hide;
  Ed2.Hide;
  Splitter.Hide;
  ReadOnly[Ed1]:= true;

  if Assigned(FBin) then
    FBin.OpenStream(nil);
  if Assigned(FBinStream) then
    FreeAndNil(FBinStream);
  FBinStream:= TFileStreamUTF8.Create(AFileName, fmOpenRead or fmShareDenyWrite);

  if not Assigned(FBin) then
  begin
    FBin:= TATBinHex.Create(Self);
    FBin.OnKeyDown:= @BinaryOnKeyDown;
    FBin.OnScroll:= @BinaryOnScroll;
    FBin.OnOptionsChange:= @BinaryOnScroll;
    FBin.OnSearchProgress:= @BinaryOnProgress;
    FBin.Parent:= Self;
    FBin.Align:= alClient;
    FBin.BorderStyle:= bsNone;
    FBin.TextGutter:= true;
    FBin.TextWidth:= UiOps.ViewerBinaryWidth;
    FBin.TextPopupCommands:= [vpCmdCopy, vpCmdCopyHex, vpCmdSelectAll];
    FBin.TextPopupCaption[vpCmdCopy]:= msgEditCopy;
    FBin.TextPopupCaption[vpCmdCopyHex]:= msgEditCopy+' (hex)';
    FBin.TextPopupCaption[vpCmdSelectAll]:= msgEditSelectAll;
  end;

  ViewerApplyTheme(FBin);
  FBin.Mode:= AMode;
  FBin.OpenStream(FBinStream);

  if Visible and FBin.Visible then
    FBin.SetFocus;

  DoOnChangeCaption;
end;


procedure TEditorFrame.DoFileOpen_AsPicture(const AFileName: string);
begin
  FFileName:= AFileName;
  UpdateCaptionFromFilename;

  Ed1.Hide;
  Ed2.Hide;
  Splitter.Hide;
  ReadOnly[Ed1]:= true;

  FImageBox:= TATImageBox.Create(Self);
  FImageBox.Parent:= Self;
  FImageBox.Align:= alClient;
  FImageBox.BorderStyle:= bsNone;
  FImageBox.OptFitToWindow:= true;
  FImageBox.OnScroll:= @DoImageboxScroll;
  FImageBox.OnKeyDown:= @BinaryOnKeyDown;

  try
    FImageBox.LoadFromFile(AFileName);
  except
  end;

  DoOnChangeCaption;
end;

procedure TEditorFrame.DoImageboxScroll(Sender: TObject);
begin
  DoOnUpdateStatus;
end;


procedure TEditorFrame.DoDeactivatePictureMode;
begin
  if Assigned(FImageBox) then
  begin
    FreeAndNil(FImageBox);
    Ed1.Show;
    ReadOnly[Ed1]:= false;
  end;
end;

procedure TEditorFrame.DoDeactivateViewerMode;
begin
  if Assigned(FBin) then
  begin
    FBin.OpenStream(nil);
    FreeAndNil(FBin);
    Ed1.Show;
    ReadOnly[Ed1]:= false;
  end;
end;

procedure TEditorFrame.DoFileOpen(const AFileName, AFileName2: string; AAllowLoadHistory, AAllowErrorMsgBox: boolean;
  AOpenMode: TAppOpenMode);
begin
  if not FileExistsUTF8(AFileName) then exit;
  if (AFileName2<>'') then
    if not FileExistsUTF8(AFileName2) then exit;

  Lexer[Ed1]:= nil;
  if not EditorsLinked then
    Lexer[Ed2]:= nil;

  case AOpenMode of
    cOpenModeViewText:
      begin
        DoFileOpen_AsBinary(AFileName, vbmodeText);
        exit;
      end;
    cOpenModeViewBinary:
      begin
        DoFileOpen_AsBinary(AFileName, vbmodeBinary);
        exit;
      end;
    cOpenModeViewHex:
      begin
        DoFileOpen_AsBinary(AFileName, vbmodeHex);
        exit;
      end;
    cOpenModeViewUnicode:
      begin
        DoFileOpen_AsBinary(AFileName, vbmodeUnicode);
        exit;
      end;
  end;

  if IsFilenameListedInExtensionList(AFileName, UiOps.PictureTypes) then
  begin
    DoFileOpen_AsPicture(AFileName);
    exit;
  end;

  DoDeactivatePictureMode;
  DoDeactivateViewerMode;

  DoFileOpen_Ex(Ed1, AFileName, AAllowLoadHistory, AAllowErrorMsgBox, AOpenMode);

  if AFileName2<>'' then
  begin
    EditorsLinked:= false;
    SplitHorz:= false;
    Splitted:= true;
    DoFileOpen_Ex(Ed2, AFileName2, AAllowLoadHistory, AAllowErrorMsgBox, AOpenMode);
  end;
end;

procedure TEditorFrame.DoFileOpen_Ex(Ed: TATSynEdit; const AFileName: string; AAllowLoadHistory, AAllowErrorMsgBox: boolean;
  AOpenMode: TAppOpenMode);
begin
  try
    Ed.LoadFromFile(AFileName);
    SetFileName(Ed, AFileName);
    UpdateCaptionFromFilename;
  except
    if AAllowErrorMsgBox then
      MsgBox(msgCannotOpenFile+#13+AFileName, MB_OK or MB_ICONERROR);

    SetFileName(Ed, '');
    UpdateCaptionFromFilename;

    EditorClear(Ed);
    exit
  end;

  //turn off opts for huge files
  FileWasBig:= Ed.Strings.Count>EditorOps.OpWrapEnabledMaxLines;

  DoLexerFromFilename(Ed, AFileName);
  if AAllowLoadHistory then
  begin
    DoLoadUndo(Ed);
    DoLoadHistory(Ed);
  end;
  UpdateReadOnlyFromFile(Ed);

  NotifEnabled:= UiOps.NotifEnabled;
end;

procedure TEditorFrame.UpdateReadOnlyFromFile(Ed: TATSynEdit);
begin
  if IsFileReadonly(GetFileName(Ed)) then
  begin
    ReadOnly[Ed]:= true;
    ReadOnlyFromFile:= true;
  end;
end;

procedure TEditorFrame.UpdateFrame(AUpdatedText: boolean);
var
  Ad: TATAdapterEControl;
begin
  Ed1.UpdateIncorrectCaretPositions;
  Ed2.UpdateIncorrectCaretPositions;

  Ed1.Update(AUpdatedText);
  Ed2.Update(AUpdatedText);

  if AUpdatedText then
  begin
    Ad:= Adapter[Ed1];
    Ad.OnEditorChange(Ed1);

    if not EditorsLinked then
    begin
      Ad:= Adapter[Ed2];
      if Assigned(Ad) then
        Ad.OnEditorChange(Ed2);
    end;
  end;
end;

function TEditorFrame.GetFileName(Ed: TATSynEdit): string;
begin
  if EditorsLinked or (Ed=Ed1) then
    Result:= FFileName
  else
    Result:= FFileName2;
end;

procedure TEditorFrame.SetFileName(Ed: TATSynEdit; const AFileName: string);
begin
  if EditorsLinked or (Ed=Ed1) then
    FFileName:= AFileName
  else
    FFileName2:= AFileName;
end;

function TEditorFrame.DoFileSave(ASaveAs, AAllEditors: boolean): boolean;
begin
  Result:= true;

  if not EditorsLinked and AAllEditors then
  begin
    if Ed1.Modified or ASaveAs then
      Result:= DoFileSave_Ex(Ed1, ASaveAs);

    if Ed2.Modified or ASaveAs then
      Result:= DoFileSave_Ex(Ed2, ASaveAs);
  end
  else
  begin
    if Editor.Modified or ASaveAs then
      Result:= DoFileSave_Ex(Editor, ASaveAs);
  end;
end;

function TEditorFrame.DoFileSave_Ex(Ed: TATSynEdit; ASaveAs: boolean): boolean;
var
  An: TecSyntAnalyzer;
  attr: integer;
  PrevEnabled, bNameChanged: boolean;
  NameCounter: integer;
  SFileName, NameTemp, NameInitial: string;
begin
  Result:= false;
  if not IsText then exit(true); //disable saving, but close
  if DoPyEvent(Ed, cEventOnSaveBefore, [])=cPyFalse then exit(true); //disable saving, but close

  SFileName:= GetFileName(Ed);
  bNameChanged:= false;

  if ASaveAs or (SFileName='') then
  begin
    An:= Lexer[Ed];
    if Assigned(An) then
    begin
      SaveDialog.DefaultExt:= DoGetLexerDefaultExt(An);
      SaveDialog.Filter:= DoGetLexerFileFilter(An, msgAllFiles);
    end
    else
    begin
      SaveDialog.DefaultExt:= '.txt';
      SaveDialog.Filter:= '';
    end;

    if SFileName='' then
    begin
      NameInitial:= DoPyEvent(Ed, cEventOnSaveNaming, []);
      if (NameInitial='') or (NameInitial=cPyNone) then
        NameInitial:= 'new';

      //get first free filename: new.txt, new1.txt, new2.txt, ...
      NameCounter:= 0;
      repeat
        NameTemp:= SaveDialog.InitialDir+DirectorySeparator+
                   NameInitial+IfThen(NameCounter>0, IntToStr(NameCounter))+
                   SaveDialog.DefaultExt; //DefaultExt with dot
        if not FileExistsUTF8(NameTemp) then
        begin
          SaveDialog.FileName:= ExtractFileName(NameTemp);
          Break
        end;
        Inc(NameCounter);
      until false;
    end
    else
    begin
      SaveDialog.FileName:= ExtractFileName(SFileName);
      SaveDialog.InitialDir:= ExtractFileDir(SFileName);
    end;

    if not SaveDialog.Execute then
      exit(false);

    if OnCheckFilenameOpened(SaveDialog.FileName) then
    begin
      MsgBox(
        msgStatusFilenameAlreadyOpened+#10+
        ExtractFileName(SaveDialog.FileName)+#10#10+
        msgStatusNeedToCloseTabSavedOrDup, MB_OK or MB_ICONWARNING);
      exit;
    end;

    //add to recents previous filename
    if Assigned(FOnAddRecent) then
      FOnAddRecent(Self, SFileName);

    SFileName:= SaveDialog.FileName;
    SetFileName(Ed, SFileName);
    bNameChanged:= true;

    //add to recents new filename
    if Assigned(FOnAddRecent) then
      FOnAddRecent(Self, SFileName);
  end;

  PrevEnabled:= NotifEnabled;
  NotifEnabled:= false;

  while true do
  try
    FFileAttrPrepare(SFileName, attr);
    Ed.BeginUpdate;
    try
      try
        Ed.SaveToFile(SFileName);
      except
        on E: EConvertError do
          begin
            NameTemp:= Ed.EncodingName;
            Ed.EncodingName:= cEncNameUtf8_NoBom;
            Ed.SaveToFile(SFileName);
            MsgBox(Format(msgCannotSaveFileWithEnc, [NameTemp]), MB_OK or MB_ICONWARNING);
          end
        else
          raise;
      end;
    finally
      Ed.EndUpdate;
    end;
    FFileAttrRestore(SFileName, attr);
    Break;
  except
    if MsgBox(msgCannotSaveFile+#10+SFileName,
      MB_RETRYCANCEL or MB_ICONERROR) = IDCANCEL then
      Exit(false);
  end;

  if bNameChanged then
    DoLexerFromFilename(Ed, GetFileName(Ed));

  NotifEnabled:= PrevEnabled;

  if not TabCaptionFromApi then
    UpdateCaptionFromFilename;

  DoSaveUndo(Ed, SFileName);

  DoPyEvent(Ed, cEventOnSaveAfter, []);
  if Assigned(FOnSaveFile) then
    FOnSaveFile(Self);
  Result:= true;
end;

procedure TEditorFrame.DoFileReload_DisableDetectEncoding;
begin
  if FileName='' then exit;
  if Ed1.Modified then
    if MsgBox(
      Format(msgConfirmReopenModifiedTab, [ExtractFileName(FileName)]),
      MB_OKCANCEL or MB_ICONWARNING
      ) <> ID_OK then exit;

  Ed1.Strings.EncodingDetect:= false;
  Ed1.Strings.LoadFromFile(FileName);
  Ed1.Strings.EncodingDetect:= true;
  UpdateEds(true);
end;

procedure TEditorFrame.DoFileReload;
var
  PrevCaretX, PrevCaretY: integer;
  PrevTail: boolean;
  Mode: TAppOpenMode;
  Ed: TATSynEdit;
begin
  if FileName='' then exit;
  Ed:= Ed1;

  //remember props
  PrevCaretX:= 0;
  PrevCaretY:= 0;

  if Ed.Carets.Count>0 then
    with Ed.Carets[0] do
      begin
        PrevCaretX:= PosX;
        PrevCaretY:= PosY;
      end;

  PrevTail:= UiOps.ReloadFollowTail and
    (Ed.Strings.Count>0) and
    (PrevCaretY=Ed.Strings.Count-1);

  Mode:= cOpenModeEditor;
  if IsBinary then
    case FBin.Mode of
      vbmodeText:
        Mode:= cOpenModeViewText;
      vbmodeBinary:
        Mode:= cOpenModeViewBinary;
      vbmodeHex:
        Mode:= cOpenModeViewHex;
      vbmodeUnicode:
        Mode:= cOpenModeViewUnicode;
      else
        Mode:= cOpenModeViewHex;
    end;

  //reopen
  DoSaveHistory(Ed);
  DoFileOpen(FileName, '', true{AllowLoadHistory}, false, Mode);
  if Ed.Strings.Count=0 then exit;

  //restore props
  PrevCaretY:= Min(PrevCaretY, Ed.Strings.Count-1);
  if PrevTail then
  begin
    PrevCaretX:= 0;
    PrevCaretY:= Ed.Strings.Count-1;
  end;

  Application.ProcessMessages; //for DoGotoPos

  Ed.DoGotoPos(
    Point(PrevCaretX, PrevCaretY),
    Point(-1, -1),
    1,
    1, //indentVert must be >0
    true,
    false
    );

  OnUpdateStatus(Self);
end;

procedure TEditorFrame.SetLineEnds(Ed: TATSynEdit; AValue: TATLineEnds);
begin
  if GetLineEnds(Ed)=AValue then Exit;

  Ed.Strings.Endings:= AValue;
  Ed.Update;
  if (Ed=Ed1) and EditorsLinked then
    Ed2.Update;
end;

procedure TEditorFrame.SetUnprintedShow(AValue: boolean);
begin
  Ed1.OptUnprintedVisible:= AValue;
  UpdateEds;
end;

procedure TEditorFrame.SetUnprintedSpaces(AValue: boolean);
begin
  Ed1.OptUnprintedSpaces:= AValue;
  UpdateEds;
end;

procedure TEditorFrame.SetEditorsLinked(AValue: boolean);
begin
  if FEditorsLinked=AValue then exit;
  FEditorsLinked:= AValue;

  if FEditorsLinked then
    Ed2.Strings:= Ed1.Strings
  else
    Ed2.Strings:= nil;

  Ed1.Strings.GutterDecor1:= Ed1.GutterDecor;
  if FEditorsLinked then
  begin
    Ed1.Strings.GutterDecor2:= Ed2.GutterDecor;
  end
  else
  begin
    Ed1.Strings.GutterDecor2:= nil;
    Ed2.Strings.GutterDecor1:= Ed2.GutterDecor;
    Ed2.Strings.GutterDecor2:= nil;
  end;

  Adapter1.AddEditor(nil);
  if Assigned(Adapter2) then
    Adapter2.AddEditor(nil);

  if FEditorsLinked then
  begin
    Adapter1.AddEditor(Ed1);
    Adapter1.AddEditor(Ed2);
  end
  else
  begin
    if Adapter2=nil then
    begin
      Adapter2:= TATAdapterEControl.Create(Self);
      OnInitAdapter(Adapter2);
    end;
    Adapter1.AddEditor(Ed1);
    Adapter2.AddEditor(Ed2);
  end;

  Ed2.Fold.Clear;
  Ed2.Update(true);
end;

procedure TEditorFrame.SplitterMoved(Sender: TObject);
begin
  FSplitPos:= GetSplitPosCurrent;
end;

procedure TEditorFrame.SetUnprintedEnds(AValue: boolean);
begin
  Ed1.OptUnprintedEnds:= AValue;
  UpdateEds;
end;

procedure TEditorFrame.SetUnprintedEndsDetails(AValue: boolean);
begin
  Ed1.OptUnprintedEndsDetails:= AValue;
  UpdateEds;
end;

procedure TEditorFrame.EditorOnClickGutter(Sender: TObject; ABand, ALine: integer);
var
  Ed: TATSynEdit;
begin
  Ed:= Sender as TATSynEdit;

  if DoPyEvent(Ed, cEventOnClickGutter, [
    '"'+ConvertShiftStateToString(KeyboardStateToShiftState)+'"',
    IntToStr(ALine),
    IntToStr(ABand)
    ]) = cPyFalse then exit;

  if ABand=Ed.GutterBandBm then
    ed.BookmarkToggleForLine(ALine, 1, '', false, true, 0);
end;

procedure TEditorFrame.EditorOnDrawBookmarkIcon(Sender: TObject; C: TCanvas; ALineNum: integer;
  const ARect: TRect);
var
  Ed: TATSynEdit;
  r: TRect;
  dx: integer;
  index, kind: integer;
begin
  r:= ARect;
  if r.Left>=r.Right then exit;

  Ed:= Sender as TATSynEdit;
  index:= Ed.Strings.Bookmarks.Find(ALineNum);
  if index<0 then exit;

  kind:= Ed.Strings.Bookmarks[index].Data.Kind;
  if kind<=1 then
  begin
    c.brush.color:= GetAppColor('EdBookmarkIcon');
    c.pen.color:= c.brush.color;
    inc(r.top, 1);
    inc(r.left, 4);
    dx:= r.Height div 2-1;
    c.Polygon([Point(r.left, r.top), Point(r.left+dx, r.top+dx), Point(r.left, r.top+2*dx)]);
  end
  else
  if (kind>=Low(AppBookmarkSetup)) and (kind<=High(AppBookmarkSetup)) then
  begin
    AppBookmarkImagelist.Draw(c, r.left, r.top,
      AppBookmarkSetup[kind].ImageIndex);
  end;
end;


function TEditorFrame.GetCommentString(Ed: TATSynEdit): string;
var
  an: TecSyntAnalyzer;
begin
  Result:= '';
  an:= Adapter[Ed].Lexer;
  if Assigned(an) then
    Result:= an.LineComment;
end;

function TEditorFrame.GetEnabledCodeTree(Ed: TATSynEdit): boolean;
begin
  if (Ed=Ed1) or EditorsLinked then
    Result:= FEnabledCodeTree[0]
  else
    Result:= FEnabledCodeTree[1];
end;

function TEditorFrame.GetEnabledFolding: boolean;
begin
  Result:= Editor.OptFoldEnabled;
end;

procedure TEditorFrame.DoOnChangeCaption;
begin
  if Assigned(FOnChangeCaption) then
    FOnChangeCaption(Self);
end;

procedure TEditorFrame.DoRestoreFolding;
var
  S: string;
begin
  if FFoldTodo<>'' then
  begin
    S:= FFoldTodo;
    FFoldTodo:= '';
    EditorSetFoldString(Editor, S);
  end;

  if FTopLineTodo>0 then
  begin
    Editor.LineTop:= FTopLineTodo;
    FTopLineTodo:= 0;
  end;
end;

procedure TEditorFrame.DoMacroStart;
begin
  FMacroRecord:= true;
  FMacroString:= '';
end;

procedure TEditorFrame.DoMacroStop(ACancel: boolean);
begin
  FMacroRecord:= false;
  if ACancel then
    FMacroString:= '';
end;

procedure TEditorFrame.DoOnUpdateStatus;
begin
  if Assigned(FOnUpdateStatus) then
    FOnUpdateStatus(Self);
end;

procedure TEditorFrame.EditorClickMoveCaret(Sender: TObject; APrevPnt,
  ANewPnt: TPoint);
begin
  if Assigned(FOnEditorClickMoveCaret) then
    FOnEditorClickMoveCaret(Self, APrevPnt, ANewPnt);
end;

procedure TEditorFrame.EditorDrawMicromap(Sender: TObject; C: TCanvas;
  const ARect: TRect);
const
  cTagOccurrences = 101; //see plugin Hilite Occurrences
  cTagSpellChecker = 105; //see plugin SpellChecker
var
  NScale: double;
  NPixelOffset: integer;
//
  function GetItemRect(NLine1, NLine2: integer; ALeft: boolean): TRect;
  begin
    if ALeft then
    begin
      Result.Left:= ARect.Left;
      Result.Right:= Result.Left + EditorOps.OpMicromapWidthSmall;
    end
    else
    begin
      Result.Right:= ARect.Right;
      Result.Left:= Result.Right - EditorOps.OpMicromapWidthSmall;
    end;
    Result.Top:= ARect.Top+Trunc(NLine1*NScale);
    Result.Bottom:= Max(Result.Top+2, ARect.Top+Trunc((NLine2+1)*NScale));
    //Inc(Result.Top, NPixelOffset);
    //Inc(Result.Bottom, NPixelOffset);
  end;
//
var
  Ed: TATSynEdit;
  NColor: TColor;
  Caret: TATCaretItem;
  State: TATLineState;
  Mark: TATMarkerItem;
  NColorSelected, NColorOccur, NColorSpell: TColor;
  R1: TRect;
  NLine1, NLine2, i: integer;
  Obj: TATLinePartClass;
begin
  Ed:= Sender as TATSynEdit;
  if Ed.Strings.Count=0 then exit;
  NScale:= ARect.Height / Ed.Strings.Count;
  NPixelOffset:= Ed.ScrollVert.NPixelOffset;

  C.Brush.Color:= GetAppColor('EdMicromapBg');
  C.FillRect(ARect);

  R1:= GetItemRect(Ed.LineTop, Ed.LineBottom, true);
  R1.Right:= ARect.Right;

  C.Brush.Color:= GetAppColor('EdMicromapViewBg');
  C.FillRect(R1);

  NColorSelected:= Ed.Colors.TextSelBG;
  NColorOccur:= GetAppColor('EdMicromapOccur');
  NColorSpell:= GetAppColor('EdMicromapSpell');

  //paint line states
  for i:= 0 to Ed.Strings.Count-1 do
  begin
    State:= Ed.Strings.LinesState[i];
    case State of
      cLineStateNone: Continue;
      cLineStateAdded: NColor:= Ed.Colors.StateAdded;
      cLineStateChanged: NColor:= Ed.Colors.StateChanged;
      cLineStateSaved: NColor:= Ed.Colors.StateSaved;
      else Continue;
    end;
    C.Brush.Color:= NColor;
    C.FillRect(GetItemRect(i, i, true));
  end;

  //paint selections
  C.Brush.Color:= NColorSelected;
  for i:= 0 to Ed.Carets.Count-1 do
  begin
    Caret:= Ed.Carets[i];
    Caret.GetSelLines(NLine1, NLine2, false);
    if NLine1<0 then Continue;
    R1:= GetItemRect(NLine1, NLine2, false);
    C.FillRect(R1);
  end;

  //paint marks for plugins
  for i:= 0 to Ed.Attribs.Count-1 do
  begin
    Mark:= Ed.Attribs[i];
    Obj:= TATLinePartClass(Mark.Ptr);

    case Mark.Tag of
      cTagSpellChecker:
        begin
          C.Brush.Color:= NColorSpell;
          C.FillRect(GetItemRect(Mark.PosY, Mark.PosY, false));
        end;
      cTagOccurrences:
        begin
          C.Brush.Color:= NColorOccur;
          C.FillRect(GetItemRect(Mark.PosY, Mark.PosY, false));
        end;
      else
        begin
          if Obj.ShowOnMap then
          begin
            C.Brush.Color:= Obj.Data.ColorBG;
            C.FillRect(GetItemRect(Mark.PosY, Mark.PosY, false));
          end;
        end;
      end;
  end;
end;

procedure TEditorFrame.EditorClickEndSelect(Sender: TObject; APrevPnt,
  ANewPnt: TPoint);
begin
  if Assigned(FOnEditorClickEndSelect) then
    FOnEditorClickEndSelect(Self, APrevPnt, ANewPnt);
end;


procedure TEditorFrame.DoSaveHistory(Ed: TATSynEdit);
var
  c: TJSONConfig;
  SFileName: string;
  path: UnicodeString;
  items: TStringlist;
begin
  if not FSaveHistory then exit;
  if UiOps.MaxHistoryFiles<2 then exit;

  SFileName:= GetFileName(Ed);
  if SFileName='' then exit;

  c:= TJsonConfig.Create(nil);
  try
    try
      c.Formatted:= true;
      c.Filename:= GetAppPath(cFileOptionsHistoryFiles);
    except
      MsgBadConfig(GetAppPath(cFileOptionsHistoryFiles));
      exit
    end;

    path:= UTF8Decode(SMaskFilenameSlashes(SFileName));

    items:= TStringList.Create;
    try
      c.DeletePath(path);
      c.EnumSubKeys('/', items);
      while items.Count>=UiOps.MaxHistoryFiles do
      begin
        c.DeletePath(UTF8Decode('/'+items[0]));
        items.Delete(0);
      end;
    finally
      FreeAndNil(items);
    end;

    DoSaveHistoryEx(Ed, c, path);
  finally
    c.Free;
  end;
end;

procedure TEditorFrame.DoSaveHistoryEx(Ed: TATSynEdit; c: TJsonConfig; const path: UnicodeString);
var
  caret: TATCaretItem;
  items, items2: TStringList;
  bookmark: TATBookmarkItem;
  i: integer;
begin
  c.SetValue(path+cHistory_Lexer, LexerName[Ed]);
  c.SetValue(path+cHistory_Enc, Ed.EncodingName);
  c.SetValue(path+cHistory_Top, Ed.LineTop);
  c.SetValue(path+cHistory_Wrap, Ord(Ed.OptWrapMode));
  if not ReadOnlyFromFile then
    c.SetValue(path+cHistory_RO, ReadOnly[Ed]);
  c.SetValue(path+cHistory_Ruler, Ed.OptRulerVisible);
  c.SetValue(path+cHistory_Minimap, Ed.OptMinimapVisible);
  c.SetValue(path+cHistory_Micromap, Ed.OptMicromapVisible);
  c.SetValue(path+cHistory_TabSize, Ed.OptTabSize);
  c.SetValue(path+cHistory_TabSpace, Ed.OptTabSpaces);
  c.SetValue(path+cHistory_Unpri, Ed.OptUnprintedVisible);
  c.SetValue(path+cHistory_Unpri_Spaces, Ed.OptUnprintedSpaces);
  c.SetValue(path+cHistory_Unpri_Ends, Ed.OptUnprintedEnds);
  c.SetValue(path+cHistory_Unpri_Detail, Ed.OptUnprintedEndsDetails);
  c.SetValue(path+cHistory_Nums, Ed.Gutter[Ed.GutterBandNum].Visible);
  c.SetValue(path+cHistory_Fold, EditorGetFoldString(Ed));

  if TabColor=clNone then
    c.SetValue(path+cHistory_TabColor, '')
  else
    c.SetValue(path+cHistory_TabColor, ColorToString(TabColor));

  if Ed.Carets.Count>0 then
  begin
    caret:= Ed.Carets[0];
    c.SetValue(path+cHistory_Caret,
      Format('%d,%d,%d,%d,', [caret.PosX, caret.PosY, caret.EndX, caret.EndY]));
  end;

  items:= TStringList.Create;
  items2:= TStringList.Create;
  try
    for i:= 0 to Ed.Strings.Bookmarks.Count-1 do
    begin
      bookmark:= Ed.Strings.Bookmarks[i];
      //save usual bookmarks and numbered bookmarks (kind=1..10)
      if (bookmark.Data.Kind>10) then Continue;
      items.Add(IntToStr(bookmark.Data.LineNum));
      items2.Add(IntToStr(bookmark.Data.Kind));
    end;
    c.SetValue(path+cHistory_Bookmark, items);
    c.SetValue(path+cHistory_BookmarkKind, items2);

  finally
    FreeAndNil(items2);
    FreeAndNil(items);
  end;

  c.SetValue(path+cHistory_CodeTreeFilter, FCodetreeFilter);
  c.SetValue(path+cHistory_CodeTreeFilters, FCodetreeFilterHistory);
end;

procedure _WriteStringToFileInHiddenDir(const fn, s: string);
var
  dir: string;
begin
  if s<>'' then
  begin
    dir:= ExtractFileDir(fn);
    if not DirectoryExists(dir) then
    begin
      CreateDir(dir);
      {$ifdef windows}
      FileSetAttr(dir, faHidden);
      {$endif}
    end;
    DoWriteStringToFile(fn, s);
  end
  else
  begin
    if FileExistsUTF8(fn) then
      DeleteFile(fn);
  end;
end;

procedure TEditorFrame.DoSaveUndo(Ed: TATSynEdit; const AFileName: string);
begin
  if IsFilenameListedInExtensionList(AFileName, UiOps.UndoPersistent) then
  begin
    _WriteStringToFileInHiddenDir(GetAppUndoFilename(AFileName, false), Ed.UndoAsString);
    _WriteStringToFileInHiddenDir(GetAppUndoFilename(AFileName, true), Ed.RedoAsString);
  end;
end;

procedure TEditorFrame.DoLoadHistory(Ed: TATSynEdit);
var
  c: TJSONConfig;
  SFileName: string;
  path: UnicodeString;
begin
  SFileName:= GetFileName(Ed);
  if SFileName='' then exit;
  if UiOps.MaxHistoryFiles<2 then exit;

  c:= TJsonConfig.Create(nil);
  try
    try
      c.Formatted:= true;
      c.Filename:= GetAppPath(cFileOptionsHistoryFiles);
    except
      MsgBadConfig(GetAppPath(cFileOptionsHistoryFiles));
      exit
    end;

    path:= UTF8Decode(SMaskFilenameSlashes(SFileName));
    DoLoadHistoryEx(Ed, SFileName, c, path);
  finally
    c.Free;
  end;
end;


procedure TEditorFrame.DoLoadHistoryEx(Ed: TATSynEdit; const AFileName: string; c: TJsonConfig; const path: UnicodeString);
var
  str, str0: string;
  Caret: TATCaretItem;
  nTop, nKind, i: integer;
  items, items2: TStringlist;
  BmData: TATBookmarkData;
begin
  FillChar(BmData, SizeOf(BmData), 0);
  BmData.ShowInBookmarkList:= true;

  //file not listed?
  nTop:= c.GetValue(path+cHistory_Top, -1);
  if nTop<0 then exit;

  //lexer
  str0:= LexerName[Ed];
  str:= c.GetValue(path+cHistory_Lexer, '');
  if (str<>'') and (str<>str0) then
    LexerName[Ed]:= str;

  //enc
  str0:= Ed.EncodingName;
  str:= c.GetValue(path+cHistory_Enc, str0);
  if str<>str0 then
  begin
    Ed.EncodingName:= str;
    //reread in enc
    //but only if not modified (modified means other text is loaded)
    if AFileName<>'' then
      if not Ed.Modified then
        Ed.LoadFromFile(AFileName);
  end;

  TabColor:= StringToColorDef(c.GetValue(path+cHistory_TabColor, ''), clNone);

  ReadOnly[Ed]:= c.GetValue(path+cHistory_RO, ReadOnly[Ed]);
  if not FileWasBig then
  begin
    Ed.OptWrapMode:= TATSynWrapMode(c.GetValue(path+cHistory_Wrap, Ord(Ed.OptWrapMode)));
    Ed.OptMinimapVisible:= c.GetValue(path+cHistory_Minimap, Ed.OptMinimapVisible);
    Ed.OptMicromapVisible:= c.GetValue(path+cHistory_Micromap, Ed.OptMicromapVisible);
  end;
  Ed.OptRulerVisible:= c.GetValue(path+cHistory_Ruler, Ed.OptRulerVisible);
  Ed.OptTabSize:= c.GetValue(path+cHistory_TabSize, Ed.OptTabSize);
  Ed.OptTabSpaces:= c.GetValue(path+cHistory_TabSpace, Ed.OptTabSpaces);
  Ed.OptUnprintedVisible:= c.GetValue(path+cHistory_Unpri, Ed.OptUnprintedVisible);
  Ed.OptUnprintedSpaces:= c.GetValue(path+cHistory_Unpri_Spaces, Ed.OptUnprintedSpaces);
  Ed.OptUnprintedEnds:= c.GetValue(path+cHistory_Unpri_Ends, Ed.OptUnprintedEnds);
  Ed.OptUnprintedEndsDetails:= c.GetValue(path+cHistory_Unpri_Detail, Ed.OptUnprintedEndsDetails);

  if Assigned(Lexer[Ed]) then
  begin
    //this seems ok: works even for open-file via cmdline
    FFoldTodo:= c.GetValue(path+cHistory_Fold, '');
    //linetop
    FTopLineTodo:= nTop; //restore LineTop after analize done
    Ed.LineTop:= nTop; //scroll immediately
  end
  else
  begin
    //for open-file from app: ok
    //for open via cmdline: not ok (maybe need to do it after form shown? how?)
    Ed.Update(true);
    Application.ProcessMessages;
    Ed.LineTop:= nTop;
  end;

  with Ed.Gutter[Ed.GutterBandNum] do
    Visible:= c.GetValue(path+cHistory_Nums, Visible);

  //caret
  if Ed.Carets.Count>0 then
  begin
    caret:= Ed.Carets[0];
    str:= c.GetValue(path+cHistory_Caret, '');
    caret.PosX:= StrToIntDef(SGetItem(str), 0);
    caret.PosY:= StrToIntDef(SGetItem(str), 0);
    caret.EndX:= StrToIntDef(SGetItem(str), -1);
    caret.EndY:= StrToIntDef(SGetItem(str), -1);
    Ed.UpdateIncorrectCaretPositions;
    Ed.DoEventCarets;
  end;

  //bookmarks
  items:= TStringList.create;
  items2:= TStringList.create;
  try
    c.GetValue(path+cHistory_Bookmark, items, '');
    c.GetValue(path+cHistory_BookmarkKind, items2, '');
    for i:= 0 to items.Count-1 do
    begin
      nTop:= StrToIntDef(items[i], -1);
      if i<items2.Count then
        nKind:= StrToIntDef(items2[i], 1)
      else
        nKind:= 1;
      if Ed.Strings.IsIndexValid(nTop) then
      begin
        BmData.LineNum:= nTop;
        BmData.Kind:= nKind;
        Ed.Strings.Bookmarks.Add(BmData);
      end;
    end;
  finally
    FreeAndNil(items2);
    FreeAndNil(items);
  end;

  FCodetreeFilter:= c.GetValue(path+cHistory_CodeTreeFilter, '');
  c.GetValue(path+cHistory_CodeTreeFilters, FCodetreeFilterHistory, '');

  Ed.Update;
  if Splitted and EditorsLinked then
    Ed2.Update;
end;

procedure TEditorFrame.DoLoadUndo(Ed: TATSynEdit);
var
  SFileName, STemp: string;
begin
  SFileName:= GetFileName(Ed);
  if SFileName='' then exit;
  if IsFilenameListedInExtensionList(SFileName, UiOps.UndoPersistent) then
  begin
    STemp:= GetAppUndoFilename(SFileName, false);
    if FileExistsUTF8(STemp) then
      Ed.UndoAsString:= DoReadContentFromFile(STemp);

    STemp:= GetAppUndoFilename(SFileName, true);
    if FileExistsUTF8(STemp) then
      Ed.RedoAsString:= DoReadContentFromFile(STemp);
  end;
end;

function TEditorFrame.DoPyEvent(AEd: TATSynEdit; AEvent: TAppPyEvent;
  const AParams: array of string): string;
begin
  Result:= '';
  if Assigned(FOnPyEvent) then
    Result:= FOnPyEvent(AEd, AEvent, AParams);
end;


procedure TEditorFrame.SetTabColor(AColor: TColor);
var
  Gr: TATGroups;
  Pages: TATPages;
  NLocalGroups, NGlobalGroup, NTab: integer;
  D: TATTabData;
begin
  FTabColor:= AColor;
  GetFrameLocation(Self, Gr, Pages, NLocalGroups, NGlobalGroup, NTab);
  D:= Pages.Tabs.GetTabData(NTab);
  if Assigned(D) then
  begin
    D.TabColor:= AColor;
    Pages.Tabs.Invalidate;
  end;
end;

procedure TEditorFrame.DoRemovePreviewStyle;
var
  Gr: TATGroups;
  Pages: TATPages;
  NLocalGroup, NGlobalGroup, NTab: integer;
  D: TATTabData;
begin
  GetFrameLocation(Self, Gr, Pages, NLocalGroup, NGlobalGroup, NTab);
  D:= Pages.Tabs.GetTabData(NTab);
  if Assigned(D) then
  begin
    D.TabSpecial:= false;
    D.TabFontStyle:= [];
    Pages.Tabs.Invalidate;
  end;
end;

procedure TEditorFrame.SetTabImageIndex(AValue: integer);
var
  Gr: TATGroups;
  Pages: TATPages;
  NLocalGroup, NGlobalGroup, NTab: integer;
  D: TATTabData;
begin
  if FTabImageIndex=AValue then exit;
  FTabImageIndex:= AValue;

  GetFrameLocation(Self, Gr, Pages, NLocalGroup, NGlobalGroup, NTab);
  D:= Pages.Tabs.GetTabData(NTab);
  if Assigned(D) then
  begin
    D.TabImageIndex:= AValue;
    Pages.Tabs.Invalidate;
  end;
end;

procedure TEditorFrame.NotifChanged(Sender: TObject);
begin
  //silent reload if: not modified, and undo empty
  if (not Ed1.Modified) and (Ed1.UndoCount<=1) then
  begin
    DoFileReload;
    exit
  end;

  case MsgBox(msgConfirmFileChangedOutside+#10+FileName+
         #10#10+msgConfirmReloadIt+#10+msgConfirmReloadItHotkeys,
         MB_YESNOCANCEL or MB_ICONQUESTION) of
    ID_YES:
      DoFileReload;
    ID_CANCEL:
      NotifEnabled:= false;
  end;
end;

procedure TEditorFrame.SetEnabledCodeTree(Ed: TATSynEdit; AValue: boolean);
begin
  if GetEnabledCodeTree(Ed)=AValue then Exit;

  if (Ed=Ed1) or EditorsLinked then
    FEnabledCodeTree[0]:= AValue
  else
    FEnabledCodeTree[1]:= AValue;

  if not AValue then
    ClearTreeviewWithData(CachedTreeview[Ed]);
end;

procedure TEditorFrame.SetEnabledFolding(AValue: boolean);
begin
  Ed1.OptFoldEnabled:= AValue;
  Ed2.OptFoldEnabled:= AValue;
end;

function TEditorFrame.PictureSizes: TPoint;
begin
  if Assigned(FImageBox) then
    Result:= Point(FImageBox.ImageWidth, FImageBox.ImageHeight)
  else
    Result:= Point(0, 0);
end;


procedure TEditorFrame.DoGotoPos(Ed: TATSynEdit; APosX, APosY: integer);
begin
  if APosY<0 then exit;
  if APosX<0 then APosX:= 0; //allow x<0

  Ed.LineTop:= APosY;
  TopLineTodo:= APosY; //check is it still needed
  Ed.DoGotoPos(
    Point(APosX, APosY),
    Point(-1, -1),
    UiOps.FindIndentHorz,
    UiOps.FindIndentVert,
    true,
    true
    );
  Ed.Update;
end;

procedure TEditorFrame.DoLexerFromFilename(Ed: TATSynEdit; const AFileName: string);
var
  TempLexer: TecSyntAnalyzer;
  TempLexerLite: TATLiteLexer;
  SName: string;
begin
  if AFileName='' then exit;
  DoLexerDetect(AFileName, TempLexer, TempLexerLite, SName);
  if Assigned(TempLexer) then
    Lexer[Ed]:= TempLexer
  else
  if Assigned(TempLexerLite) then
    LexerLite[Ed]:= TempLexerLite;
end;

procedure TEditorFrame.SetFocus;
begin
  DoOnChangeCaption;
  DoShow;

  if Assigned(FBin) then
    if FBin.Visible and FBin.CanFocus then
    begin
      EditorFocus(FBin);
      exit;
    end;

  if Assigned(FImageBox) then
    if FImageBox.Visible and FImageBox.CanFocus then
    begin
      FImageBox.SetFocus;
      exit;
    end;

  EditorFocus(Editor);
end;

type
  TATSynEdit_Hack = class(TATSynEdit);

procedure TEditorFrame.BinaryOnKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Shift=[]) then
    if (Key=VK_UP) or
       (Key=VK_DOWN) or
       (Key=VK_LEFT) or
       (Key=VK_RIGHT) or
       (Key=VK_HOME) or
       (Key=VK_END) then
    exit;

  TATSynEdit_Hack(Editor).KeyDown(Key, Shift);
end;

procedure TEditorFrame.BinaryOnScroll(Sender: TObject);
begin
  DoOnUpdateStatus;
end;

procedure TEditorFrame.BinaryOnProgress(const ACurrentPos,
  AMaximalPos: Int64; var AContinueSearching: Boolean);
begin
  if Assigned(FOnProgress) then
    FOnProgress(nil, ACurrentPos, AMaximalPos, AContinueSearching);
end;

function TEditorFrame.BinaryFindFirst(AFinder: TATEditorFinder; AShowAll: boolean): boolean;
var
  Ops: TATStreamSearchOptions;
begin
  Ops:= [];
  if AFinder.OptCase then Include(Ops, asoCaseSens);
  if AFinder.OptWords then Include(Ops, asoWholeWords);
  if AShowAll then Include(Ops, asoShowAll);

  Result:= FBin.FindFirst(
    UTF8Encode(AFinder.StrFind), Ops, 0);
end;

function TEditorFrame.BinaryFindNext(ABack: boolean): boolean;
begin
  if FBinStream=nil then exit;
  Result:= FBin.FindNext(ABack);
end;

procedure TEditorFrame.DoFileClose;
begin
  Lexer[Ed1]:= nil;
  if not EditorsLinked then
    Lexer[Ed2]:= nil;

  FFileName:= '';
  FFileName2:= '';
  UpdateCaptionFromFilename;

  if Assigned(FBin) then
  begin
    FBin.OpenStream(nil);
    FreeAndNil(FBin);
    Ed1.Show;
  end;

  EditorClear(Ed1);
  if not EditorsLinked then
    EditorClear(Ed2);

  UpdateModified(Ed1);
end;

procedure TEditorFrame.DoToggleFocusSplitEditors;
var
  Ed: TATSynEdit;
begin
  if Splitted then
  begin
    Ed:= EditorBro;
    if Ed.Enabled and Ed.Visible then
    begin
      FActiveSecondaryEd:= Ed=Ed2;
      Ed.SetFocus;
    end;
  end;
end;

function TEditorFrame.IsPreview: boolean;
var
  Gr: TATGroups;
  Pages: TATPages;
  NLocalGroups, NGlobalGroup, NTab: integer;
  D: TATTabData;
begin
  Result:= false;
  GetFrameLocation(Self, Gr, Pages, NLocalGroups, NGlobalGroup, NTab);
  if NTab>=0 then
  begin
    D:= Pages.Tabs.GetTabData(NTab);
    if Assigned(D) then
      Result:= D.TabSpecial;
  end;
end;

function TEditorFrame.IsCaretInsideCommentOrString(Ed: TATSynEdit; AX, AY: integer): boolean;
var
  Pnt1, Pnt2: TPoint;
  SLexer, STokenText, STokenStyle: string;
begin
  Result:= false;

  //lite lexer not supported here
  if not (Ed.AdapterForHilite is TATAdapterEControl) then exit;
  SLexer:= LexerName[Ed];
  if SLexer='' then exit;

  TATAdapterEControl(Ed.AdapterForHilite).GetTokenAtPos(
    Point(AX, AY),
    Pnt1,
    Pnt2,
    STokenText,
    STokenStyle
    );
  Result:= IsLexerStyleCommentOrString(SLexer, STokenStyle);
end;

end.

