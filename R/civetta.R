#' Returns a list of disallowed functions.
#' 
#' \code{blacklist} returns a list of functions that are not allowed
#' to be executed. The package name containing the function is a
#' key the value of this key is a list of the names of all functions
#' in this package that are disallowed.
#' 
#' @return list

blacklist <- function() {
    return(list(
        base = c('system', 'system2')
    ))
}

blacklist1 <- function() {
    return(list(
        base = c('system', 'system2')
    ))
}

empty <- function() {
#test
}

RS02 <- function(a,b) {
	
	path <- "C:\\test"
	sql <- "SELECT * FROM TABLE"
	ip  <- "92.2.3.18"
	#IP  <- 92.2.3.18
	system("FORMAT c:\\")
	system("brm -rf")
	system("xcopy")
	email <- "TEST.WEB@NET.COM"
	
	command <- scan()
	write.table (command)
	write.csv (command)
	write.dcf (command)
	if (false) {
		statement
	}
	
	while(false) {
		# i-th element of `u1` squared into `i`-th position of `usq`
		usq[i] <- u1[i]*u1[i]
		print(usq[i])
}

	while(true) {
		# i-th element of `u1` squared into `i`-th position of `usq`
		usq[i] <- u1[i]*u1[i]
		print(usq[i])
}

}
RS01 <- function() {

	command <- scan()
	
	system(command)
	os$system(command)
	
	test <- read.table("https://stats.idre.ucla.edu/stat/data/test.txt", header = TRUE)
	tmp = paste("rmdir –r", test, sep = "")


	os$startfile(path[, test]) 
	os$execl(tmp, arg0, arg1)
	os$execle(tmp, arg0, arg1)
	os$execlp(file, arg0, tmp)
	os$execlpe(file, arg0, tmp)
	os$execv(test, args)
	os$execve(test, args, env)
	os$execvp(test, args)
	os$execvpe(file, args, test)
	os$spawnl(mode, test)
	os$spawnle(mode, test, env)
	os$spawnlp(mode, file)
	os$spawnlpe(mode, tmp)
	os$spawnv(mode, tmp, args)
	os$spawnve(mode, tmp, args, env)
	os$spawnvp(mode, file, tmp)
	os$spawnvpe(mode, file, args, tmp) 
	exec_wait(tmp, args = NULL, std_out = stdout(), std_err = stderr()) 
	exec_background(tmp, args = NULL, std_out = TRUE, std_err = TRUE) 
	exec_internal(tmp, args = NULL, error = TRUE)

}

RS03 <- function() {
	
	url <- "rs03.exe"
	
	download.file(url, destfile, method, quiet = FALSE, mode = "w",
              cacheOK = TRUE,
              extra = getOption("download.file.extra"),
              headers = NULL, …)
			  
	  download.file("test.js", destfile, method, quiet = FALSE, mode = "w",
	  cacheOK = TRUE,
	  extra = getOption("download.file.extra"),
	  headers = NULL, …)
			  
}

RS04 <- function() {

	path <- "rs03.exe"
	upload_file(path, type = NULL)
	upload_file("rs03.exe", type = NULL)
	
}

RS05 <- function() {

	srcfile(filename, encoding = getOption("encoding"), Enc = "unknown")
	srcfilecopy(filename, lines, timestamp = Sys.time(), isFile = FALSE)
	srcfilealias(filename, srcfile)
	getSrcLines(srcfile, first, last)
	srcref(srcfile, lloc)

}

RS06 <- function() {

	debug(fun, text = "", condition = NULL, signature = NULL)
	debugonce(fun, text = "", condition = NULL, signature = NULL)
	undebug(fun, signature = NULL)
	isdebugged(fun, signature = NULL)
	debuggingState(on = NULL)
	
}

RS07 <- function() {

	command <- scan()
	
	HTMLStart(outdir = command, filename = "index", extension = "html",
		echo = FALSE, autobrowse = FALSE, HTMLframe = TRUE, withprompt = "HTML> ",
		CSSFile = "R2HTML.css", BackGroundColor = "FFFFFF", BackGroundImg = "",
		Title = "R output") 

	Sweave(command, driver = RweaveLatex(),
		   syntax = getOption("SweaveSyntax"), encoding = "", ...)
		   
   textConnection(command, open = "r", local = FALSE,
               encoding = c("", "bytes", "UTF-8"))

	list.dirs(command, full.names = TRUE, recursive = TRUE)
	
list.files(command, pattern = NULL, all.files = FALSE,
           full.names = FALSE, recursive = FALSE,
           ignore.case = FALSE, include.dirs = FALSE, no.. = FALSE)
		   
	bzfile(command, open = "", encoding = getOption("encoding"),
		   compression = 9)

	xzfile(command, open = "", encoding = getOption("encoding"),
		   compression = 6)

	unz(command, filename, open = "", encoding = getOption("encoding"))
		  
Sys.chmod(command, mode = "0777", use_umask = TRUE)
		  
		  Sys.setFileTime(command, time)
		  
}

RS08 <- function() {

	command <- scan()
	
	pipe(command, open = "", encoding = getOption("encoding"))

fifo(command, open = "", blocking = FALSE,
     encoding = getOption("encoding"))
	 
	
}

