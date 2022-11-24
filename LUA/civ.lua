-- create a variable and initialize by some value
local num = 21
local num2 = 20  --CWE563P1
local nameUnused --CWE563P1
local veeeeeeeeeryLooooooooongNaaaaaaaaameeeeeeee  --CWE398LONG
local mysteryMeat = EntityCreate("decoration\\food\\mystery meat.sprite.chain", "Mystery Meat", EntityGetPosition(weirden)) ; coroutine.yield(AsyncPathEntityLinear(mysteryMeat, meatStartPos, meatEndPos, 1500)) ; coroutine.yield(AsyncPathEntityLinear(mysteryMeat, meatEndPos, meatStartPos, 1500)) ; EntityRemove(mysteryMeat)  --CWE388LL
print("The number is : ", num)
-- checking whether the number is even or odd
if (num % 2 == 0) then
-- if num even, then jump to the label even
goto even  --CE10
else
-- if num odd, then jump to the label odd
goto odd   --CE10
end
-- define even label
::even::
while( false ) --CWE570P2
do
print("Number is even.")
end
-- define odd label
::odd::
while( true ) --CWE561P16
do
	print("Number is odd.")
end

	function h(r) --CWE398SHORTME
		 local name = r:parseargs().name or ""
		 r:puts(name)
	end
	
	function sGFDGFSD()  


	end

    local name = ngx.req.get_uri_args().name or ""
    ngx.header.content_type = "text/html"
    local html = string.format([[
     ngx.say("Hello, %s")
     ngx.say("Today is "..os.date())
    ]], name)
    --VIOLAZ 
    loadstring(html)()
    
    local name = cgilua.QUERY.name or ""
    cgilua.htmlheader()
    local html = string.format([[
    <html>
    <body>
    Hello, %s!
    Today is <?=os.date()?>
    </body>
    </html>
    ]], name)
    html = cgilua.lp.translate(html)
    --VIOLAZ
    loadstring(html)()



local luatech = 'CGILua'
local username = cgilua.QUERY.username or 'Unknown username' cgilua.htmlheader() cgilua.put([[]]) 
local name = ngx.req.get_uri_args().name or ""
local handle = io.popen("ls -lart /home/" .. username) 
local textfile = cgilua.QUERY.textfile or 'README'
local template = cgilua.QUERY.template or "default_template" 
local data = handle:read("*a") 

function handle(r)
     local name = r:parseargs().name or ""
     r:puts(name)
	name = htmlescape(name) -- see an example at the end of this paper
	ngx.header.content_type = "text/html"
	--OK name è sanificato da htmlescape
	ngx.say(name)
	--VIOLAZ
	local f = io.open(textfile .. ".txt") 
end

function LUA_01(r)  --CWE561P1

	-- VIOLAZ
	handle:close() 
	cgilua.put(data)

	cgilua.put(username)
	ngx.header.content_type = "text/html"
	-- VIOLAZ
	ngx.say(name)

	cgilua.htmlheader() 
	cgilua.put([[]]) 
	--VIOLAZ
	
	local tmpfile = "../pippo.txt"
	local tmpfile2 = "..\\pluto.txt"
	

	file = io.open (tmpfile, "r"])   -- VIOLAZ
	file = io.open (tmpfile2, "r"])   -- VIOLAZ
	file = io.open ("..\\pluto.txt", "r"])   -- VIOLAZ
	
    ngx.header.content_type = "text/html"
    local file = ngx.req.get_uri_args().file or ""
   --VIOLAZ
    local f = io.open(file..".txt")
    local result = f:read("*a")
    f:close()
    ngx.say(result)

end

	cgilua.htmlheader() 
	--VIOLAZ
	cgilua.handlhelp(template .. ".lp")
	
	--VIOLAZ
	cgilua.lp.include(template..".lp")
	 
	--VIOLAZ
	cgilua.doif(template..".lua")

local u = cgilua.QUERY.username or '' 
local p = cgilua.QUERY.password or ''
local logged = 0 
local mysql = require "luasql.mysql" 
local env = mysql.mysql() 


function handle(r)
        r.content_type = "text/html"
        local username = cgilua.QUERY.username or '' 
        local database, err = r:dbacquire("mysql", "host=localhost,user=user,pass=,dbname=dbname")
        if not err then
           --VIOLAZ
           local sl = 'SELECT * FROM users WHERE username="'..username..'"'
           local results, err = database:query(r,sl)
           -- (...)
           database:close()
        else
           r:puts("Could not connect to the database: " .. err)
        end
		
		local conn = env:connect('mysqldb', 'mysqluser', 'mysqlpass') 
		
    end
	
--VIOLAZ
local conn = env:connect('mysqldb', 'mysqluser', 'mysqlpass') 
cur, err = conn:execute("select * from users where username = '" .. u .. "' and password = '" .. p .. "'")

    function handle(r)
     local user = cgilua.QUERY.username or '' 
     --VIOLAZ
     os.execute("ls -l /home/"..user)
    end


function handle(r)
     local user = cgilua.QUERY.username or '' 
     r.content_type = "text/html"
    --VIOLAZ
     r.headers_out['X-Test'] = user
     r:puts('Some text')
     return apache2.OK
    end
 
    local name = ngx.req.get_uri_args().name or ""
    ngx.header.content_type = "text/html"
    --VIOLAZ
    ngx.redirect("http://www.somehost.com/"..name)

    local user = ngx.req.get_uri_args().user or ""
   --VIOLAZ  c:/test.txt
   -- ip 192.25.36.12
    ngx.header['X-Test'] = user
    ngx.say('Some text')

    local url = cgilua.QUERY.url or ""
    --VIOLAZ
    cgilua.redirect(url)

    …
    local demo = cgilua.QUERY.demo or ""
    --VIOLAZ
    cgilua.header('X-Test',demo)
    cgilua.htmlheader()
	
	dostring (string)
	eval (demo)
	
	function index()
	   --VIOLAZ
		entry({"admin", "iotgoat"}, firstchild(), "IoTGoat", 60).dependent=false}
		--VIOLAZ
		entry({"admin", "iotgoat", "cmdinject"}, template("iotgoat/cmd"), "", 1) }
		--VIOLAZ
		entry({"admin", "iotgoat", "cam"}, template("iotgoat/camera"), "Camera", 2) }
		--VIOLAZ
		entry({"admin", "iotgoat", "door"}, template("iotgoat/door"), "Doorlock", 3) }
		--VIOLAZ
		entry({"admin", "iotgoat", "webcmd"}, call("webcmd")}
	end

	local PASSWORD = "TEST1"
	
	