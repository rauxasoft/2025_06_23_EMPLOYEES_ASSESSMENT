package employeesmanagement.presentation.application.controllers;

import java.io.IOException;
import java.text.SimpleDateFormat;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import employeesmanagement.business.model.Employee;
import employeesmanagement.business.services.EmployeeServices;

@WebServlet("/app/employee-form")
public class EmployeeFormServlet extends HttpServlet {
	  
	private EmployeeServices employeeServices = null;
	private SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
	
	@Override
	public void init(ServletConfig config) throws ServletException {
		this.employeeServices = (EmployeeServices) config.getServletContext().getAttribute("employeeServices");
	}
	
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		
		String strEmployeeId = request.getParameter("employeeId");

		if (strEmployeeId == null || strEmployeeId.isBlank()) {
			request.setAttribute("accion", "alta");
		} else {
			try {
				Long employeeId = Long.valueOf(strEmployeeId);
				Employee employee = employeeServices.read(employeeId);
				
				if (employee != null) {
					request.setAttribute("employee", employee);
					request.setAttribute("dateOfJoining", sdf.format(employee.getDateOfJoining()));
					request.setAttribute("accion", "edicion");
				} else {
					response.sendError(HttpServletResponse.SC_NOT_FOUND, "Empleado no encontrado");
					return;
				}
			} catch (NumberFormatException e) {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST, "ID inválido");
				return;
			}
		}

		request.getRequestDispatcher("/WEB-INF/employee-form.jsp").forward(request, response);
	}

}
