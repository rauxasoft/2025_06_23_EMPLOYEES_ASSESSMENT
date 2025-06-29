package employeesmanagement.business.services;

import employeesmanagement.business.model.Employee;
import employeesmanagement.common.Page;

public interface EmployeeServices {

	// Operaciones CRUD
	
	Long create(Employee employee);
	
	Employee read(Long employeeId);
	
	void update(Employee employee);
	
	void remove(Long employeeId);
	
	// Obtenión de página
		
	Page<Employee> getPage(int pageNumber, int pageSize, String sortedField, boolean ascending);
	
}
