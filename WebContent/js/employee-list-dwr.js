// employee-list-dwr.js adaptado para DWR con ordenación y paginación
// Jordi Alemany - 2025-06-28

$(document).ready(function() {

    const contextPath = $("body").data("context-path") || "";
    const currentEmployees = new Map();

    let pageSize = 10;
    let currentPage = 1;
    let currentSortField = "name";
    let currentSortAsc = true;
    let employeeIdToDelete = null;

    // ***************************************************************************
    // Utilidad para parsear fecha correctamente desde String DWR
	// ***************************************************************************
	
    function parseDWRDate(fechaStr) {
        if (!fechaStr) return '';
        const fecha = new Date(fechaStr);
        if (isNaN(fecha)) return '';
        const year = fecha.getFullYear();
        const month = String(fecha.getMonth() + 1).padStart(2, '0');
        const day = String(fecha.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    // ***************************************************************************
    // Listeners
    // ***************************************************************************

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
        EmployeeServices.remove(employeeIdToDelete, function() {
            $("#confirmDelete").fadeOut();
            displayNotification("Employee deleted successfully");
            loadPage(currentPage);
        });
    });

    $("#confirmNo").click(() => {
        $("#confirmDelete").fadeOut();
        employeeIdToDelete = null;
    });

    $("#prevBtn").click(() => loadPage(currentPage - 1));
    $("#nextBtn").click(() => loadPage(currentPage + 1));

    // ***************************************************************************
    // Display notification
	// ***************************************************************************
	
    function displayNotification(message, type = "success") {
        const div = $("#notification");
        div.text(message);
        div.css("color", type === "success" ? "green" : "red");
        div.fadeIn();
        setTimeout(() => {
            div.fadeOut();
        }, 3000);
    }

    // ***************************************************************************
    // Load page with DWR
	// ***************************************************************************
	
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

        EmployeeServices.getPage(pageNumber, pageSize, currentSortField, currentSortAsc, function(data) {
            let tbody = $("#employeeTable tbody");
            tbody.empty();
            currentEmployees.clear();

            data.content.forEach(e => {
                currentEmployees.set(e.employeeId, e);
                tbody.append(`
                    <tr>
                        <td>${e.employeeId}</td>
                        <td>${e.name}</td>
                        <td>${e.email}</td>
                        <td>${e.phoneNumber}</td>
                        <td>${parseDWRDate(e.dateOfJoining)}</td>
                        <td>
                            <a href="${contextPath}/app/employee-form?employeeId=${e.employeeId}" title="Editar">
                                <span style="cursor:pointer;font-size:18px;">✏️</span>
                            </a>
                        </td>
                        <td>
                            <span class="btnEliminar" data-id="${e.employeeId}" title="Delete" style="cursor:pointer;color:red;font-size:18px;">&#10060;</span>
                        </td>
                    </tr>
                `);
            });

            $("#pageInfo").text(`Page ${data.pageNumber} of ${data.totalPages}`);
            currentPage = data.pageNumber;
            $("#prevBtn").prop("disabled", currentPage <= 1);
            $("#nextBtn").prop("disabled", currentPage >= data.totalPages);
        });
    }

    // ***************************************************************************
    // Init
    loadPage(currentPage);

});
