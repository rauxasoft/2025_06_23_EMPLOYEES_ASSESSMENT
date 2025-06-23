package employeesmanagement.repository.daos.impl;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import employeesmanagement.business.model.Employee;
import employeesmanagement.common.Page;
import employeesmanagement.repository.ConnectionProvider;
import employeesmanagement.repository.daos.EmployeeDAO;
import employeesmanagement.repository.exceptions.PersistenceException;
import oracle.jdbc.OracleTypes;

public class EmployeeDAOImpl implements EmployeeDAO {

	@Override
	public Long create(Employee employee) throws PersistenceException {
		
		String call = "{ call employment_module.create_or_edit(?, ?, ?, ?, ?) }";

	    try (Connection conn = ConnectionProvider.getConnection();
	         CallableStatement stmt = conn.prepareCall(call)) {

	        // 1️.- Parámetro IN-OUT para el ID
	        stmt.registerOutParameter(1, Types.NUMERIC);
	        stmt.setNull(1, Types.NUMERIC); // al crear -> sin ID previo

	        // 2.- Parámetros de entrada
	        stmt.setString(2, employee.getName());
	        stmt.setString(3, employee.getEmail());
	        stmt.setString(4, employee.getPhoneNumber());
	        stmt.setDate(5, java.sql.Date.valueOf(employee.getDateOfJoining()));

	        // 3️.- Ejecutar
	        stmt.execute();

	        // 4️.- Leer el ID generado
	        return stmt.getLong(1);

	    } catch (SQLException e) {
	        throw new PersistenceException("Error creating employee");
	    }
	}
	
	@Override
	public Optional<Employee> findById(long employeeId) throws PersistenceException {
		
		String sql = """
				
			SELECT employee_id, 
				   name, 
				   email, 
				   phone_number, 
				   date_of_joining
			  FROM employees 
			  WHERE employee_id = ?
				
		"""; 

	    try (Connection conn = ConnectionProvider.getConnection();
	         PreparedStatement ps = conn.prepareStatement(sql)) {

	        ps.setLong(1, employeeId);

	        try (ResultSet rs = ps.executeQuery()) {
	            if (rs.next()) {
	                Employee emp = new Employee();
	                emp.setEmployeeId(rs.getLong("employee_id"));
	                emp.setName(rs.getString("name"));
	                emp.setEmail(rs.getString("email"));
	                emp.setPhoneNumber(rs.getString("phone_number"));
	                emp.setDateOfJoining(rs.getDate("date_of_joining").toLocalDate());
	                return Optional.of(emp);
	            } else {
	                return Optional.empty();
	            }
	        }

	    } catch (SQLException e) {
	        throw new PersistenceException("Error finding employee by ID " + employeeId);
	    }
	}

	@Override
	public void update(Employee employee) throws PersistenceException {
		
		String call = "{ call employment_module.create_or_edit(?, ?, ?, ?, ?) }";

	    try (Connection conn = ConnectionProvider.getConnection();
	         CallableStatement stmt = conn.prepareCall(call)) {

	    	stmt.registerOutParameter(1, Types.NUMERIC);
	        stmt.setLong(1, employee.getEmployeeId());
	        
	        stmt.setString(2, employee.getName());
	        stmt.setString(3, employee.getEmail());
	        stmt.setString(4, employee.getPhoneNumber());
	        stmt.setDate(5, java.sql.Date.valueOf(employee.getDateOfJoining()));

	        stmt.execute();

	    } catch (SQLException e) {
	    	
	    	if (e.getErrorCode() == 20001) {
	    	    throw new PersistenceException("The email is already in use");
	    	} else {
	    	    throw new PersistenceException("Error updating employee with ID " + employee.getEmployeeId());
	    	}
	    }
		
	}

	@Override
	public void delete(long employeeId) throws PersistenceException {
		 
		String call = "{ call employment_module.remove(?) }";
		
		try (Connection conn = ConnectionProvider.getConnection();
		     CallableStatement stmt = conn.prepareCall(call)) {

		     stmt.setLong(1, employeeId);
		     stmt.execute();

		} catch (SQLException e) {
		     throw new PersistenceException("Error deleting employee with ID " + employeeId);
		}	
	}

	@Override
	public Page<Employee> findPage(int pageNumber, int pageSize, String orderBy, boolean ascending) throws PersistenceException {
		
		List<Employee> employees = new ArrayList<>();
		int totalElements = 0;
		int totalPages = 0;
		                         
		final String call = "{call employment_module.get_employees(?, ?, ?, ?, ?, ?, ?, ?)}";
		
		try (Connection conn = ConnectionProvider.getConnection(); 
			 CallableStatement stmt = conn.prepareCall(call)) {
			
			 stmt.setInt(1, pageNumber);
		     stmt.setInt(2, pageSize);
		     stmt.setString(3, orderBy);
		     stmt.setString(4, ascending ? "ASC" : "DESC");
		     stmt.registerOutParameter(5, OracleTypes.CURSOR);
		     stmt.registerOutParameter(6, Types.INTEGER); // totalElements
		     stmt.registerOutParameter(7, Types.INTEGER); // totalPages
		     stmt.registerOutParameter(8, Types.INTEGER); // currentPageCount

		     stmt.execute();
		     
		     try (ResultSet rs = (ResultSet) stmt.getObject(5)) {
		    	 
		    	 while (rs.next()) {
		    		 Employee emp = new Employee();
		             emp.setEmployeeId(rs.getLong("employee_id"));
		             emp.setName(rs.getString("name"));
		             emp.setEmail(rs.getString("email"));
		             emp.setPhoneNumber(rs.getString("phone_number"));
		             emp.setDateOfJoining(rs.getDate("date_of_joining").toLocalDate());
		             employees.add(emp);
		            }
		        }

		        totalElements = stmt.getInt(6);
		        totalPages = stmt.getInt(7);
		       
		        return new Page<>(employees, pageNumber, pageSize, totalElements, totalPages);
			
		} catch (Exception e) {
			e.printStackTrace();
			throw new PersistenceException("Error accessing the database");

		}
		
	}
	
	@Override
	public boolean existsById(Long employeeId) {
		
		String sql = "SELECT 1 FROM employees WHERE employee_id = ?";

	    try (Connection conn = ConnectionProvider.getConnection();
	         PreparedStatement ps = conn.prepareStatement(sql)) {

	        ps.setLong(1, employeeId);
	        try (ResultSet rs = ps.executeQuery()) {
	            return rs.next(); 
	        }

	    } catch (SQLException e) {
	        throw new PersistenceException("Error checking employee existence by ID");
	    }
	}

	@Override
	public boolean existsEmail(String email) {
		
		String sql = "SELECT 1 FROM employees WHERE LOWER(email) = LOWER(?)";
	    
		try (Connection conn = ConnectionProvider.getConnection();
	         PreparedStatement ps = conn.prepareStatement(sql)) {
	        
	        ps.setString(1, email.trim());
	        
	        try (ResultSet rs = ps.executeQuery()) {
	            return rs.next();  
	        }
	        
	    } catch (SQLException e) {
	        throw new PersistenceException("Email already in use");
	    }
	}
	
}
