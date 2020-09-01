CREATE DATABASE IF NOT EXISTS business_sql;

-- ЗАДАНИЕ 1

CREATE TABLE t_provider (
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(45) NOT NULL UNIQUE
);

CREATE TABLE t_schedule (
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    `type` VARCHAR(15) NOT NULL UNIQUE
);

CREATE TABLE t_contractor_scheduler (
    provider_id INT NOT NULL,
    schedule_id INT NOT NULL,
    date_begin DATETIME NOT NULL,
    date_end DATETIME NOT NULL,
    CONSTRAINT check_date_begin CHECK (DATEDIFF(date_end, date_begin) > 0),
    FOREIGN KEY (provider_id)
        REFERENCES t_provider (id)
        ON DELETE CASCADE,
    PRIMARY KEY (provider_id , date_begin)
);

-- ЗАПОЛНЕНИЕ БД данными
INSERT INTO t_provider (`name`) VALUES ('Поставщик 1');
INSERT INTO t_provider (`name`) VALUES ('Поставщик 2');
INSERT INTO t_provider (`name`) VALUES ('Поставщик 3');

INSERT INTO t_schedule (`type`) VALUES ('дддвсвнн');
INSERT INTO t_schedule (`type`) VALUES ('ннвннв');
INSERT INTO t_schedule (`type`) VALUES ('св');
INSERT INTO t_schedule (`type`) VALUES ('свсвсв');
INSERT INTO t_schedule (`type`) VALUES ('днвсв');
INSERT INTO t_schedule (`type`) VALUES ('ннддвсв');
INSERT INTO t_schedule (`type`) VALUES ('нвнвнв');
INSERT INTO t_schedule (`type`) VALUES ('двдвдвдв');

INSERT INTO t_contractor_scheduler (
	provider_id, schedule_id, date_begin, date_end)
VALUES (1, 1, '2019-01-01 00:00', '2019-01-10 00:00');
INSERT INTO t_contractor_scheduler (
	provider_id, schedule_id, date_begin, date_end)
VALUES (1, 2, '2019-01-11 00:00', '2019-01-15 00:00');
INSERT INTO t_contractor_scheduler (
	provider_id, schedule_id, date_begin, date_end)
VALUES (1, 3, '2019-01-16 00:00', '2019-01-20 00:00');
INSERT INTO t_contractor_scheduler (
	provider_id, schedule_id, date_begin, date_end)
VALUES (2, 4, '2019-01-01 00:00', '2019-01-07 00:00');
INSERT INTO t_contractor_scheduler (
	provider_id, schedule_id, date_begin, date_end)
VALUES (2, 5, '2019-01-08 00:00', '2019-01-14 00:00');
INSERT INTO t_contractor_scheduler (
	provider_id, schedule_id, date_begin, date_end)
VALUES (2, 6, '2019-01-15 00:00', '9999-12-31 00:00');
INSERT INTO t_contractor_scheduler (
	provider_id, schedule_id, date_begin, date_end)
VALUES (3, 7, '2019-01-01 00:00', '2019-02-01 00:00');
INSERT INTO t_contractor_scheduler (
	provider_id, schedule_id, date_begin, date_end)
VALUES (3, 8, '2019-02-02 00:00', '9999-12-31 00:00');

-- ЗАДАНИЕ 2

CREATE TABLE t_contractor_work_day (
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(45) NOT NULL,
    date_begin DATETIME NOT NULL,
    date_end DATETIME NOT NULL
);

-- ЗАДАНИЕ 3

CREATE TABLE t_work_mode (
    `type` CHAR(1) NOT NULL PRIMARY KEY,
    time_begin TIME NOT NULL,
    duration TIME NOT NULL
);

INSERT INTO t_work_mode (`type`, time_begin, duration)
VALUES ('д', '08:00:00', '12:00:00');
INSERT INTO t_work_mode (`type`, time_begin, duration)
VALUES ('н', '20:00:00', '12:00:00');
INSERT INTO `t_work_mode` (`type`, time_begin, duration)
VALUES ('с', '08:00:00', '24:00:00');

DELIMITER $$
CREATE PROCEDURE add_contractor_work_days 
	(IN date_start DATETIME, IN date_finish DATETIME)
