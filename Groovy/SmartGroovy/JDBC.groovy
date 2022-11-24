// Import the Groovy class required to work with SQL databases.
import groovy.sql.Sql

// Set up database connection properties.
def url = 'jdbc:mysql://mydatabase.com/DatabaseVariable' /* IMPORTANT: must start with jdbc:mysql:// */
def user = 'DatabaseUser'
def password = 'DatabasePassword'
def driver = 'com.mysql.jdbc.Driver'

// Register the MySQL JDBC driver – required for Groovy to send requests to the database.
com.eviware.soapui.support.GroovyUtils.registerJdbcDriver( driver )

// Connect to the SQL instance.
def sql = Sql.newInstance(url, user, password, driver)

// Use the SQL instance.
// ...

// Close the SQL instance.
sql.close()