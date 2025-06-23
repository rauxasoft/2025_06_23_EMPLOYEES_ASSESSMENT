package employeesmanagement.listeners;

import java.time.LocalDate;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import employeesmanagement.business.services.EmployeeServices;
import employeesmanagement.business.services.impl.EmployeeServicesDummyImpl;
import employeesmanagement.business.services.impl.EmployeeServicesImpl;
import employeesmanagement.presentation.api.servlets.config.GsonLocalDateAdapter;
import employeesmanagement.repository.daos.EmployeeDAO;
import employeesmanagement.repository.daos.impl.EmployeeDAOImpl;

@WebListener
public class ServletContextInit implements ServletContextListener {

    @SuppressWarnings("unused")
	@Override
    public void contextInitialized(ServletContextEvent sce)  { 
        
    	final EmployeeDAO employeeDAO = new EmployeeDAOImpl();
    	
    	final EmployeeServicesImpl employeeServices = new EmployeeServicesImpl();
    	employeeServices.setEmployeeDAO(employeeDAO);
    	
    	final EmployeeServices employeeServicesDummyImpl = new EmployeeServicesDummyImpl();
    	
    	final Gson gson = new GsonBuilder()
    		    .registerTypeAdapter(LocalDate.class, new GsonLocalDateAdapter())
    		    .create();
    	
    	sce.getServletContext().setAttribute("employeeServices", employeeServices);
   // 	sce.getServletContext().setAttribute("employeeServices", employeeServicesDummyImpl);
    	
    	sce.getServletContext().setAttribute("gson", gson);
    	
    }
    
    @Override 
    public void contextDestroyed(ServletContextEvent sce)  { 
        
    }
	
}
