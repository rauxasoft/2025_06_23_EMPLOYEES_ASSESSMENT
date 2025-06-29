<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Employee Form</title>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="${pageContext.request.contextPath}/dwr/engine.js"></script>
    <script src="${pageContext.request.contextPath}/dwr/util.js"></script>
    <script src="${pageContext.request.contextPath}/dwr/interface/EmployeeServices.js"></script>
    <script src="${pageContext.request.contextPath}/js/employee-form-dwr.js"></script>
  	<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
</head>
<body data-context-path="${pageContext.request.contextPath}">
	
	<jsp:include page="nav.jsp"/>

	<h2 id="form-title">Employee Form</h2>

	<form id="employeeForm">
	
		<!-- Solo presente si estamos editando -->
		<input type="hidden" id="employeeId" value="${employee.employeeId}">

	    <label>Name:</label><br>
	    <input type="text" id="name" value="${employee.name}"><br>

	    <label>Email:</label><br>
	    <input type="email" id="email" value="${employee.email}"><br>

	    <label>Phone Number:</label><br>
	    <input type="text" id="phone" value="${employee.phoneNumber}"><br>

	    <label>Date of joining:</label><br>
	    <input type="date" id="date" value="${dateOfJoining}"><br><br>

	    <button type="submit" id="submitBtn">Send</button>
  	</form>

	<p id="message"></p>

	
</body>
</html>
