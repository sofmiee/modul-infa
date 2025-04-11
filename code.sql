CREATE DATABASE company


CREATE TABLE employees(
id_ INT PRIMARY KEY,
name_ VARCHAR(100),
position_ VARCHAR(100),
salary DECIMAL
);
CREATE TABLE projects(
id_ INT PRIMARY KEY,
name_ VARCHAR(100),
budget DECIMAL
);
CREATE TABLE employee_projects(
employee_id INT,
FOREIGN KEY (employee_id) REFERENCES employees(id_),
project_id INT,
FOREIGN KEY(project_id) REFERENCES projects(id_),
role_in_project VARCHAR(100)
);


-- Создание ролей
CREATE ROLE admin_;  -- Роль администратора
CREATE ROLE manager_;  -- Роль менеджера
CREATE ROLE analyst_;  -- Роль аналитика

-- Назначение привилегий для роли администратора
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO admin_;

-- Назначение привилегий для роли менеджера
GRANT SELECT ON employees TO manager_;  -- Чтение данных из таблицы employees
GRANT SELECT ON projects TO manager_;  -- Чтение данных из таблицы projects
GRANT INSERT ON employee_projects TO manager_;   -- Добавление данных в таблицу employee_projects

-- Назначение привилегий для роли аналитика
GRANT SELECT ON projects TO analyst_;  -- Чтение данных из таблицы projects
GRANT SELECT ON employee_projects TO analyst_;    -- Чтение данных из таблицы employee_projects

-- Установка роли по умолчанию для новых объектов в схеме
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO manager_;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO analyst_;



CREATE OR REPLACE FUNCTION update_project_budget(p_project_id INT, p_new_budget DECIMAL(18, 2)) RETURNS VOID AS $$
BEGIN
    UPDATE projects
    SET budget = p_new_budget
    WHERE id_ = p_project_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка при обновлении бюджета проекта';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION assign_employee_to_project(p_project_id INT, p_employee_id INT) RETURNS VOID AS $$
BEGIN
    INSERT INTO employee_project (project_id, employee_id)
    VALUES (p_project_id, p_employee_id);

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка при назначении сотрудника на проект';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION remove_employee_from_project(p_project_id INT, p_employee_id INT) RETURNS VOID AS $$
BEGIN
    -- Удаление сотрудника из проекта
    DELETE FROM project_employees
    WHERE project_id = p_project_id AND employee_id = p_employee_id;

    -- Проверка, был ли удален сотрудник
    IF NOT FOUND THEN
        RAISE NOTICE 'Сотрудник не найден в проекте';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка при удалении сотрудника из проекта: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION create_new_project(p_project_name TEXT, p_budget DECIMAL(18, 2), p_employee_ids INT[] -- Массив ID сотрудников для назначения на проект) 
RETURNS VOID AS $$
DECLARE
    new_project_id INT;
    emp_id INT; -- Объявление переменной emp_id
BEGIN
    -- Создание нового проекта
    INSERT INTO projects (name_, budget)
    VALUES (p_project_name, p_budget)
    RETURNING project_id INTO new_project_id;

    -- Назначение сотрудников на проект
    FOREACH emp_id IN ARRAY p_employee_ids LOOP
        INSERT INTO project_employees (project_id, employee_id)
        VALUES (new_project_id, emp_id);
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка при создании нового проекта';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION delete_project(p_project_id INT) 
RETURNS VOID AS $$
BEGIN
    -- Удаление всех назначений сотрудников на проект
    DELETE FROM project_employees WHERE project_id = p_project_id;

    -- Удаление самого проекта
    DELETE FROM Projects WHERE project_id = p_project_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка при удалении проекта';
END;
$$ LANGUAGE plpgsql;
