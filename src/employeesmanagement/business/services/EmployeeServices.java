package employeesmanagement.business.services;

import java.util.Optional;

import employeesmanagement.business.model.Employee;
import employeesmanagement.common.Page;

public interface EmployeeServices {

	// Operaciones CRUD
	
	Long create(Employee employee);
	
	Optional<Employee> read(Long employeeId);
	
	void update(Employee employee);
	
	void delete(Long employeeId);
	
	// Obtenión de página
	
	Page<Employee> getPage(int pageNumber, int pageSize, String sortedField, boolean ascending);
	
}
