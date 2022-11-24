using System.IO;
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

    public class HttpExample
    {
		public void S3ClientBuilderNoncompliant ()
		{
			ProfileCredentialsProvider credentialsProvider = ProfileCredentialsProvider.create();
			Region region = Region.US_EAST_1;
			S3Client s3 = S3Client.builder()
				.region(region)
				.build();
				
			AmazonS3ClientBuilder.standard().withRegion("eu_west_1").build();  //VIOLAZ
			AmazonS3ClientBuilder.standard().withRegion(Regions.EU_WEST_1).build(); //OK

		}
		
		public void S3ClientBuilderCompliant ()
		{
			ProfileCredentialsProvider credentialsProvider = ProfileCredentialsProvider.create();
			Region region = Region.US_EAST_1;
			S3Client s3 = S3Client.builder()
				.region(region)
				.credentialsProvider(credentialsProvider)
				.build();
		}		

		public void S3ClientBuilderRegionCompliant ()
		{
			ProfileCredentialsProvider credentialsProvider = ProfileCredentialsProvider.create();
			Region region = Region.US_EAST_1;
			S3Client s3 = S3Client.builder()
				.region(region)
				.credentialsProvider(credentialsProvider)
				.build();
		}		

		public void S3ClientBuilderRegionNoCompliant ()
		{
			ProfileCredentialsProvider credentialsProvider = ProfileCredentialsProvider.create();
			Region region = Region.US_EAST_1;
			S3Client s3 = S3Client.builder()
				.credentialsProvider(credentialsProvider)
				.build();
		}		

			
		public static void createBucket( S3Client s3Client, String bucketName) {

        try {
			
			S3Client s3 = s3Client.builder()
				.region(region)
				.credentialsProvider(credentialsProvider)
				.build();
				
			
            S3Waiter s3Waiter = s3Client.waiter();
            CreateBucketRequest bucketRequest = CreateBucketRequest.builder()
                .bucket(bucketName)
                .build();

            s3Client.createBucket(bucketRequest);
            HeadBucketRequest bucketRequestWait = HeadBucketRequest.builder()
                .bucket(bucketName)
                .build();

            // Wait until the bucket is created and print out the response.
            WaiterResponse<HeadBucketResponse> waiterResponse = s3Waiter.waitUntilBucketExists(bucketRequestWait);
            waiterResponse.matched().response().ifPresent(System.out::println);
            System.out.println(bucketName +" is ready");

        } catch (S3Exception e) {
            System.err.println(e.awsErrorDetails().errorMessage());
            System.exit(1);
        }
    }
	
        [FunctionName("HttpExample")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = null)] HttpRequest request)
        {
            HttpClient httpClient = new HttpClient(); // VIOLAZ

            var response = await httpClient.GetAsync("https://example.com");
            // rest of the function
        }
    }

    public class HttpExample
    {
        [FunctionName("HttpExample")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = null)] HttpRequest request, IHttpClientFactory clientFactory)
        {
            var httpClient = clientFactory.CreateClient(); //OK
            var response = await httpClient.GetAsync("https://example.com");
            // rest of the function
        }
    }


	public static class AvoidBlockingCalls
	{
		[FunctionName("Foo")]
		public static async Task<IActionResult> Foo([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req)
		{
			// This can lead to thread exhaustion
			string requestBody = new StreamReader(req.Body).ReadToEndAsync().Result;  //VIOLAZ

			// do stuff...
		}
	}
	
	public static class AvoidBlockingCalls
	{
		[FunctionName("Foo")]
		public static async Task<IActionResult> Foo([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req)
		{
			string requestBody = await new StreamReader(req.Body).ReadToEndAsync();  //OK
			// do stuff...
		}
	}
	
public static class HttpExample
    {
        private static readonly int port = 2000;
        private static int numOfRequests = 1;

        [FunctionName("HttpExample")]
        public static async Task<IActionResult> Run( [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = null)] HttpRequest request, ILogger log)
        {
            numOfRequests += 1; // VIOLAZ, modifica un field
            log.LogInformation($"Number of POST requests is {numOfRequests}.");

            string responseMessage = $"HttpRequest was made on port {port}."; // Compliant, state is only read.

            return new OkObjectResult(responseMessage);
        }
		
	
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
		File.Move (g,g3);
		File.Encrypt  ("");
		CacheDependency dep = new CacheDependency(fileName, dt);
	}
	
	RegistryKey rk1 = Registry.ClassesRoot;
	
	 public static void Main() {

        // Create a RegistryKey, which will access the HKEY_CLASSES_ROOT
        // key in the registry of this machine.
        RegistryKey rk = Registry.ClassesRoot;

        // Print out the keys.
        PrintKeys(rk);
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
