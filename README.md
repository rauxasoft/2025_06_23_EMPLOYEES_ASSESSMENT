# Employee Management Web Application

## Author

**Jordi Alemany**  
June 2025  

This project is a simple but complete Java EE web application designed to manage employee records using JSP, Servlets, PL/SQL and jQuery. It has been developed as part of a technical assignment, following best practices in modular architecture, error handling and frontend interaction.

---

## 🔧 1. Backend (Java EE)

The backend is built using standard Java EE with the following structure:

```
employeesmanagement/
├── presentation/
│   ├── application/       → Application-level Servlets
│   └── api/               → REST API Servlets (AJAX endpoints)
├── business/              → Business logic layer
├── repository/            → Interface to database operations
├── common/                → Shared classes (e.g. pagination wrapper)
```

- **Servlets** are grouped by purpose: those that serve JSP pages (`/app/...`) and those that act as API endpoints (`/api/...`).
- A clear separation is made between presentation, business logic and persistence.
- The business layer was introduced to isolate validation and interaction with stored procedures.
- Backend uses **Gson** for JSON serialization and supports full CRUD via RESTful endpoints.

---

## 🧱 2. Database Script

The script `database_generation.sql` includes everything required to initialize the database:

- Conditional `DROP` statements with exception handling
- Creation of the `EMPLOYEES` table and sequence
- A PL/SQL package `employment_module` containing:
  - `create_or_edit` procedure
  - `remove` procedure
  - `get_employees` procedure with pagination and sorting support
  - A function `is_email_duplicated` for validation
- Test data: 100 employees inserted using fixed IDs

This script is fully idempotent and can be rerun safely.

---

## 🌐 3. Tomcat Configuration and JNDI Setup

The application is designed to run on **Apache Tomcat 9.x**.

To enable connection pooling using JNDI:

- The file `context.xml` (inside Tomcat `conf/` or `META-INF/` in the app) defines the `DataSource` with the name:

```xml
<Resource name="jdbc/EmployeeDB" 
          auth="Container" 
          type="javax.sql.DataSource"
          driverClassName="oracle.jdbc.OracleDriver"
          url="jdbc:oracle:thin:@localhost:1521:xe"
          username="system" 
          password="your_password"
          maxTotal="20" 
          maxIdle="10" 
          maxWaitMillis="-1"/>
```

- In Java, JNDI is used to look up the connection pool:

```java
Context ctx = new InitialContext();
DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/EmployeeDB");
```

The application avoids hardcoded credentials in Java code, improving maintainability and security.

---

## 📄 Additional Notes

- Frontend uses **JSP** and **jQuery** for interactivity (pagination, sorting, deletion confirmation).
- AJAX requests return and consume JSON payloads.
- All dynamic pages are routed through servlets to enforce separation of responsibilities.
- CSS styles and JavaScript are kept modular and minimalistic.

---

## 🚀 Deployment Instructions

1. Ensure Oracle XE 21 is installed and accessible.
2. Execute `database_generation.sql` from SQL Developer or command line.
3. Deploy the `.war` or import the Eclipse project into a server runtime with Tomcat 9.
4. Configure the `context.xml` for JNDI connection pooling.
5. Start the server and open `http://localhost:8080/employeesmanagement/` (or your chosen context path).

---

### 🧪 Dummy Service for UI Testing (No Database)

For testing the application without requiring a database connection, a dummy implementation of `EmployeeServices` is available.

To enable it:

1. **Comment** the real service line:
   
   ```java
   // sce.getServletContext().setAttribute("employeeServices", employeeServices);
   ```
  
2. **Uncomment** the dummy line:
   
   ```java
   sce.getServletContext().setAttribute("employeeServices", employeeServicesDummyImpl);
   ```

This allows you to run and test the application without an Oracle database:

✅ Browse JSP pages

✅ Submit and validate forms

✅ Interact with AJAX endpoints


