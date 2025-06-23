-- =============================================
-- Limpieza previa: drop con control de errores
-- =============================================

BEGIN
  -- Drop table employees
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE employees';
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -942 THEN -- ORA-00942: table or view does not exist
      RAISE;
    END IF;
  END;

  -- Drop sequence employee_seq
  BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE employee_seq';
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -2289 THEN -- ORA-02289: sequence does not exist
      RAISE;
    END IF;
  END;

  -- Drop package employment_module
  BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE employment_module';
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -4043 THEN -- ORA-04043: object does not exist
      RAISE;
    END IF;
  END;
END;
/

-- =============================================
-- Creación de objetos
-- =============================================

CREATE TABLE employees (
  employee_id     NUMBER PRIMARY KEY,
  name            VARCHAR2(100) NOT NULL,
  email           VARCHAR2(150) NOT NULL UNIQUE,
  phone_number    VARCHAR2(20) NOT NULL,
  date_of_joining DATE NOT NULL
);
/

CREATE SEQUENCE employee_seq
  START WITH 2000
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;
  
/

CREATE OR REPLACE PACKAGE employment_module AS

    FUNCTION is_email_duplicated(
        p_email             IN VARCHAR2,
        p_employee_id       IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN;
  
    PROCEDURE create_or_edit(
        p_employee_id       IN OUT NUMBER,
        p_name              IN VARCHAR2,
        p_email             IN VARCHAR2,
        p_phone_number      IN VARCHAR2,
        p_date_of_joining   IN DATE
    );
    
    PROCEDURE remove(
        p_employee_id IN NUMBER
    );
    
    PROCEDURE get_employees(
        p_page_number       IN NUMBER,
        p_page_size         IN NUMBER,
        p_order_by          IN VARCHAR2,
        p_ascending         IN VARCHAR2,  -- 'ASC' o 'DESC'
        p_result_cursor     OUT SYS_REFCURSOR,
        p_total_records     OUT NUMBER,
        p_total_pages       OUT NUMBER,
        p_page_count        OUT NUMBER
    );
  
END employment_module;
/

CREATE OR REPLACE PACKAGE BODY employment_module AS

    FUNCTION is_email_duplicated(
        p_email             IN VARCHAR2,
        p_employee_id       IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN IS v_count NUMBER := 0;
    
    BEGIN
        SELECT COUNT(*) INTO v_count
          FROM employees
         WHERE LOWER(email) = LOWER(p_email)
           AND (p_employee_id IS NULL OR employee_id != p_employee_id);
        
        RETURN v_count > 0;
        
    END is_email_duplicated;
    
    PROCEDURE create_or_edit(
        p_employee_id       IN OUT NUMBER,
        p_name              IN VARCHAR2,
        p_email             IN VARCHAR2,
        p_phone_number      IN VARCHAR2,
        p_date_of_joining   IN DATE) IS
    
    BEGIN
    
        IF is_email_duplicated(p_email, p_employee_id) THEN
            RAISE_APPLICATION_ERROR(-20001, 'Email already in use.');
        END IF;

        IF p_employee_id IS NULL THEN
            
            SELECT employee_seq.NEXTVAL INTO p_employee_id FROM dual;

            INSERT INTO employees (employee_id, name, email, phone_number, date_of_joining) 
                 VALUES (p_employee_id, p_name, p_email, p_phone_number, p_date_of_joining);

        ELSE
           
            UPDATE employees
               SET             name = p_name,
                              email = p_email,
                       phone_number = p_phone_number,
                    date_of_joining = p_date_of_joining
            WHERE employee_id = p_employee_id;

            IF SQL%ROWCOUNT = 0 THEN 
                RAISE_APPLICATION_ERROR(-20002, 'No exits an employee with this ID.');
            END IF;
        END IF;
    END create_or_edit;
  
    PROCEDURE remove(
        p_employee_id       IN NUMBER
    ) IS
    
    BEGIN
        DELETE 
          FROM employees
         WHERE employee_id = p_employee_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Not found an employee with this ID.');
        END IF;
    END remove;
    
    PROCEDURE get_employees(
        p_page_number       IN NUMBER,
        p_page_size         IN NUMBER,
        p_order_by          IN VARCHAR2,
        p_ascending         IN VARCHAR2,  -- 'ASC' o 'DESC'
        p_result_cursor     OUT SYS_REFCURSOR,
        p_total_records     OUT NUMBER,
        p_total_pages       OUT NUMBER,
        p_page_count        OUT NUMBER
    ) IS
        v_sql               VARCHAR2(1000);
        v_offset            NUMBER;
        v_order             VARCHAR2(50);
        v_direction         VARCHAR2(4); 
    
    BEGIN
        
        -- Validar y establecer orden por defecto
        IF p_order_by IS NULL OR UPPER(p_order_by) NOT IN ('NAME', 'EMAIL', 'PHONE_NUMBER', 'DATE_OF_JOINING') THEN
            v_order := 'employee_id';
        ELSE
            v_order := LOWER(p_order_by);
        END IF;

        -- Nos aseguramos de tener bien la dirección
        IF UPPER(p_ascending) = 'DESC' THEN
            v_direction := 'DESC';
        ELSE
            v_direction := 'ASC';
        END IF;

        v_offset := (p_page_number - 1) * p_page_size;
       
        SELECT COUNT(*) INTO p_total_records FROM employees;

        p_total_pages := CEIL(p_total_records / p_page_size);
        
        -- Construir SQL dinámico con paginación
       
        v_sql := '
            SELECT *
              FROM employees
             ORDER BY ' || v_order || ' ' || v_direction || '
            OFFSET :1 ROWS FETCH NEXT :2 ROWS ONLY';

        
        OPEN p_result_cursor FOR v_sql USING v_offset, p_page_size;

  
        IF v_offset + p_page_size > p_total_records THEN
            p_page_count := GREATEST(p_total_records - v_offset, 0);
        ELSE
            p_page_count := p_page_size;
        END IF;
    END get_employees;
    
END employment_module;
/

-- =============================================
-- Datos de ejemplo
-- =============================================

insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (1, 'Layned Bugdell', 'lbugdell0@bloglovin.com', '130-775-3397', TO_DATE('2021-08-31', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (2, 'Job Tripcony', 'jtripcony1@slate.com', '744-333-8354', TO_DATE('2020-04-12', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (3, 'Lani Easson', 'leasson2@java.com', '928-161-1769', TO_DATE('2020-10-03', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (4, 'Ranique Terren', 'rterren3@livejournal.com', '676-109-1781', TO_DATE('2011-11-27', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (5, 'Shoshana Housecraft', 'shousecraft4@comsenz.com', '106-736-0793', TO_DATE('2025-02-20', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (6, 'Teddy Setterfield', 'tsetterfield5@usgs.gov', '592-995-9965', TO_DATE('2022-12-03', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (7, 'Rolland Poytheras', 'rpoytheras6@hugedomains.com', '807-470-1482', TO_DATE('2018-12-01', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (8, 'Tami Minet', 'tminet7@noaa.gov', '474-294-4488', TO_DATE('2016-05-03', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (9, 'Romeo Bicheno', 'rbicheno8@examiner.com', '968-881-2801', TO_DATE('2010-06-06', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (10, 'Lelia Barstock', 'lbarstock9@reddit.com', '441-114-0082', TO_DATE('2013-05-22', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (11, 'Brook Matiewe', 'bmatiewea@google.com.hk', '173-521-5861', TO_DATE('2013-05-09', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (12, 'Julina Paulot', 'jpaulotb@howstuffworks.com', '688-933-0662', TO_DATE('2013-05-01', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (13, 'Neilla Culleford', 'ncullefordc@engadget.com', '205-163-8122', TO_DATE('2023-09-07', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (14, 'Bernetta Else', 'belsed@com.com', '295-484-3940', TO_DATE('2017-01-31', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (15, 'Hildegaard Giorgeschi', 'hgiorgeschie@flavors.me', '193-833-7141', TO_DATE('2024-09-21', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (16, 'Herold De Castri', 'hdef@ftc.gov', '504-271-8249', TO_DATE('2019-04-30', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (17, 'Brittney Gammie', 'bgammieg@google.ca', '592-330-4653', TO_DATE('2022-01-13', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (18, 'Huntley Lippingwell', 'hlippingwellh@usnews.com', '957-523-2284', TO_DATE('2024-10-17', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (19, 'Francisco Lavender', 'flavenderi@google.ca', '623-321-8398', TO_DATE('2024-01-27', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (20, 'Clementius Domerc', 'cdomercj@ow.ly', '494-204-9172', TO_DATE('2017-02-04', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (21, 'Lorelei Breddy', 'lbreddyk@netvibes.com', '814-445-4185', TO_DATE('2018-03-05', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (22, 'Catha Pieche', 'cpiechel@yellowbook.com', '746-550-9518', TO_DATE('2010-04-09', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (23, 'Garrek Forestel', 'gforestelm@disqus.com', '847-609-3638', TO_DATE('2022-02-22', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (24, 'Candida Olivas', 'colivasn@dailymail.co.uk', '919-811-6570', TO_DATE('2019-04-23', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (25, 'Antonetta Demaine', 'ademaineo@blogtalkradio.com', '892-115-1745', TO_DATE('2015-12-03', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (26, 'Sharity Ransom', 'sransomp@wikia.com', '962-425-9514', TO_DATE('2021-05-07', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (27, 'Jacquenetta Reditt', 'jredittq@google.com.hk', '549-110-4946', TO_DATE('2023-11-04', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (28, 'Dulsea Brewett', 'dbrewettr@nasa.gov', '392-773-9850', TO_DATE('2023-06-06', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (29, 'Eleanore Grgic', 'egrgics@bluehost.com', '121-675-8599', TO_DATE('2021-09-09', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (30, 'Stefania Burchnall', 'sburchnallt@rediff.com', '372-338-6402', TO_DATE('2019-10-08', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (31, 'Beniamino Okenfold', 'bokenfoldu@imgur.com', '389-433-3798', TO_DATE('2020-07-31', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (32, 'Leontyne Drinkeld', 'ldrinkeldv@mapquest.com', '959-843-5751', TO_DATE('2023-11-02', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (33, 'Gerrie Rosellini', 'groselliniw@ftc.gov', '224-887-2297', TO_DATE('2015-04-17', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (34, 'Barnabe Mineghelli', 'bmineghellix@pinterest.com', '619-157-2829', TO_DATE('2019-10-12', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (35, 'Gaston Salaman', 'gsalamany@walmart.com', '774-388-8069', TO_DATE('2024-12-12', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (36, 'Johan Riddles', 'jriddlesz@lycos.com', '596-897-9994', TO_DATE('2010-12-10', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (37, 'Abbye Spooner', 'aspooner10@amazon.de', '875-186-3268', TO_DATE('2019-12-08', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (38, 'Jean Jerger', 'jjerger11@parallels.com', '981-222-9338', TO_DATE('2019-10-06', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (39, 'Hillie Warden', 'hwarden12@xing.com', '723-326-3258', TO_DATE('2020-11-14', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (40, 'Deeanne Tabary', 'dtabary13@goodreads.com', '509-735-4856', TO_DATE('2019-05-23', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (41, 'Ludwig Lambal', 'llambal14@pcworld.com', '400-280-0107', TO_DATE('2018-08-29', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (42, 'Willie Tonbridge', 'wtonbridge15@slashdot.org', '246-457-4822', TO_DATE('2018-11-11', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (43, 'Carmelina Stearn', 'cstearn16@privacy.gov.au', '303-833-8541', TO_DATE('2024-01-04', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (44, 'Eugen Dawidowicz', 'edawidowicz17@shinystat.com', '536-305-2925', TO_DATE('2014-11-21', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (45, 'Berkly Roycroft', 'broycroft18@etsy.com', '276-105-5074', TO_DATE('2018-06-11', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (46, 'Brittney Szapiro', 'bszapiro19@linkedin.com', '418-738-4054', TO_DATE('2012-02-15', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (47, 'Dukey Balleine', 'dballeine1a@1688.com', '558-576-3127', TO_DATE('2014-03-31', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (48, 'Tamera Copley', 'tcopley1b@imageshack.us', '680-471-8500', TO_DATE('2023-09-26', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (49, 'Maribel Shoebotham', 'mshoebotham1c@chicagotribune.com', '965-807-9389', TO_DATE('2016-02-07', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (50, 'Kiley Dyte', 'kdyte1d@tumblr.com', '175-857-1195', TO_DATE('2024-03-09', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (51, 'Peta Coupland', 'pcoupland1e@canalblog.com', '377-889-4562', TO_DATE('2019-10-13', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (52, 'Zorina Timeby', 'ztimeby1f@forbes.com', '495-764-7122', TO_DATE('2017-10-16', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (53, 'Ethe Bynold', 'ebynold1g@google.com.br', '541-138-5308', TO_DATE('2012-05-28', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (54, 'Rosabella Samson', 'rsamson1h@cam.ac.uk', '190-593-8132', TO_DATE('2012-09-23', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (55, 'Miranda Peddersen', 'mpeddersen1i@eventbrite.com', '639-305-9853', TO_DATE('2018-08-04', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (56, 'Karly Rives', 'krives1j@cpanel.net', '811-393-2019', TO_DATE('2013-08-13', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (57, 'Griffie Lowings', 'glowings1k@mapy.cz', '849-744-3134', TO_DATE('2016-09-06', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (58, 'Mariellen Farrent', 'mfarrent1l@sciencedaily.com', '577-590-4930', TO_DATE('2012-09-14', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (59, 'Bethany Wasielewski', 'bwasielewski1m@xinhuanet.com', '414-483-7169', TO_DATE('2021-08-14', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (60, 'Sibley Bernardoni', 'sbernardoni1n@mysql.com', '532-644-0365', TO_DATE('2020-12-09', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (61, 'Barry Blackader', 'bblackader1o@phpbb.com', '885-176-7065', TO_DATE('2013-09-26', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (62, 'Lindon Davydzenko', 'ldavydzenko1p@usa.gov', '173-376-8038', TO_DATE('2019-06-02', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (63, 'Ursa Fedoronko', 'ufedoronko1q@spiegel.de', '655-404-2742', TO_DATE('2010-11-14', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (64, 'Gusta Oloman', 'goloman1r@unesco.org', '261-142-0960', TO_DATE('2021-08-09', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (65, 'Tyrone Rings', 'trings1s@liveinternet.ru', '153-725-2464', TO_DATE('2012-04-11', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (66, 'Netty Morrid', 'nmorrid1t@posterous.com', '844-758-8182', TO_DATE('2022-11-01', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (67, 'Lenka Mazzei', 'lmazzei1u@dmoz.org', '451-619-4707', TO_DATE('2010-01-22', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (68, 'Glynnis Konerding', 'gkonerding1v@dmoz.org', '733-200-9032', TO_DATE('2020-04-23', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (69, 'Nell Khristoforov', 'nkhristoforov1w@hatena.ne.jp', '186-534-1071', TO_DATE('2019-02-20', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (70, 'Gabriel Henriques', 'ghenriques1x@parallels.com', '382-680-2492', TO_DATE('2021-04-29', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (71, 'Bernice Wilkin', 'bwilkin1y@jiathis.com', '723-865-9738', TO_DATE('2017-07-12', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (72, 'See Liell', 'sliell1z@gravatar.com', '140-869-4128', TO_DATE('2015-10-02', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (73, 'Raimundo Babb', 'rbabb20@webmd.com', '354-306-0656', TO_DATE('2011-10-01', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (74, 'Boonie Kirkby', 'bkirkby21@nifty.com', '575-164-5369', TO_DATE('2014-01-06', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (75, 'Jeremias Paschek', 'jpaschek22@narod.ru', '954-848-7278', TO_DATE('2025-02-08', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (76, 'Hewie Bickers', 'hbickers23@senate.gov', '419-212-5348', TO_DATE('2022-05-13', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (77, 'Celestina Gornal', 'cgornal24@japanpost.jp', '465-962-8204', TO_DATE('2023-06-06', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (78, 'Jethro Lassetter', 'jlassetter25@newsvine.com', '398-749-5904', TO_DATE('2020-10-10', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (79, 'Jerrilyn Kaesmans', 'jkaesmans26@soup.io', '811-766-3647', TO_DATE('2023-07-13', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (80, 'Sabina Cultcheth', 'scultcheth27@dailymotion.com', '162-590-0581', TO_DATE('2010-09-01', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (81, 'Roscoe Dureden', 'rdureden28@mac.com', '813-878-4392', TO_DATE('2015-10-25', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (82, 'Petra Elvins', 'pelvins29@java.com', '161-951-3469', TO_DATE('2010-01-23', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (83, 'Cory Meeland', 'cmeeland2a@studiopress.com', '381-833-4272', TO_DATE('2018-06-10', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (84, 'Frederich Scemp', 'fscemp2b@wikimedia.org', '765-489-2390', TO_DATE('2016-01-27', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (85, 'Mychal Biasini', 'mbiasini2c@live.com', '305-709-1705', TO_DATE('2015-12-11', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (86, 'Eula Karpmann', 'ekarpmann2d@joomla.org', '412-553-1409', TO_DATE('2016-07-03', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (87, 'Donavon Urey', 'durey2e@bigcartel.com', '194-929-1230', TO_DATE('2014-11-18', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (88, 'Cobb Pallis', 'cpallis2f@woothemes.com', '500-797-6467', TO_DATE('2020-06-13', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (89, 'Birgitta Stutter', 'bstutter2g@reuters.com', '396-915-9588', TO_DATE('2021-05-25', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (90, 'Chrissie Eckh', 'ceckh2h@marketwatch.com', '346-583-0786', TO_DATE('2013-11-14', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (91, 'Patin MacMakin', 'pmacmakin2i@mozilla.org', '521-469-9869', TO_DATE('2017-12-02', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (92, 'Tonya Melchior', 'tmelchior2j@xinhuanet.com', '556-119-2747', TO_DATE('2019-05-30', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (93, 'Omar McCarty', 'omccarty2k@pcworld.com', '441-229-2312', TO_DATE('2011-08-30', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (94, 'Hallie Stritton', 'hstritton2l@princeton.edu', '485-474-5694', TO_DATE('2021-02-10', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (95, 'Paton Dunkerton', 'pdunkerton2m@hhs.gov', '207-624-7641', TO_DATE('2022-01-03', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (96, 'Robinette Westrip', 'rwestrip2n@accuweather.com', '754-462-7288', TO_DATE('2018-08-27', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (97, 'Vladimir Jaffrey', 'vjaffrey2o@cdbaby.com', '882-276-1105', TO_DATE('2013-12-10', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (98, 'Josey Daleman', 'jdaleman2p@archive.org', '918-124-6707', TO_DATE('2014-05-07', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (99, 'Karie Blenkinsopp', 'kblenkinsopp2q@sakura.ne.jp', '411-901-9464', TO_DATE('2012-03-29', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (100, 'Kissie Guyers', 'kguyers2r@about.me', '270-658-5806', TO_DATE('2010-08-11', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (101, 'Salaidh Claybourn', 'sclaybourn2s@icq.com', '743-925-8605', TO_DATE('2014-02-15', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (102, 'Karina Venes', 'kvenes2t@friendfeed.com', '847-867-9298', TO_DATE('2018-05-15', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (103, 'Gwenette Willmetts', 'gwillmetts2u@toplist.cz', '136-557-3484', TO_DATE('2019-03-29', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (104, 'Vita Brandle', 'vbrandle2v@hao123.com', '504-925-8606', TO_DATE('2017-05-30', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (105, 'Ward Tabary', 'wtabary2w@ca.gov', '874-895-4755', TO_DATE('2019-11-12', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (106, 'Birch Whittlesee', 'bwhittlesee2x@ifeng.com', '589-813-1607', TO_DATE('2011-01-13', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (107, 'Hiram Ashall', 'hashall2y@slashdot.org', '350-981-4695', TO_DATE('2014-02-17', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (108, 'Dee dee Ryall', 'ddee2z@usda.gov', '602-336-7992', TO_DATE('2024-04-07', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (109, 'Sara-ann O''Teague', 'soteague30@hud.gov', '902-781-2512', TO_DATE('2013-04-06', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (110, 'Gustavo Boolsen', 'gboolsen31@goodreads.com', '195-692-9752', TO_DATE('2020-06-21', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (111, 'Bernardo Morden', 'bmorden32@e-recht24.de', '830-961-9037', TO_DATE('2016-11-24', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (112, 'Ado Gwinnell', 'agwinnell33@gov.uk', '388-493-8395', TO_DATE('2013-11-26', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (113, 'Haley Ronaghan', 'hronaghan34@xing.com', '978-867-2361', TO_DATE('2018-08-09', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (114, 'Winne Doy', 'wdoy35@cloudflare.com', '896-724-7406', TO_DATE('2020-12-18', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (115, 'Keely Monard', 'kmonard36@bloglovin.com', '572-629-1002', TO_DATE('2025-05-05', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (116, 'Nara Rodda', 'nrodda37@linkedin.com', '248-143-3029', TO_DATE('2014-06-11', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (117, 'Trescha Blogg', 'tblogg38@studiopress.com', '102-658-1283', TO_DATE('2013-06-13', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (118, 'Talbot Bolderstone', 'tbolderstone39@mapy.cz', '219-750-1798', TO_DATE('2017-07-22', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (119, 'Sybil Bossons', 'sbossons3a@homestead.com', '728-970-1980', TO_DATE('2012-01-27', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (120, 'Gerome Di Francesco', 'gdi3b@yahoo.com', '490-931-3320', TO_DATE('2016-09-04', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (121, 'Morrie Isenor', 'misenor3c@columbia.edu', '139-771-1395', TO_DATE('2020-07-09', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (122, 'North Vedekhov', 'nvedekhov3d@stanford.edu', '275-187-3824', TO_DATE('2010-02-26', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (123, 'Beckie Benzing', 'bbenzing3e@smugmug.com', '227-397-6823', TO_DATE('2011-07-11', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (124, 'Levon Halpen', 'lhalpen3f@multiply.com', '620-905-3247', TO_DATE('2017-01-19', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (125, 'Angelita Riches', 'ariches3g@opera.com', '133-625-4846', TO_DATE('2024-10-13', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (126, 'Yvonne Birkby', 'ybirkby3h@sohu.com', '899-288-5465', TO_DATE('2023-01-07', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (127, 'Kristy Matteotti', 'kmatteotti3i@addtoany.com', '553-520-7547', TO_DATE('2017-04-08', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (128, 'Rubie Garbar', 'rgarbar3j@about.me', '702-293-2336', TO_DATE('2022-04-27', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (129, 'Othelia Muscat', 'omuscat3k@google.pl', '144-403-8795', TO_DATE('2022-04-03', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (130, 'Olive Mocker', 'omocker3l@vistaprint.com', '421-415-9606', TO_DATE('2017-04-07', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (131, 'Pincas Boissier', 'pboissier3m@cloudflare.com', '934-806-0105', TO_DATE('2020-02-25', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (132, 'Gui Chaundy', 'gchaundy3n@uol.com.br', '768-752-6641', TO_DATE('2011-06-22', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (133, 'Lawrence Mixture', 'lmixture3o@google.it', '464-139-3119', TO_DATE('2018-02-10', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (134, 'Tucker Enocksson', 'tenocksson3p@sciencedirect.com', '748-564-1188', TO_DATE('2023-01-23', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (135, 'Isa Basillon', 'ibasillon3q@purevolume.com', '972-620-7366', TO_DATE('2011-07-05', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (136, 'Adelle MacColm', 'amaccolm3r@mashable.com', '385-382-4569', TO_DATE('2019-11-24', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (137, 'Bab Geraldi', 'bgeraldi3s@sun.com', '339-960-4690', TO_DATE('2025-04-14', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (138, 'Wright Hairesnape', 'whairesnape3t@geocities.com', '773-119-1490', TO_DATE('2014-12-11', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (139, 'Korey Tant', 'ktant3u@webmd.com', '511-509-7869', TO_DATE('2013-05-08', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (140, 'Averill Nabbs', 'anabbs3v@ameblo.jp', '732-897-9480', TO_DATE('2020-08-28', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (141, 'Wilfrid Zettoi', 'wzettoi3w@msn.com', '749-646-1857', TO_DATE('2015-07-23', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (142, 'Deerdre See', 'dsee3x@marriott.com', '615-886-6792', TO_DATE('2015-05-14', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (143, 'Joellyn Prettyman', 'jprettyman3y@devhub.com', '586-982-7722', TO_DATE('2014-07-19', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (144, 'Hannah Gowry', 'hgowry3z@moonfruit.com', '865-786-2029', TO_DATE('2011-03-16', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (145, 'Archibald Danneil', 'adanneil40@sbwire.com', '658-667-3307', TO_DATE('2025-06-19', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (146, 'Ephraim Bairstow', 'ebairstow41@php.net', '777-164-9672', TO_DATE('2018-08-03', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (147, 'Manya Cowitz', 'mcowitz42@opera.com', '979-381-6105', TO_DATE('2024-11-12', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (148, 'Sibel Legerwood', 'slegerwood43@dmoz.org', '972-313-3476', TO_DATE('2014-05-30', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (149, 'Ailyn Gaskarth', 'agaskarth44@google.co.uk', '599-223-5311', TO_DATE('2013-08-28', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (150, 'Brynna Tourmell', 'btourmell45@accuweather.com', '967-102-4943', TO_DATE('2022-05-14', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (151, 'Archaimbaud Wickrath', 'awickrath46@cnn.com', '433-105-6538', TO_DATE('2011-04-10', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (152, 'Marita Nolan', 'mnolan47@sun.com', '407-440-8098', TO_DATE('2025-04-04', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (153, 'Derrik Barcke', 'dbarcke48@linkedin.com', '954-524-4056', TO_DATE('2024-12-30', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (154, 'Dalton Overbury', 'doverbury49@wunderground.com', '161-476-8422', TO_DATE('2015-02-28', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (155, 'Yuma Eddleston', 'yeddleston4a@live.com', '503-570-8624', TO_DATE('2018-07-14', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (156, 'Daile Franzke', 'dfranzke4b@360.cn', '988-201-7883', TO_DATE('2014-03-19', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (157, 'Vassili Landon', 'vlandon4c@redcross.org', '548-149-0373', TO_DATE('2016-10-11', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (158, 'Ruben East', 'reast4d@foxnews.com', '664-204-2225', TO_DATE('2024-03-10', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (159, 'Carmela Cruddace', 'ccruddace4e@desdev.cn', '855-723-2634', TO_DATE('2016-02-09', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (160, 'Boony Roostan', 'broostan4f@craigslist.org', '902-356-1014', TO_DATE('2015-05-16', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (161, 'Maribeth Gateman', 'mgateman4g@live.com', '126-236-1761', TO_DATE('2021-03-29', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (162, 'Christos Cosh', 'ccosh4h@trellian.com', '793-106-4188', TO_DATE('2013-01-27', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (163, 'Pavla Gartery', 'pgartery4i@spiegel.de', '365-836-9176', TO_DATE('2013-05-18', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (164, 'Shem Airs', 'sairs4j@xing.com', '565-981-4243', TO_DATE('2014-10-04', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (165, 'Adelbert Jennery', 'ajennery4k@cam.ac.uk', '452-522-9541', TO_DATE('2011-07-23', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (166, 'Noreen Cathel', 'ncathel4l@tmall.com', '495-364-8005', TO_DATE('2013-08-29', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (167, 'Elsey Penylton', 'epenylton4m@goo.ne.jp', '326-208-1502', TO_DATE('2013-01-20', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (168, 'Malory MacLachlan', 'mmaclachlan4n@cam.ac.uk', '482-780-4999', TO_DATE('2016-10-01', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (169, 'Dierdre Le Fleming', 'dle4o@phoca.cz', '394-726-4781', TO_DATE('2010-05-01', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (170, 'Diarmid Sauvage', 'dsauvage4p@apple.com', '192-224-9884', TO_DATE('2017-12-27', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (171, 'Porter Eicheler', 'peicheler4q@weebly.com', '294-176-3373', TO_DATE('2022-04-20', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (172, 'Annabella Stoneley', 'astoneley4r@elegantthemes.com', '997-531-8487', TO_DATE('2025-04-13', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (173, 'Elonore Rickets', 'erickets4s@ovh.net', '114-420-1589', TO_DATE('2010-05-05', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (174, 'Pattie Adger', 'padger4t@delicious.com', '954-373-7123', TO_DATE('2010-12-25', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (175, 'Darrel Sutter', 'dsutter4u@shinystat.com', '602-405-6936', TO_DATE('2011-08-16', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (176, 'Leland Pasterfield', 'lpasterfield4v@devhub.com', '147-735-9268', TO_DATE('2016-03-05', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (177, 'Katlin Niesel', 'kniesel4w@nasa.gov', '306-510-1529', TO_DATE('2011-06-28', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (178, 'Kylie Davidwitz', 'kdavidwitz4x@marketwatch.com', '538-515-5782', TO_DATE('2021-10-20', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (179, 'Alejandra Jankovic', 'ajankovic4y@woothemes.com', '299-263-7269', TO_DATE('2022-04-13', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (180, 'Enriqueta Tayspell', 'etayspell4z@baidu.com', '307-880-1816', TO_DATE('2023-01-06', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (181, 'Carey Pidgeley', 'cpidgeley50@vk.com', '161-592-9595', TO_DATE('2024-12-05', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (182, 'Wren Chellingworth', 'wchellingworth51@devhub.com', '850-851-5890', TO_DATE('2016-04-16', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (183, 'Saidee Spawell', 'sspawell52@aboutads.info', '381-906-9547', TO_DATE('2012-09-09', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (184, 'Tad Tice', 'ttice53@ameblo.jp', '968-101-2832', TO_DATE('2010-04-24', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (185, 'Chuck Bardill', 'cbardill54@cbslocal.com', '502-815-0227', TO_DATE('2013-08-06', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (186, 'Merle Welldrake', 'mwelldrake55@networkadvertising.org', '730-272-9929', TO_DATE('2013-09-21', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (187, 'Nalani Matasov', 'nmatasov56@liveinternet.ru', '476-985-9156', TO_DATE('2023-12-02', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (188, 'Barbette Arman', 'barman57@friendfeed.com', '816-706-4380', TO_DATE('2021-12-03', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (189, 'Hillary Sollis', 'hsollis58@taobao.com', '871-553-6009', TO_DATE('2017-05-28', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (190, 'Ursa Erdely', 'uerdely59@myspace.com', '924-744-4863', TO_DATE('2014-01-27', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (191, 'Moss Branwhite', 'mbranwhite5a@home.pl', '884-210-1670', TO_DATE('2020-07-20', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (192, 'Pamella Giacomoni', 'pgiacomoni5b@privacy.gov.au', '375-921-8722', TO_DATE('2011-03-07', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (193, 'Mahala Serjeantson', 'mserjeantson5c@free.fr', '444-104-1037', TO_DATE('2015-04-25', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (194, 'Nanon Lackemann', 'nlackemann5d@hud.gov', '426-112-9293', TO_DATE('2015-02-20', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (195, 'Clemmy Aicheson', 'caicheson5e@4shared.com', '919-649-9476', TO_DATE('2018-04-01', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (196, 'Fairlie Esseby', 'fesseby5f@hao123.com', '637-933-7955', TO_DATE('2010-12-03', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (197, 'Jesus Thorp', 'jthorp5g@ox.ac.uk', '142-732-1710', TO_DATE('2012-10-26', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (198, 'Shayne Mortel', 'smortel5h@51.la', '521-726-0849', TO_DATE('2013-04-15', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (199, 'Anabella Kopman', 'akopman5i@booking.com', '689-776-1864', TO_DATE('2013-10-01', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (200, 'Kandy Bowle', 'kbowle5j@dyndns.org', '119-488-9208', TO_DATE('2023-07-07', 'YYYY-MM-DD'));
insert into EMPLOYEES (employee_id, name, email, phone_number, date_of_joining) values (201, 'Megen Steer', 'msteer5k@loc.gov', '910-647-4381', TO_DATE('2021-08-06', 'YYYY-MM-DD'));

COMMIT;

