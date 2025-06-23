/**
 * Jordi Alemany
 * 
 * 2025-06-21
 * 
 */

$(document).ready(function () {
	
	const contextPath = $("body").data("context-path");
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

    	if (editMode) {
      		employee.employeeId = parseInt(employeeId);
    	}

    	const httpMethod = editMode ? "PUT" : "POST";

    	$.ajax({
			
      		url: contextPath + "/api/employees",
      		method: httpMethod,
      		contentType: "application/json",
      		data: JSON.stringify(employee),
      		
			success: function () {
        		$("#message").text("Employee " + (editMode ? "updated" : "created") + " successfully").css("color", "green");
				window.location.href = contextPath + "/app/employees";
      		},
      		
			error: function (xhr) {
        		const msg = xhr.responseText || "An error occurred while processing the employee";
        		$("#message").text(msg).css("color", "red");
      		}
    	});
  	});
});
