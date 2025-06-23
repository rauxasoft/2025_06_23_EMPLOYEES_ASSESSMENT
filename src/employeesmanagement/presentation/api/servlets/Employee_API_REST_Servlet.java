package employeesmanagement.presentation.api.servlets;

import java.io.BufferedReader;
import java.io.IOException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.gson.Gson;

import employeesmanagement.business.exceptions.BusinessException;
import employeesmanagement.business.model.Employee;
import employeesmanagement.business.services.EmployeeServices;
import employeesmanagement.common.Page;

@WebServlet("/api/employees/*")
public class Employee_API_REST_Servlet extends HttpServlet {
	   
	private EmployeeServices employeeServices = null;
	private Gson gson = null;
	
	@Override
	public void init(ServletConfig config) throws ServletException {
		this.employeeServices = (EmployeeServices) config.getServletContext().getAttribute("employeeServices");
		this.gson = (Gson) config.getServletContext().getAttribute("gson");
	}

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		
		int pageSize = Integer.parseInt(request.getParameter("pagesize")) ;
		int pageNumber = Integer.parseInt(request.getParameter("pagenumber"));
		String sortField = request.getParameter("sortfield");
		boolean ascending = "asc".equals(request.getParameter("sortdir"));
				
		Page<Employee> page = employeeServices.getPage(pageNumber, pageSize, sortField, ascending);
			
		response.setContentType("application/json");
		response.setCharacterEncoding("UTF-8");
		response.getWriter().write(gson.toJson(page));
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		
		try {
	      	
	        BufferedReader reader = request.getReader();
	        Employee nuevoEmpleado = gson.fromJson(reader, Employee.class);

	        employeeServices.create(nuevoEmpleado);

	        response.setStatus(HttpServletResponse.SC_CREATED); // 201
	        
	    } catch (BusinessException e) {
	        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
	        response.getWriter().write(e.getMessage());
	        
	    } catch (Exception e) {
	        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
	        response.getWriter().write("Unexpected error");
	    }
	}

	@Override
	protected void doPut(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
	    
		try {
	       
	        BufferedReader reader = request.getReader();
	        Employee empleado = gson.fromJson(reader, Employee.class);

	        if (empleado.getEmployeeId() == null) {
	            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
	            response.getWriter().write("employee ID is missing");
	            return;
	        }

	        employeeServices.update(empleado);

	        response.setStatus(HttpServletResponse.SC_OK);
	        response.getWriter().write("Employee successfully updated");
	        
	    } catch (BusinessException e) {
	        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
	        response.getWriter().write(e.getMessage());
	        
	    } catch (Exception e) {
	        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
	        response.getWriter().write("Unexpected error");
	        e.printStackTrace();
	    }
	}

	@Override
	protected void doDelete(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		
		String pathInfo = request.getPathInfo(); // e.g. "/123"

	    if (pathInfo == null || pathInfo.equals("/") || pathInfo.length() <= 1) {
	        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
	        response.getWriter().write("employee ID is missing");
	        return;
	    }

	    try {
	        Long id = Long.valueOf(pathInfo.substring(1));
	        
	        employeeServices.delete(id);
	        
	        // no accedo al PrintWriter porque este ya devuelve un body, lo cual es incoherente con NO CONTENT
	        
	        response.setStatus(HttpServletResponse.SC_NO_CONTENT);

	    } catch (BusinessException e) {
	        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
	        response.getWriter().write(e.getMessage());

	    } catch (Exception e) {
	        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
	        response.getWriter().write("Unexpected error");
	        e.printStackTrace();
	    }
	}

}