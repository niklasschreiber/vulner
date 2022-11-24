

<ServiceContract>
Interface IMyService
    Function MyServiceMethod() As Integer
End Interface

<ServiceContract>
Interface IMyService1
    <OperationContract>
    Function MyServiceMethod() As Integer
End Interface

<Serializable>
Public Class Foo

	Private Sub SurroundingSub()
		Dim v1 As Integer = 0
		Dim v2 As Boolean = False
		Dim v3 = Not Not v1
		Dim v4 = Not Not v2
		de = New DirectoryEntry("LDAP://ad.example.com:389/ou=People,dc=example,dc=com")
	End Sub

	Public Sub Foo()
		Dim g = New Guid()
		Dim g1 = New Guid(Test)
	End Sub

Private Shared Sub Main(ByVal args As String())
    Assembly.LoadFrom()
    Assembly.LoadFile()
    Assembly.LoadWithPartialName()
	GC.SuppressFinalize
End Sub

    <OnSerializing>
    Public Sub OnSerializing(ByVal context As StreamingContext)
    End Sub

    <OnSerialized>
    Private Function OnSerialized(ByVal context As StreamingContext) As Integer
    End Function

    <OnDeserializing>
    Private Sub OnDeserializing()
    End Sub

    <OnSerializing>
    Public Sub OnSerializing2(Of T)(ByVal context As Context)
    End Sub

    <OnDeserialized>
    Private Sub OnDeserialized(ByVal context As StreamingContext, ByVal str As String)
    End Sub
End Class

<SecurityCritical>
Public Class Foo
    <SecuritySafeCritical>
    Public Sub Bar()
    End Sub
End Class

Private Class MyException
    Inherits Exception
End Class

<Export(GetType(ISomeType))>
Public Class SomeType
    Inherits ISomeType
End Class

<Export(GetType(ISomeTypeX))>
Public Class SomeType
End Class


<PartCreationPolicy(CreationPolicy.Any)>
Public Class FooBar2
    Inherits IFooBar
End Class

<Export(GetType(IFooBar))>
<PartCreationPolicy(CreationPolicy.Any)>
Public Class FooBar
    Inherits IFooBar
End Class

Class SurroundingClass
    Private Shared Sub Main(ByVal args As String())
        Dim hres1 = CoSetProxyBlanket(Nothing, 0, 0, Nothing, 0, 0, IntPtr.Zero, 0)
        Dim hres2 = CoInitializeSecurity(IntPtr.Zero, -1, IntPtr.Zero, IntPtr.Zero, RpcAuthnLevel.None, RpcImpLevel.Impersonate, IntPtr.Zero, EoAuthnCap.None, IntPtr.Zero)
    End Sub
	
	Private Shared Sub Main(ByVal args As String())
		Thread.CurrentThread.Suspend()
		Thread.CurrentThread.Resume()
	End Sub

	Private Shared Sub Main2(ByVal args As String())
		Dim fieldInfo As System.Reflection.FieldInfo = ""
		Dim handle As SafeHandle = CType(fieldInfo.GetValue(rKey), SafeHandle)
		Dim dangerousHandle As IntPtr = handle.DangerousGetHandle()
		
		Try
		Catch exc As Exception
		End Try
		
	End Sub


End Class

Public Class JunkFood
    Public Sub DoSomething(ByVal i As Integer)
        If TypeOf Me Is Pizza Then
		
			 If TypeOf Me Is Pizza Then
				i = i And -1
				j = i Xor 0
				k = i Or 0
			End If
		
        End If

        If TypeOf Me.i Is Integer Then
        End If
    End Sub
End Class

