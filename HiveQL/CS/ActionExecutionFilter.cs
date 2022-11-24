using APP_Commons_MODEL;
using APP_Commons_MODEL.Exceptions;
using APP_Commons_WFE.JWT;
using System;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;

namespace Test
{

[ServiceContract]
interface IMyService // VIOLAZ
{
  int MyServiceMethod();
}

[ServiceContract]
interface IMyService1
{
  [OperationContract]  //OK
  int MyServiceMethod();
}

[Serializable]
public class Foo
{
    [OnSerializing]
    public void OnSerializing(StreamingContext context) {} // VIOLAZ should be private

    [OnSerialized]
    int OnSerialized(StreamingContext context) {} // VIOLAZ should return void

    [OnDeserializing]
    void OnDeserializing() {} // VIOLAZ should have a single parameter of type StreamingContext

    [OnSerializing]
    public void OnSerializing2<T>(Context context) {} // VIOLAZ should have no type parameters

    [OnDeserialized]
    void OnDeserialized(StreamingContext context, string str) {} // VIOLAZ should have a single parameter of type StreamingContext
}

[PartCreationPolicy(CreationPolicy.Any)] // VIOLAZ
public class FooBar2 : IFooBar
{
	
	static void Main(string[] args)
		{
			Assembly.LoadFrom(...); // VIOLAZ
			Assembly.LoadFile(...); // VIOLAZ
			Assembly.LoadWithPartialName(...); // VIOLAZ
			GC.SuppressFinalize;
			de = new DirectoryEntry("LDAP://ad.example.com:389/ou=People,dc=example,dc=com");
		}
		
		public void Foo()
	{
		var g = new Guid(); // VIOLAZ
		var g3 = new Guid(bytes); //OK
	}
	
	
}

[Export(typeof(IFooBar))]
[PartCreationPolicy(CreationPolicy.Any)]  // OK, preceduta dalla Export
public class FooBar : IFooBar
{
}
	
	[SecurityCritical]
    public class Foo
    {
        [SecuritySafeCritical] // VIOLAZ
        public void Bar()
        {
			
			int v1 = 0;
			bool v2 = false;

			var v3 = !!v1; // VIOLAZ
			var v4 = ~~v2; // VIOLAZ
        }
    }
	[SecuritySafeCritical]
    public class Foo2
    {
        [SecurityCritical] // VIOLAZ
        public void Bar2()
        {
        }
    }
	
internal class MyException : Exception   // VIOLAZ
{
 
}

internal public class MyException1 : Exception   // VIOLAZ
{
 
}

public class JunkFood
{
  public void DoSomething(int i)
  {
    if (this is Pizza) // VIOLAZ
    {
		i = i & -1;
		j = i^0;
		k= i|0;
    } 
    if (this.i is Integer){ //VIOLAZ
	
		try {}
		catch (Exception exc) // VIOLAZ
		{
		}
			
    }
  }
}

	[Export(typeof(ISomeType))]
	public class SomeType // VIOLAZ
	{
	}
	
	[Export(typeof(ISomeType))]
	public class SomeType : ISomeType // VIOLAZ?
	{
		
		static void Main(string[] args)
			{
			  Thread.CurrentThread.Suspend(); // Noncompliant
			  Thread.CurrentThread.Resume(); // Noncompliant
			}
	}
	
    public class Test
    {
       		
		[DllImport("ole32.dll")]
		public static extern int CoInitializeSecurity(IntPtr pVoid, int cAuthSvc, IntPtr asAuthSvc, IntPtr pReserved1,
			RpcAuthnLevel level, RpcImpLevel impers, IntPtr pAuthList, EoAuthnCap dwCapabilities, IntPtr pReserved3);

		static void Main(string[] args)
			{
				var hres1 = CoSetProxyBlanket(null, 0, 0, null, 0, 0, IntPtr.Zero, 0); // Noncompliant
				var hres2 = CoInitializeSecurity(IntPtr.Zero, -1, IntPtr.Zero, IntPtr.Zero, RpcAuthnLevel.None,
				RpcImpLevel.Impersonate, IntPtr.Zero, EoAuthnCap.None, IntPtr.Zero); // Noncompliant
			}

		static void Main2(string[] args)
		{
			System.Reflection.FieldInfo fieldInfo = "";
			SafeHandle handle = (SafeHandle)fieldInfo.GetValue(rKey);
			IntPtr dangerousHandle = handle.DangerousGetHandle();  // Noncompliant
		}

    }
}
