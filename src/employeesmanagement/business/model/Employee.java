package employeesmanagement.business.model;

import java.time.LocalDate;
import java.util.Objects;

public class Employee {

	private Long employeeId;
    private String name;
    private String email;
    private String phoneNumber;
    private LocalDate dateOfJoining;
	
    public Employee() {
    	
    }
    
    public Employee(Long employeeId, String name, String email, String phoneNumber, LocalDate dateOfJoining) {
		this.employeeId = employeeId;
		this.name = name;
		this.email = email;
		this.phoneNumber = phoneNumber;
		this.dateOfJoining = dateOfJoining;
	}

	public Long getEmployeeId() {
		return employeeId;
	}

	public void setEmployeeId(Long employeeId) {
		this.employeeId = employeeId;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getPhoneNumber() {
		return phoneNumber;
	}

	public void setPhoneNumber(String phoneNumber) {
		this.phoneNumber = phoneNumber;
	}

	public LocalDate getDateOfJoining() {
		return dateOfJoining;
	}

	public void setDateOfJoining(LocalDate dateOfJoining) {
		this.dateOfJoining = dateOfJoining;
	}

	@Override
	public int hashCode() {
		return Objects.hash(employeeId);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		Employee other = (Employee) obj;
		return employeeId == other.employeeId;
	}

	@Override
	public String toString() {
		return "Employee [employeeId=" + employeeId + ", name=" + name + ", email=" + email + ", phoneNumber="
				+ phoneNumber + ", dateOfJoining=" + dateOfJoining + "]";
	}

}
