/**
 * Jordi Alemany
 * 
 * 2025-06-21
 * 
 */

$(document).ready(function() {
		
	const contextPath = $("body").data("context-path");
	const currentEmployees = new Map();
  	
	let pageSize = 10;
	let currentPage = 1;
	let currentSortField = "name";
	let currentSortAsc = true;
	let employeeIdToDelete = null;
  
  	// *********************************************************************************
	//  Listeners
	// *********************************************************************************
  
 	$("#employeeTable").on("click", ".btnEliminar", function() {
		employeeIdToDelete = $(this).data("id");
		const employee = currentEmployees.get(employeeIdToDelete);
		$("#confirmText").text(`Are you sure you want to delete employee #${employeeIdToDelete} ${employee.name}?`);
		$("#confirmDelete").fadeIn();
  	});
  
  	$("th[data-sort]").click(function() {
		const clickedField = $(this).data("sort");

    	if (clickedField === currentSortField) {
      		currentSortAsc = !currentSortAsc; 
    	} else {
      		currentSortField = clickedField;
      		currentSortAsc = true;
    	}
    	loadPage(1);
  	});

  	$("#confirmYes").click(() => {
    	$.ajax({
      		url: contextPath + "/api/employees/" + employeeIdToDelete,
      		method: "DELETE",
      		success: () => {
        		$("#confirmDelete").fadeOut();
        		displayNotification("Employee deleted successfully");
        		loadPage(currentPage);
      		},
      		error: (xhr) => {
        		$("#confirmDelete").fadeOut();
        		displayNotification("Error al eliminar: " + (xhr.responseText || "desconocido"), "error");
      		}
    	});
  	});	

  	$("#confirmNo").click(() => {
    	$("#confirmDelete").fadeOut();
    	idAEliminar = null;
  	});
	
	$("#prevBtn").click(() => loadPage(currentPage - 1));
	$("#nextBtn").click(() => loadPage(currentPage + 1));
  
	// *********************************************************************************
	//  Functions
	// *********************************************************************************
  
	function displayNotification(message, type = "success") {
    	
		const div = $("#notification");
    	
		div.text(message);
		div.css("color", type === "success" ? "green" : "red");
    	div.fadeIn();

    	setTimeout(() => {
      		div.fadeOut();
    	}, 3000);
  	}
  
	function loadPage(pageNumber) {

		$("th[data-sort]").each(function () {
	  		const th = $(this);
	  		const field = th.data("sort");
	  
	  		if (field === currentSortField) {
	    		th.text(th.text().replace(/[↑↓]$/, '') + (currentSortAsc ? ' ↑' : ' ↓'));
	  		} else {
	    		th.text(th.text().replace(/[↑↓]$/, ''));
	  		}
		});
		
    	$.get(contextPath + "/api/employees/", {
			pagesize: pageSize,
			pagenumber: pageNumber,
			sortfield: currentSortField,
			sortdir: currentSortAsc ? "asc" : "desc"
    	}, function(data) {
			
			let tbody = $("#employeeTable tbody");
			
			tbody.empty();
	  		currentEmployees.clear();
			data.content.forEach(e => {
				currentEmployees.set(e.employeeId, e);
				tbody.append(
			`		<tr>
			    		<td>${e.employeeId}</td>
          				<td>${e.name}</td>
          				<td>${e.email}</td>
          				<td>${e.phoneNumber}</td>
          				<td>${e.dateOfJoining}</td>
						<td>
							<a href="${contextPath}/app/employee-form?employeeId=${e.employeeId}" title="Editar">
								<span style="cursor:pointer;font-size:18px;">✏️</span>
				 			</a>
						</td>
						<td>
							<span class="btnEliminar" data-id="${e.employeeId}" title="Delete" style="cursor:pointer;color:red;font-size:18px;">&#10060;</span>
						</td>
        			</tr>`
				);
      		});

      		$("#pageInfo").text(`Page ${data.pageNumber} of ${data.totalPages}`);
      		
			currentPage = data.pageNumber;
      		$("#prevBtn").prop("disabled", currentPage <= 1);
      		$("#nextBtn").prop("disabled", currentPage >= data.totalPages);
    	});
  	}
	
	// *********************************************************************************
	//  Init
	// *********************************************************************************
		
  	loadPage(currentPage); 
});
