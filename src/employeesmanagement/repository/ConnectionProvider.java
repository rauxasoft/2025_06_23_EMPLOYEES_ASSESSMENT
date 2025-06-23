package employeesmanagement.repository;

import java.sql.Connection;
import java.sql.SQLException;

import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;

public class ConnectionProvider {
	
	private static final String JNDI_NAME = "java:comp/env/jdbc/EmployeeDB";
	private static DataSource DATA_SOURCE;
	
	public static Connection getConnection() throws SQLException {
		
		try {
			
	       if (DATA_SOURCE == null) {
	    	   InitialContext ctx = new InitialContext();
	    	   DATA_SOURCE = (DataSource) ctx.lookup(JNDI_NAME);
	       }
	        
	       return DATA_SOURCE.getConnection();
	       
	    } catch (NamingException e) {
	            throw new SQLException("Not possible to get DataSource from JNDI", e);
	    }
    }
}