BEGIN
	DECLARE provider_name VARCHAR(45);
    DECLARE schedule_type VARCHAR(15);
    DECLARE date_begin_ DATETIME;
    DECLARE date_end_ DATETIME;
    
    DECLARE date_from DATETIME;
	DECLARE date_until DATETIME;
    DECLARE date_current DATETIME;
    
    DECLARE schedule_length INT;
    DECLARE counter INT;
	
    DECLARE work_mode_type CHAR(1);
    DECLARE work_time_begin TIME;
    DECLARE work_time_duration TIME;
    
    DECLARE work_datetime_begin DATETIME;

	DECLARE is_finished BOOL DEFAULT FALSE;
    
    DECLARE scheduler_cursor CURSOR FOR 
		SELECT * FROM 
			(SELECT `name` AS provider_name, `type` AS schedule_type, date_begin, date_end
				FROM t_provider AS p
				INNER JOIN t_contractor_scheduler AS t_c_scheduler
				ON p.id = t_c_scheduler.provider_id
				INNER JOIN t_schedule AS s
				ON  schedule_id = s.id) AS t
		WHERE date_start <= date_end AND date_begin <= date_finish;
        
	DECLARE CONTINUE HANDLER 
    FOR NOT FOUND SET is_finished = TRUE;
    
   OPEN scheduler_cursor;
   
   get_schedule: LOOP
   
		FETCH scheduler_cursor
        INTO provider_name, schedule_type, date_begin_, date_end_;
        
        IF is_finished = TRUE THEN
			LEAVE get_schedule;
		END IF;
        
        SET date_from = IF (date_start > date_begin_, 
							 date_start, date_begin_);
                             
        SET date_until = IF (date_finish < date_end_, 
							 date_finish, date_end_);
        
        SET date_current = date_from;
        
        SET schedule_length = CHAR_LENGTH(schedule_type);
        SET counter = 0;
        
        add_work_day: REPEAT
			SET work_mode_type = SUBSTR(schedule_type, 
										counter % schedule_length + 1, 
										1);
                                   
			IF work_mode_type != 'в' THEN
				SELECT time_begin, duration 
                FROM t_work_mode WHERE `type` = work_mode_type 
                INTO work_time_begin, work_time_duration;
                
                IF work_time_begin IS NOT NULL THEN
					SET work_datetime_begin = ADDTIME(date_current, work_time_begin);
					
					INSERT INTO t_contractor_work_day (
					`name`, date_begin, date_end)
					VALUES (provider_name, 
							work_datetime_begin,
							ADDTIME(work_datetime_begin, 
									work_time_duration));
				ELSE 
					SELECT 'Unknown work mode' AS 'Work mode error';
                    
				END IF;
			END IF;
            
			            
            SET counter = counter + 1;
            SET date_current = DATE_ADD(date_current, 
										INTERVAL 1 DAY);
                                    
		UNTIL date_current > date_until
        END REPEAT;
        
   END LOOP;
   CLOSE scheduler_cursor;
    
END$$

DELIMITER ;

-- ЗАДАНИЕ 4

DROP procedure add_contractor_work_days;

CALL add_contractor_work_days('2019-01-01 00:00:00',
							  '2019-03-02 00:00:00');

-- Выборка, содержащая сколько рабочих дней было у каждого поставщика
SELECT 
    `name`, COUNT(*) AS count
FROM
    t_contractor_work_day
GROUP BY `name`;

-- Выборка поставщиков, у которыйх было больше 10 рабочих дней за январь 2019 года
SELECT 
    `name`
FROM
    (SELECT 
        `name`, COUNT(*) AS count
    FROM
        t_contractor_work_day
    WHERE
        MONTH(date_begin) = 1
            AND YEAR(date_begin) = 2019
    GROUP BY `name`) AS t
WHERE
    t.count > 10;

-- Выборка поставщиков, кто работал 14, 15 и 16 января 2019 года
SELECT DISTINCT
    `name`
FROM
    t_contractor_work_day
WHERE
    MONTH(date_begin) = 1
        AND YEAR(date_begin) = 2019
        AND DAY(date_begin) = 14
        OR DAY(date_begin) = 15
        OR DAY(date_begin) = 16;









