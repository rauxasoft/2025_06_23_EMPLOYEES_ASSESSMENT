# Employee Management Web Application (DWR Version)

## Author
**Jordi Alemany**  
June 2025

---

## New DWR-based Version

This project refactors the previous REST + AJAX implementation to use **DWR (Direct Web Remoting)**, simplifying client-server interaction:

- Service methods are exposed directly as JavaScript functions.  
- The frontend no longer uses AJAX with REST endpoints but makes direct DWR calls.  
- DTOs are automatically serialized between Java and JavaScript.

---

## Key changes from the previous version

- The `Optional<Employee>` return type was changed to return `null` when the employee is not found, ensuring DWR compatibility.
- The method `delete` was renamed to `remove` because `delete` is a reserved keyword in JavaScript and not accepted by DWR.
- `LocalDate` was replaced with `java.util.Date` to ensure DWR serialization compatibility.
- Overloaded methods in the service layer were removed because DWR does not handle overloaded methods well.
- The "dummy" service version was removed, using the real service directly now.
- The **business service (`EmployeeServicesImpl`) is a Singleton** but has a **public no-args constructor** to allow easy instantiation by DWR.
- The **repository DAO (`EmployeeDAOImpl`) is also a Singleton.**

---

## Architecture

- **Backend:** Java EE with Servlets, DWR, and JDBC with stored procedures.
- **Frontend:** JSP, CSS, and DWR calls instead of REST/AJAX.
- **Database:** Oracle with business-level stored procedures.

---

## Advantages of switching to DWR

- Less REST infrastructure and fewer manual endpoints to maintain.
- Simplified frontend, calling Java methods directly.
- Transparent and automatic object serialization between Java and JavaScript.
- Easier maintenance for educational purposes and medium-scale projects.

---

## Deployment Instructions

1. Install Oracle XE and run `database_generation.sql`.
2. Configure `context.xml` for JNDI connection pooling.
3. Deploy the `.war` file or import the project into Tomcat.
4. Configure `dwr.xml` to expose `EmployeeServicesImpl`.
5. Access the application at:** `http://localhost:8080/employeesmanagement/` (or your configured context path).

---

## Note on KISS and architectural choices

While I generally follow the **KISS** principle, I chose to maintain clear separation with interfaces and layered architecture (service and DAO layers) in this assignment to demonstrate clean architecture practices and maintainability, even though for a small application a more straightforward approach could also have been valid.
