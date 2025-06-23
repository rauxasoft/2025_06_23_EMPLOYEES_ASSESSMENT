package employeesmanagement.business.services.impl;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.TreeMap;
import java.util.stream.Collectors;

import employeesmanagement.business.exceptions.BusinessException;
import employeesmanagement.business.model.Employee;
import employeesmanagement.business.services.EmployeeServices;
import employeesmanagement.common.Page;

public class EmployeeServicesDummyImpl implements EmployeeServices{

	private TreeMap<Long, Employee> EMPLOYEE_DB = new TreeMap<>();
	
	public EmployeeServicesDummyImpl() {
		init();
	}
	
	@Override
	public Long create(Employee employee) {
		
		if(employee.getEmployeeId() != null) {
			throw new BusinessException("The employee already has an identificator. For creating a new employee the id has to be null");
		}
		
		if(employee.getPhoneNumber() == null || employee.getDateOfJoining() == null) {
			// TODO
			throw new BusinessException("All the fields are required. XXX, XXX and XXX are missing");
		}
		
		if(emailAlreadyExists(employee.getEmail())) {
			throw new BusinessException("The email already exists!");
		}
		
		if(emailIsNotWellFormed(employee.getEmail())) {
			throw new BusinessException("The email is not well formed");
		}
		
		// Validar que todos los campos sean requeridos
		
		Long newKey = EMPLOYEE_DB.isEmpty() ? 1L : EMPLOYEE_DB.lastKey() + 1;
		employee.setEmployeeId(newKey);
		EMPLOYEE_DB.put(newKey, employee);
		
		return newKey;
	}

	@Override
	public Optional<Employee> read(Long employeeId) {
		return Optional.ofNullable(EMPLOYEE_DB.get(employeeId));
	}

	@Override
	public void update(Employee employee) {
		
		Long employeeId = employee.getEmployeeId();
		
		if(employeeId == null) {
			throw new BusinessException("The employee id is null. Is not possible to update");
		}
		
		boolean existe = EMPLOYEE_DB.containsKey(employeeId);
		
		if(!existe) {
			throw new BusinessException("No exists de employee with ID [" + employeeId + "]");
		}
	
		EMPLOYEE_DB.replace(employeeId, employee);
	
	}

	@Override
	public void delete(Long employeeId) {
		EMPLOYEE_DB.remove(employeeId);
	}

	@Override
	public Page<Employee> getPage(int pageNumber, int pageSize, String sortedField, boolean ascending) {
		
		int totalElements = EMPLOYEE_DB.size();
	    int totalPages = (int) Math.ceil((double) totalElements / pageSize);

	    Map<String, Comparator<Employee>> comparators = Map.of(
	        "id", Comparator.comparing(Employee::getEmployeeId),
	        "name", Comparator.comparing(Employee::getName, String.CASE_INSENSITIVE_ORDER),
	        "email", Comparator.comparing(Employee::getEmail, String.CASE_INSENSITIVE_ORDER),
	        "phone", Comparator.comparing(Employee::getPhoneNumber),
	        "date", Comparator.comparing(Employee::getDateOfJoining)
	    );

	    Comparator<Employee> comparator = comparators.getOrDefault(
	    		sortedField != null ? sortedField.toLowerCase() : "id",
	        comparators.get("id")
	    );

	    if (!ascending) {
	        comparator = comparator.reversed();
	    }

	    List<Employee> sortedList = EMPLOYEE_DB.values()
	        .stream()
	        .sorted(comparator)
	        .collect(Collectors.toList());

	    int fromIndex = (pageNumber - 1) * pageSize;
	    int toIndex = Math.min(fromIndex + pageSize, totalElements);

	    List<Employee> pageContent = new ArrayList<>();
	    if (fromIndex < totalElements) {
	        pageContent = sortedList.subList(fromIndex, toIndex);
	    }

	    return new Page<>(pageContent, pageNumber, pageSize, totalElements, totalPages);
	}
	
	// **************************************************************************
	//
	// Private Methods
	//
	// ***************************************************************************
	
	private void init() {
		
		for(long i = 1; i <= 100; i++) {
			
			Employee employee = new Employee(i, "nombre_" + i, "email@email" +  i + ".com" , "93 221 22 34", LocalDate.of(2024, 10, 25));
			
			EMPLOYEE_DB.put(i, employee);
			
		}
	}
	
	private boolean emailAlreadyExists(String email) {
		
		return EMPLOYEE_DB.values().stream()
				.map(e -> e.getEmail().toUpperCase())
				.anyMatch(x -> x.equals(email.toUpperCase()));
			
	}
	
	private boolean emailIsNotWellFormed(String email) {
		
		if (email == null || email.isBlank()) return false;

	    String regex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$";
	    return !email.toUpperCase().matches(regex);
	}

}
