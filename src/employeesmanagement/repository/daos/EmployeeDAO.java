package employeesmanagement.repository.daos;

import java.util.Optional;

import employeesmanagement.business.model.Employee;
import employeesmanagement.common.Page;
import employeesmanagement.repository.exceptions.PersistenceException;

public interface EmployeeDAO {

	Long create(Employee employee) throws PersistenceException;
	
	Optional<Employee> findById(long employeeId) throws PersistenceException;
	
	void update(Employee employee) throws PersistenceException;

    void delete(long employeeId) throws PersistenceException;

    Page<Employee> findPage(int pageNumber, int pageSize, String orderBy, boolean ascending) throws PersistenceException;
    
    boolean existsById(Long employeeId);
    
    boolean existsEmail(String email);
 
}
