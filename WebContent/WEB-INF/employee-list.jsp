<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Employees</title>
  	<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
  	<script src="${pageContext.request.contextPath}/dwr/engine.js"></script>
	<script src="${pageContext.request.contextPath}/dwr/util.js"></script>
	<script src="${pageContext.request.contextPath}/dwr/interface/EmployeeServices.js"></script>
	<script src="${pageContext.request.contextPath}/js/employee-list-dwr.js"></script>
  	<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
</head>
<body data-context-path="${pageContext.request.contextPath}">
	<jsp:include page="nav.jsp"/>
	<h2>Employee List</h2>
	<table id="employeeTable">
  		<thead>
    		<tr>
    			<th data-sort="id">EmployeeID</th>
    			<th data-sort="name">Name</th>
    			<th data-sort="email">Email</th>
    			<th data-sort="phone">Phone Number</th>
    			<th data-sort="date">Date of joining</th>
      			<th>edit</th>
      			<th>delete</th>
    		</tr>
  		</thead>
  		<tbody></tbody>
	</table>
	
	<div id="notification" style="display: none; color: green; margin: 10px 0;"></div>
	
	<div id="confirmDelete" class="modal" style="display: none;">
  		<div class="modal-content">
    		<p id="confirmText">¿Are yuo sure?</p>
    		<button id="confirmYes">Yes</button>
    		<button id="confirmNo">No</button>
  		</div>
	</div>

	<br>
	
	<button id="prevBtn">« Previous</button> <span id="pageInfo"></span><button id="nextBtn">Next »</button>
	
</body>
</html>