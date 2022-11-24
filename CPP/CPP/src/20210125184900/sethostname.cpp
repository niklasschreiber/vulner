#define DB_DRIVER "QODBC3"

QSqlDatabase *CreateConnections()
{
if(const char* dbhost = std::getenv("DB_HOST"))  // dbhost is untrusted
        std::cout << "Your DB_HOST is: " << dbhost << '\n';
if(const char* dbname = std::getenv("DB_NAME"))  // dbname is untrusted
        std::cout << "Your DB_NAME is: " << dbname << '\n';
if(const char* dbuser = std::getenv("DB_USER"))  // dbuser is untrusted
        std::cout << "Your DB_USER is: " << dbuser << '\n';
if(const char* dbpasswd = std::getenv("DB_PASSWD"))  // dbpasswd is untrusted
        std::cout << "Your DB_PASSWD is: " << dbpasswd << '\n';
        
// create the default database connection
QSqlDatabase *defaultDB = QSqlDatabase::addDatabase( DB_DRIVER , "MyDataBase");
if ( defaultDB )
    {
    defaultDB->setDatabaseName( dbname ); // CWE 15
    defaultDB->setUserName( dbuser ); // CWE 15
    defaultDB->setPassword( dbpasswd ); // CWE 15
    defaultDB->setHostName( dbhost );  // CWE 15
    if ( ! defaultDB->open() ) 
        { 
        qWarning( "Failed to open books database: " + 
        defaultDB->lastError().driverText() );
        qWarning( defaultDB->lastError().databaseText() );
        return NULL;
        }
    }
return defaultDB;
}