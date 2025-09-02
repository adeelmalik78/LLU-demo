--liquibase formatted sql

--changeset nvoxland:DB-1022 runOnChange:true
--precondition OnFail:HALT onError:HALT
--precondition-sql-check expectedResult:0 SELECT COUNT(*) FROM employee
INSERT INTO employee (id, name, address1, address2, city)
   VALUES(10, 'Nathan', '5 State St.', '', '¿Minneapolis');
INSERT INTO employee (id, name, address1, address2, city)
   VALUES(20, 'Adeel', '201 Park Ave.', '', 'New York');
INSERT INTO employee (id, name, address1, address2, city)
   VALUES(30, 'Annette', '85 Lincoln Blvd.', '', 'Austin');
INSERT INTO employee (id, name, address1, address2, city)
   VALUES(40, 'Lelsey', '8981 Commonwealth Ave.', '', 'Boston');
-- INSERT INTO employee (id, name, address1, address2, city)
--    VALUES(50, 'Annie', '3939 Tom Holland Way', '', 'London¿');

--rollback TRUNCATE TABLE employee;