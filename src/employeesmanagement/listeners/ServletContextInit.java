package employeesmanagement.listeners;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

import employeesmanagement.business.services.impl.EmployeeServicesImpl;

@WebListener
public class ServletContextInit implements ServletContextListener {

	@Override
    public void contextInitialized(ServletContextEvent sce)  {
    	
        EmployeeServicesImpl employeeServices = new EmployeeServicesImpl();
       
        sce.getServletContext().setAttribute("employeeServices", employeeServices);

    }
    
    @Override 
    public void contextDestroyed(ServletContextEvent sce)  { 
        
    }
	
}
