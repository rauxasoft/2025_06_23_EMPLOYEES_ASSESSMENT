// employee-form-dwr.js adaptado de AJAX ----> DWR
// Jordi Alemany - 2025-06-28

$(document).ready(function () {

    const contextPath = $("body").data("context-path") || "";
    const employeeId = $("#employeeId").val();
    const editMode = employeeId !== undefined && employeeId !== "";

    if (editMode) {
        $("#form-title").text("Edit Employee");
        $("#submitBtn").text("Update");
    } else {
        $("#form-title").text("New Employee");
        $("#submitBtn").text("Create");
    }

    $("#employeeForm").submit(function (e) {

        e.preventDefault();

        const employee = {
            name: $("#name").val().trim(),
            email: $("#email").val().trim(),
            phoneNumber: $("#phone").val().trim(),
            dateOfJoining: $("#date").val()
        };

        if (!employee.name || !employee.email || !employee.phoneNumber || !employee.dateOfJoining) {
            $("#message").text("All fields are required").css("color", "red");
            return;
        }
		
		employee.dateOfJoining = parseDateFromInput(employee.dateOfJoining);

        if (editMode) {
            employee.employeeId = parseInt(employeeId);
            EmployeeServices.update(employee, function () {
                $("#message").text("Employee updated successfully").css("color", "green");
                setTimeout(() => {
                    window.location.href = contextPath + "/app/employees";
                }, 1000);
            });

        } else {
			
            EmployeeServices.create(employee, function (newId) {
                $("#message").text("Employee created successfully with ID " + newId).css("color", "green");
                setTimeout(() => {
                    window.location.href = contextPath + "/app/employees";
                }, 1000);
            });
        }
    });
	
	/**
	 * Convierte una fecha en formato 'yyyy-MM-dd' en un objeto Date de JS
	 * 
	 * @param {string} fechaString - La fecha en formato '2021-10-22'
	 * @returns {Date|null} - Objeto Date o null si la entrada es inválida
	 */
	function parseDateFromInput(fechaString) {
	    if (!fechaString) return null;
	    const parts = fechaString.split("-");
	    if (parts.length !== 3) return null;
	    const year = parseInt(parts[0], 10);
	    const month = parseInt(parts[1], 10) - 1; // Mes 0-based
	    const day = parseInt(parts[2], 10);
	    if (isNaN(year) || isNaN(month) || isNaN(day)) return null;
	    return new Date(year, month, day);
	}
});
