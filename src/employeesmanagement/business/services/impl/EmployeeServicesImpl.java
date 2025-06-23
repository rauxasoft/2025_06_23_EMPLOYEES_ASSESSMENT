package employeesmanagement.business.services.impl;

import java.util.Objects;
import java.util.Optional;
import java.util.stream.Stream;

import employeesmanagement.business.exceptions.BusinessException;
import employeesmanagement.business.model.Employee;
import employeesmanagement.business.services.EmployeeServices;
import employeesmanagement.common.Page;
import employeesmanagement.repository.daos.EmployeeDAO;
import employeesmanagement.repository.exceptions.PersistenceException;

public class EmployeeServicesImpl implements EmployeeServices{

	private EmployeeDAO employeeDAO;
	
	public void setEmployeeDAO(EmployeeDAO employeeDAO) {
		this.employeeDAO = employeeDAO;
	}
	
	@Override
	public Long create(Employee employee) {
		
		if(employee.getEmployeeId() != null) {
			throw new BusinessException("The employee already has an identificator. For creating a new employee the id has to be null");
		}
		
		if(missingFields(employee)) {
			throw new BusinessException("All the fields are required");
		}
		
		if(emailIsNotWellFormed(employee.getEmail())) {
			throw new BusinessException("The email is not well formed");
		}
		
		if(employeeDAO.existsEmail(employee.getEmail())) {
			throw new BusinessException("The email is already in use");
		}
		
		Long id = employeeDAO.create(employee);
		
		return id;
	}

	@Override
	public Optional<Employee> read(Long employeeId) {
		return employeeDAO.findById(employeeId);
	}

	@Override
	public void update(Employee employee) {
		
		try {
		
			Long employeeId = employee.getEmployeeId();
		
			if(employeeId == null) {
				throw new BusinessException("To update an employee, it must have an ID");
			}
		
			boolean exists = employeeDAO.existsById(employeeId);
		
			if(!exists) {
				throw new BusinessException("Employee" + employeeId + "does not exist. It cannot be deleted.");
			}
		
			if(missingFields(employee)) {
				throw new BusinessException("All the fields are required");
			}
		
			if(emailIsNotWellFormed(employee.getEmail())) {
				throw new BusinessException("The email is not well formed");
			}
		
			employeeDAO.update(employee);
		
		} catch(PersistenceException e) {
			throw new BusinessException(e.getMessage());
		}
		
	}

	@Override
	public void delete(Long employeeId) {
		
		boolean exists = employeeDAO.existsById(employeeId);
		
		if(!exists) {
			throw new BusinessException("Employee" + employeeId + "does not exist. It cannot be deleted.");
		}
		
		employeeDAO.delete(employeeId);
	}

	@Override
	public Page<Employee> getPage(int pageNumber, int pageSize, String sortedField, boolean ascending) {
		return employeeDAO.findPage(pageNumber, pageSize, sortedField, ascending);
	}
	
	// **************************************************************************
	//
	// Private Methods
	//
	// ***************************************************************************
	
	private boolean emailIsNotWellFormed(String email) {
		
		if (email == null || email.isBlank()) return false;

	    String regex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$";
	    return !email.toUpperCase().matches(regex);
	}
	
	private boolean missingFields(Employee employee) {
		
		return Stream.of(employee.getName(), employee.getEmail(), employee.getPhoneNumber(), employee.getDateOfJoining())
                .anyMatch(Objects::isNull);
	}

}
