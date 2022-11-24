
Imports System.DirectoryServices
Imports System.IO
Imports System.Web.UI.WebControls
Imports System
Imports System.Reflection
Imports System.Security.Permissions
Imports System.Security.Cryptography
Imports System.Security
Imports System.Runtime.InteropServices
Imports System.Data.SqlClient
Imports System.Activator
Imports System.AppDomain
Imports System.Reflection.Assembly
Imports System.Type
' Dead Code
Imports System.Windows.Forms
Namespace PerformanceLibrary

   Public Class UnusedLocals

      Sub SomeMethod()
      
         Dim unusedInteger As Integer
         Dim unusedString As String = "hello"
         Dim unusedArray As String() = Environment.GetLogicalDrives()
         Dim unusedButton As New Button()

      End Sub

   End Class

End Namespace

Public Class _Default
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

    End Sub

    Public Class B ' VIOLATION
        Implements ICloneable

        Dim key As New DESCryptoServiceProvider() ' VIOLATION
        Dim violClass As New Random() ' VIOLATION
        Dim a As Date
        Dim mmm As Integer = a.Millisecond
        Dim millis As Integer = System.DateTime.Now.Millisecond ' VIOLATION
        Dim rng As Random = New System.Random(millis)

        Public connectionStringClass As String = "Data Source=myServerAddress;Initial Catalog=myDataBase;User Id=myUsername;Password=myPassword;" ' VIOLATION
        Public ReadOnly numbers() As Integer = {1, 2, 3}
        Public var_pub As Integer ' violation   

        Public pointer1 As IntPtr ' violation
        Protected pointer2 As UIntPtr ' violation 

        Protected var_prot As Integer ' violation

        Shared st As Integer ' vioilation    
        Private Shared _LOGGER As EventLog
        Dim connection As SqlCommand


        Public Overridable Function Clone() As Object Implements System.ICloneable.Clone
            Return New B
        End Function

        Public Function Sensible01(ByVal param As TextBox) As String

            Dim s As New B
            Return s.ToString

        End Function

        Public Function Sensible02(ByVal param As TextBox) As String

            Dim s As String
            s = param.Text
            Return s.ToString

        End Function

        Public Sub BD_SECURITY_TDXSS(ByVal userName As TextBox, ByVal response As HttpResponse, ByVal XssText As TextBox)
            userName.Text = XssText.Text 'INV
            response.Write("Welcome, ")
            userName.Text = Validate(userName.Text) 'VALIDO
            response.Write(userName.Text & XssText.Text) ' VIOLATION 
            response.Write(Environment.NewLine)
            userName.Text = userName.Text
        End Sub

        Private Function Validate(strValidate As String) As String
            Return strValidate
        End Function

        Public Sub doGet(ByVal userName As TextBox)
            Dim user = userName.Text
            Dim filter = "(uid=" + user + ")"

            Dim entry As New DirectoryEntry(filter)
            '' Create a DirectorySearcher object.
            Dim searcher As New DirectorySearcher(entry) ' VIOLATION 
            ' ... 
            For Each res As SearchResult In searcher.FindAll()
                ' ... 
            Next
        End Sub


        Public Shared Sub MainAssembly()
            Dim assem As Assembly = Reflection.Assembly.GetExecutingAssembly()

            Console.WriteLine("Assembly Full Name:")
            Console.WriteLine(assem.FullName)

            ' The AssemblyName type can be used to parse the full name.
            Dim assemName As AssemblyName = assem.GetName()
            Console.WriteLine(vbLf + "Name: {0}", assemName.Name)
            Console.WriteLine("Version: {0}.{1}", assemName.Version.Major, _
                assemName.Version.Minor)

            Console.WriteLine(vbLf + "Assembly CodeBase:")
            Console.WriteLine(assem.CodeBase)

            ' Create an object from the assembly, passing in the correct number
            ' and type of arguments for the constructor.
            Dim o As Object = assem.CreateInstance("Example", False, _
                BindingFlags.ExactBinding, Nothing, _
                New Object() {2}, Nothing, Nothing)

            ' Make a late-bound call to an instance method of the object.    
            Dim m As MethodInfo = assem.GetType("Example").GetMethod("SampleMethod")
            Dim ret As Object = m.Invoke(o, New Object() {42})
            Console.WriteLine("SampleMethod returned {0}.", ret)

            Console.WriteLine(vbCrLf & "Assembly entry point:")
            Console.WriteLine(assem.EntryPoint)

        End Sub

        Public Function BD_SECURITY_TDCMD(ByVal storyName As TextBox, ByVal storyContents As TextBox) As String

            storyName.Text = Validate(storyName.Text)
            storyName.Text = storyContents.Text

            Dim appHome As String = Environment.GetEnvironmentVariable("APPHOME")
            Dim cmd As String = appHome + "INITCMD"
            Process.Start(cmd)

            'Lock typeof(B)

            Return String.Empty

        End Function

        Public Function TDLOG(ByVal request As HttpRequest) As Integer
            Dim logName As String = request("val")

            Try
                Return logName
            Catch ex As Exception
                EventLog.CreateEventSource("applicationName", logName) ' VIOLATION 
                Return 0
            End Try
        End Function


        Public Function BD_SECURITY_TDFNAMES(ByVal storyName As TextBox, ByVal storyContents As TextBox) As String

            Dim fileName As String = storyName.Text

            Using myStreamWriter As StreamWriter = File.CreateText(fileName) ' File name injection 
                myStreamWriter.Write(storyContents)
            End Using

            Dim a As File

            Using myStreamWriter As StreamWriter = a.CreateText(fileName) ' File name injection 
                myStreamWriter.Write(storyContents)
            End Using

            Return String.Empty

        End Function

        Public Shared Function openFile(ByVal path As String, Text1 As TextBox) As Stream
            Try


                Dim Sens As String = path.ToString  'Dato Sensibile path.tostring
                Dim Ass As Assembly

                MsgBox(Ass)

                MsgBox(Sens)

                Return File.OpenRead(Text1.Text)

            Catch ex As Exception
                Console.WriteLine(ex.ToString()) ' VIOLATION 
                Return Nothing
            End Try

        End Function

        Public Sub qux()

            'TODO

            Dim rsa As New RSACryptoServiceProvider()
            rsa.KeySize = 4096 ' violation
            ' rsa key size remains 1024

            Dim dsa As New DSACryptoServiceProvider()
            dsa.KeySize = 512 ' violation
            '    ' rsa key size remains 1024

            If rsa.KeySize = 4000 Then
            End If

            'if rsa.keySize = 4000 then
            'end if

            Dim netCred1 As New System.Net.NetworkCredential("username", "password") ' VIOLATION
            Dim netCred As New System.Net.NetworkCredential
            netCred.Password = "ooo"
            netCred.UserName = "ooo"

            Dim viol As New Random() ' VIOLATION

            'FIXME
        End Sub

        Private Sub checkPasswd(passwd As SecureString, passwordTemplate As SecureString)

            Dim keyMethod As New DESCryptoServiceProvider() ' VIOLATION

            Dim passwdPtr As IntPtr = Marshal.SecureStringToBSTR(passwd)
            Dim passwdStr As String = Marshal.PtrToStringUni(passwdPtr)      ' violation
            Dim templatePtr As IntPtr = Marshal.SecureStringToBSTR(passwordTemplate)
            Dim templateStr As String = Marshal.PtrToStringUni(templatePtr)  ' violation

            Dim security As New SecurityPermission(SecurityPermissionFlag.SkipVerification)
            security.Deny()


        End Sub

        Public Sub MilliSecond()
            Dim millis As Integer = System.DateTime.Now.Millisecond ' VIOLATION
            Dim rng As Random = New System.Random(millis)
        End Sub





        Public Sub BD_SECURITY_TDLDAP(ByVal userName As TextBox)
            Dim user = userName.Text
            Dim filter = "(uid=)" + user + ")"
            Dim searcher As DirectorySearcher = New DirectorySearcher(filter) ' VIOLATION 
            ' ... 
            For Each res As SearchResult In searcher.FindAll()
                ' ... 
            Next
        End Sub

        Public Sub SEL_SPLAT()
            Dim selSplat As String = "SELECT * FROM PIPPO"
        End Sub

        Public Function getConnection() As SqlConnection
            Return New SqlConnection(Environment.GetEnvironmentVariable("CONNECTION")) ' VIOLATION 
        End Function

        Public Sub BD_SECURITY_TDSQL(ByVal userName As TextBox, ByVal password As TextBox, ByVal connection As SqlConnection)

            Dim queryString As String = "SELECT user_id, user_class, rights FROM users WHERE " + _
                                              "user_name = '" + userName.Text + "' and password = '" + _
                                              password.Text + "'"
            Dim command As SqlCommand = New SqlCommand(queryString, connection) ' VIOLATION 
            Dim reader As SqlDataReader = command.ExecuteReader()

            Try
                If reader.Read() Then
                    ' user was found, authenticate using data received 
                Else
                    ' no user info was found, report incorrect login and  
                    ' show relogin form 
                End If
            Catch ex As Exception
                ' process necessary exceptions 
                'Catch Senza Logger
            Finally
                reader.Close()
            End Try

        End Sub

        Public Function Splat() As String
            Return "Select * from pippo"
        End Function

        Dim _m1 As String

        Public Overrides Function Equals(a As Object) As Boolean
            If a Is Nothing Then
                Return False
            End If

            If a.GetHashCode() <> GetHashCode() Then
                Return False
            End If

            Return (a.GetHashCode() = GetHashCode())

        End Function


        Public Sub CS_SEC_CRIF()

            Dim reader As SqlDataReader = connection.ExecuteReader

            reader.Close()

            Try

                Try

                Catch ex As Exception
                    'Catch Senza Logger
                Finally

                End Try

            Catch ex As Exception

            End Try

            Try

            Catch ex As Exception
                Logger("")
            Finally

            End Try


        End Sub

        Public Sub TryCatch()
            Try

            Catch ex As Exception
                Throw ex
            Finally

            End Try
        End Sub
        Public Sub TryCatch1()
            Try

            Catch ex As Exception

            Finally

            End Try
        End Sub
        Public Sub CS_SEC_CRIF1()

            Dim reader As SqlDataReader = connection.ExecuteReader

            Try

                Try

                Catch ex As Exception

                Finally

                End Try

            Catch ex As Exception

            End Try


            Try

            Catch ex As Exception
            Finally

            End Try


        End Sub

        Public Sub CS_SEC_CRIF2()

            Dim reader As SqlDataReader = connection.ExecuteReader

            Try

                Try

                Catch ex As Exception

                Finally

                End Try

            Catch ex As Exception

            End Try


            Try
                reader.Close()
            Catch ex As Exception
            Finally

            End Try


        End Sub


        Public Sub CS_SEC_CDBC()

            Dim connection As SqlConnection
            Dim connectionGood As SqlConnection


            connection.Open()
            connectionGood.Open()

            Try

                Try

                Catch ex As Exception

                Finally
                    connectionGood.Close()
                End Try

            Catch ex As Exception

            End Try


            Try
                connection.Close()
            Catch ex As Exception
            Finally

            End Try




        End Sub

        Public Sub saveStory(ByVal storyName As TextBox, ByVal storyContents As TextBox)
            Dim fileName As String = storyName.Text

            Using myStreamWriter As StreamWriter = File.CreateText(fileName) ' File name injection 
                myStreamWriter.Write(storyContents)
            End Using
        End Sub



        Public Sub BD_SECURITY_TDRESP(ByVal userName As TextBox, ByVal response As HttpResponse)
            Dim name As String = userName.Text
            response.AppendCookie(New HttpCookie("name", name)) ' VIOLATION 
        End Sub

        Private Sub DBConnect()
            Dim connectionString As String = "Data Source=myServerAddress;Initial Catalog=myDataBase;User Id=myUsername;Password=myPassword;" ' VIOLATION
            Using connection As New SqlConnection()
                connection.ConnectionString = connectionString
                ' open connection
            End Using
            ' code
        End Sub



        Sub PEO(ByVal FileName As String, ByVal FileSize As Int16)
            Try
                Dim str As StreamReader = New StreamReader(New FileStream(FileName, FileMode.Open, FileAccess.Read))
            Catch e As IOException
                Console.WriteLine(e.ToString())        'VIOLATION
            End Try
        End Sub


        Protected Overrides Sub Finalize()
            'EXCEPT_TID
            Throw New Exception() ' VIOLATION       
        End Sub

        Public Sub PBCOnsoleWrite()
            System.Console.WriteLine("result is : ") ' VIOLATION
            '...
        End Sub

        Public Sub Main()
            System.Console.WriteLine("result is : ")
            '...
        End Sub

        Public Sub Show()
            System.Console.WriteLine("result is : ")
            '...
        End Sub

        Public Sub Verbose()
            System.Console.WriteLine("result is : ")
            '...
        End Sub


        Public Shared Sub SEC_ACPST_WITHFIX()
            Try
                Dim line As String = System.Console.In.ReadLine()
                ' ...
            Catch ex As IOException
                Console.WriteLine(ex.StackTrace) ' VIOLATION

            End Try
        End Sub


        Public Sub SEC_ACWFB(ByVal source As String, ByVal target As String, ByVal sum As Long)


            Console.WriteLine("Transform from: " + source + " to " + target + " sum: " + sum + " $")
            Dim success As Boolean = False

            Try
                success = True
            Finally                                     ' VIOLATION 
            End Try

        End Sub

        Public Function ALBM(ByVal typeName1 As TextBox) As Type

            Dim TypeName As String = typeName1.Text

            Return Type.GetType(TypeName) ' violation


        End Function

        Public Shared Function foo() As String
            Dim sr As System.IO.TextReader = CType(System.IO.File.OpenText("C:\\temp\\SRID.csv"), System.IO.TextReader)
            Dim line As String = ""

            line = sr.ReadLine()               ' VIOLATION
            line += "my addition to the line"

            Return line
        End Function

        Public Shared Function WrapperFoo() As String
            Dim sr As System.IO.TextReader = CType(System.IO.File.OpenText("C:\\temp\\SRID.csv"), System.IO.TextReader)
            Dim line As String = ""

            line = sr.ReadLine()               ' VIOLATION
            line += "my addition to the line"

            Return line
        End Function

        Public Sub SecurityManager()

            System.Security.SecurityManager.SecurityEnabled = False

        End Sub

        Public Sub SecurityManager2()

            Dim prova As System.Security.SecurityManager
            prova.SecurityEnabled = False

        End Sub

		' Dead Code 
		public sub Dead_1(ByVal sum As Long)
		 
			try  
				Console.WriteLine("Hello")
				Catch ex As IOException
                
			End Try
			return
			' Unused Label
			LabelDead:
			Console.WriteLine("unreachable")
		end sub
		
		public sub Dead_2()
		
			try 
			end try
			Console.WriteLine("Hello")
			if (true) then return
			Console.WriteLine("unreachable")
		end sub
		
		private void Dead_3() {
			try  
				Console.WriteLine("Hello")
				catch ex As IOException
					LabelDead_2:
			end try
			if(false) then return
			LabelDead_3:
				Console.WriteLine("bar")
			goto LabelDead_3
		end sub
		
		public sub Dead_4(byval x as long, byval sDead_4 as string) {
			dim y as long
			while (false) 
				x=3 
			end while
			try  
				Console.WriteLine("Hello")
				catch ex As IOException
					if (false) then  return x
				finally 
			end try
			Console.WriteLine("Hello")
			
			if (true) then
				return
			else
				return
			end if
			Console.WriteLine("unreachable")
		end sub
		
		public sub Dead_5() 
			
			dim bool as boolean = Random.nextBoolean()
			dim booldead as boolean
			if (bool) then
				return
			if (bool or Random.nextBoolean()) then
				Console.WriteLine("World!")
				' Ok
				if (true) then return    ' or false
				Console.WriteLine("doing something")
				LabelDead_4:
				while (false) 
					Console.WriteLine("unreachable")
				end while

				do while (true)
					Console.WriteLine("unreachable")
				loop
			end if
				
			goto LabelDead_4;
			Console.WriteLine("unreachable")
		end sub
		
		public function Dead_6(byval sDead_5 as string, byval s as string) as string
			while (true) 
			end while
			Console.WriteLine("unreachable", s)
			return sDead_5
		end function

    End Class
    Public Shared Sub Logger(log As String)

    End Sub

End Class