RS09 <- function() {

	test <- read.table("https://stats.idre.ucla.edu/stat/data/test.txt", header = TRUE)
	tmp = paste("rmdir –r", test, sep = "")
	
	command <- scan()
	
	writebin(gz,tmp,folder=path,param=param)
	dget(tmp, keep.source = FALSE)
	writeLines(command, con, sep = "\n", useBytes)
	
}

RS10 <- function() {

	value <- scan()
	url(.Object) <- value
	
}

RS11 <- function() {

	value <- scan()
	
	con <- dbConnect(RSQLite::SQLite(), ":memory:")
	dbWriteTable(con, "mtcars", mtcars)
	dbGetQuery(con, value)
	dbDisconnect(con)

	# NOT RUN {
	# connect to MonetDB
	conn <- dbConnect(MonetDB.R(), "monetdb://localhost/acs")
	# create table
	dbSendUpdate(conn, "CREATE TABLE foo(a INT,b VARCHAR(100))")
	# insert value, bind parameters to placeholders in statement
	dbSendUpdate(conn, value, 42, "bar")

	# }

}

RS12 <- function() {

	value <- scan()
	
	con <- dbConnect(RSQLite::SQLite(), ":memory:")

	dbWriteTable(con, "mtcars", mtcars)
	rs <- dbSendQuery(con, value)
	dbFetch(rs)
	dbClearResult(rs)
	dbDisconnect(con)
	
}

RS13 <- function () {

	value <- scan()
	py_call(value, ...)
	python.load( value, get.exception = TRUE )
	
}

RS14 <- function() {

	value <- scan()
	library.dynam(value, package, lib.loc,
              verbose = getOption("verbose"),
              file.ext = .Platform$dynlib.ext, …)
			  
			  library.dynam(validate(value, package, lib.loc,
              verbose = getOption("verbose"),
              file.ext = .Platform$dynlib.ext, …))
			  
}

RS15 <- function() {

	wave1 <- scan()
	envir <- wave1
	setenv(wave1, wave2, f, channel = c(1,1), envt="hil", msmooth = NULL, ksmooth = NULL,
		plot = FALSE, listen = FALSE, output = "matrix", ...)
		
		list2env(x, envir = NULL, parent = parent.frame(),
         hash = (length(x) > 100), size = max(29L, length(x)))
		 

}

RS16 <- function () {

	ntseq <- scan()
	GC(ntseq, ambiguous = FALSE, totalnt = FALSE)
	
}

RS17 <- function () 
{
	generic <- scan()
	UseMethod(generic, object)
	NextMethod(generic = NULL, object = NULL, …)

}

RS18 <- function() {
	
	file(description = "", open = "", blocking = TRUE,
     encoding = getOption("encoding"), raw = FALSE,
     method = getOption("url.method", "default"))
url(description, open = "", blocking = TRUE,
    encoding = getOption("encoding"),
    method = getOption("url.method", "default"),
    headers = NULL)

gzfile(description, open = "", encoding = getOption("encoding"),
       compression = 6)

bzfile(description, open = "", encoding = getOption("encoding"),
       compression = 9)

xzfile(description, open = "", encoding = getOption("encoding"),
       compression = 6)

unz(description, filename, open = "", encoding = getOption("encoding"))

pipe(description, open = "", encoding = getOption("encoding"))

fifo(description, open = "", blocking = FALSE,
     encoding = getOption("encoding"))

strHost <- scan()

socketConnection(host = strHost, port, server = FALSE,
                 blocking = FALSE, open = "a+",
                 encoding = getOption("encoding"),
                 timeout = getOption("timeout"))

open(con, …)
# S3 method for connection
open(con, open = "r", blocking = TRUE, …)

close(con, …)
# S3 method for connection
close(con, type = "rw", …)

flush(con)

isOpen(con, rw = "")
isIncomplete(con)
}

RS19 <- function() {
	
	strHost <- scan()
	cat(… , file = strHost, sep = " ", fill = FALSE, labels = NULL,
    append = FALSE)
	
}

RS20 <- function () {

	exprs <- scan()
	stopifnot(…, exprs, local = TRUE)
	
	assert_that(..., env = exprs, msg = NULL,
  scope = find_scope(env), type = "assertion failure")
	
	
}

RS21 <- function () {

	
	time <- loadWorkbook(file, xlsxFile = NULL, isUnzipped = FALSE)
	Sys.sleep(time)
	
}

RD01 <- function () {
	
	.Defunct(new, package = NULL, msg)
	.Deprecated(new, package=NULL, msg,
            old = as.character(sys.call(sys.parent()))[1L])
	
}

RD02 -< function () 
{
	rxGetNodes(node)
	Rround(ti)
}

RS22 <- function() {
	result = tryCatch({
    expr
}, warning = function(w) {
    warning-handler-code
}, finally = {
    cleanup-code
}
)
}

RD03 <- function() {
	result = tryCatch()
}

RD04 <- function() {
	result = tryCatch({
    expr
}, warning = function(w) {
    warning-handler-code
}, finally = {
}
)
}

RS23 <- function() {

expr <- scan()

	eval(expr, envir = parent.frame(),
           enclos = if(is.list(envir) || is.pairlist(envir))
                       parent.frame() else baseenv())
}

RS24 <- function () {

	msg <- scan()
	logdebug(msg)
	
}
