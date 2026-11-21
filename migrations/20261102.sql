do $$
begin

	-- Создаем новые структуры
	begin
		
		-- Таблица стандартных высот
		create sequence calc_correction_height_seq;
		create table calc_correction_heights
		(
		        id integer primary key not null default nextval('public.calc_correction_height_seq'),
		        height integer not null
		);
		
		
		insert into calc_correction_heights(height)
		values(200),(400),(800),(1200),(1600),(2000),(2400),(3000),(4000);
	
		comment on table calc_correction_heights is 'Таблица стандартных высот';
		comment on column calc_correction_heights.id is 'Уникальный код';
		comment on column calc_correction_heights.height is 'Высота';
	
		-- Справочник типов таблиц корректировок
		create sequence calc_correction_types_seq;
		create table calc_correction_types
		(
		        id integer not null primary key default nextval('public.calc_correction_types_seq'),
		        parent_id integer,
		        measurment_equipment_id integer,
		        description text not null,
		        header_values integer[]
		);
	
		comment on table calc_correction_types is 'Справочник типов таблиц с собственными заголовками';
		comment on column calc_correction_types.id is 'Уникальный код';
		comment on column calc_correction_types.parent_id is 'Уникальный код владельца - тип таблицы';
		comment on column calc_correction_types.measurment_equipment_id is 'Тип оборудования';
		comment on column calc_correction_types.description is 'Описание к таблице';
		comment on column calc_correction_types.header_values is 'Значения в заголовке таблице';

		-- Универсальная таблица корректировок
		create sequence calc_correction_seq;
		create table calc_correction
		(
		        id integer not null primary key default nextval('public.calc_correction_seq'),
		        height_id integer not null,
		        type_id integer not null,
		        row_values integer[]
		);

		comment on table calc_correction is 'Универсальная таблица корректировок';
		comment on column calc_correction.id is 'Уникальный код';
		comment on column calc_correction.height_id is 'Код высоты';
		comment on column calc_correction.type_id is 'Код типа таблиц';
		comment on column calc_correction.row_values is 'Значения с корректировками';

	end;	

	-- Добавляем данные
	begin

		
		insert into calc_correction_types(  description, header_values)
		values( 'Таблица 2', array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]),  -- 1
		( 'Таблица 3, скорость среднего ветра', null), -- 2
		( 'Таблица 3, направление среднего ветра', null);       -- 3

		insert into calc_correction_types( description, parent_id, measurment_equipment_id, header_values)
		values
		('Таблица 3, Скорость среднего ветра (ВР)', 2, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]), -- 4
		('Таблица 3, Направление среднего ветра (ВР)',3, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]), -- 5
		('Таблица 3, Скорость среднего ветра (ДМК)',2, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]), -- 6
		('Таблица 3, Направление среднего ветра (ДМК)',3, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]); -- 7
		
		insert into calc_correction_types( description, parent_id, header_values)
		values('Таблица 2, Отрицательные температуры', 1, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]), -- 8
		('Таблица 2, Положительные температуры', 1, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]) --9
		;

		
		insert into calc_correction(height_id, type_id, row_values )
		-- Таблица 2, отрицательные значения
		values(1, 8, array[-1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49]), -- 200
		(2, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -38, -48]), -- 400
		(3, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46]), -- 800
		(4, 8, array[-1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44]), -- 1200
		(5, 8, array[-1, -2, -3, -3, -4, -4, -5, -6, -7, -7, -17, -25, -34, -42]), -- 1600
		(6, 8, array[-1, -2, -3, -3, -4, -4, -5, -6, -6, -7, -16, -24, -32, -40]), -- 2000
		(7, 8, array[-1, -2, -2, -3, -4, -4, -5, -5, -6, -7, -15, -23, -31, -38]), -- 2400
		(8, 8, array[-1, -2, -2, -3, -4, -4, -4, -5, -5, -6, -15, -22, -30, -37]), -- 3000
		(9, 8, array[-1, -2, -2, -3, -4, -4, -4, -4, -5, -6, -14, -20, -27, -34]), -- 4000
		-- Таблица 2, положительные значения
		(1, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 200
		(2, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 400
		(3, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 800
		(4, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 1200
		(5, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 1600
		(6, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 2000
		(7, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 2400
		(8, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 3000
		(9, 9, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 4000
		-- Таблица 3, Скорость среднего ветра (ВР)
		(1, 4, array[3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 12]), -- 200
		(2, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]), -- 400
		(3, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16]), -- 800
		(4, 4, array[4, 5, 7, 8, 8, 9, 11, 12, 13, 15, 15, 16]), -- 1200
		(5, 4, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 15, 17, 17]), -- 1600
		(6, 4, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 16, 17, 18]), -- 2000
		(7, 4, array[4, 6, 8, 9, 9, 10, 12, 14, 15, 16, 18, 19]), -- 2400
		(8, 4, array[5, 6, 8, 9, 10, 11, 12, 14, 15, 17, 18, 19]), -- 3000
		(9, 4, array[5, 6, 8, 9, 10, 11, 12, 14, 16, 18, 19, 20]), -- 4000
		-- Таблица 3, Направление среднего ветра (ВР)
		(1, 5, array[0]), -- 200
		(2, 5, array[1]), -- 400
		(3, 5, array[2]), -- 800
		(4, 5, array[2]), -- 1200
		(5, 5, array[3]), -- 1600
		(6, 5, array[3]), -- 2000
		(7, 5, array[3]), -- 2400
		(8, 5, array[4]), -- 3000
		(9, 5, array[4]), -- 4000
		-- Таблица 3, Скорость среднего ветра (ДМК)
		(1, 6, array[4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22]), -- 200
		(2, 6, array[5, 7, 10, 11, 12, 14, 17, 18, 20, 22, 23, 25, 27]), -- 400
		(3, 6, array[5, 8, 10, 11, 13, 15, 18, 19, 21, 23, 25, 27, 28]), -- 800
		(4, 6, array[5, 8, 11, 12, 13, 16, 19, 20, 22, 24, 26, 28, 30]), -- 1200
		(5, 6, array[6, 8, 11, 13, 14, 17, 20, 21, 23, 25, 27, 29, 32]), -- 1600
		(6, 6, array[6, 9, 11, 13, 14, 17, 20, 21, 24, 26, 28, 30, 32]), -- 2000
		(7, 6, array[6, 9, 12, 14, 15, 18, 21, 22, 25, 27, 29, 32, 34]), -- 2400
		(8, 6, array[6, 9, 12, 14, 15, 18, 21, 23, 25, 28, 30, 32, 36]), -- 3000
		(9, 6, array[6, 10, 12, 14, 16, 19, 22, 24, 26, 29, 32, 34, 36]), -- 4000
		-- Таблица 3, Направление среднего ветра (ДМК)
		(1, 7, array[1]), -- 200
		(2, 7, array[2]), -- 400
		(3, 7, array[3]), -- 800
		(4, 7, array[3]), -- 1200
		(5, 7, array[4]), -- 1600
		(6, 7, array[4]), -- 2000
		(7, 7, array[4]), -- 2400
		(8, 7, array[5]), -- 3000
		(9, 7, array[5]) -- 4000
		;
		
	end;

	-- Прочее
	begin
		-- Наименование подправлю
		alter table public.calc_temperature_correction rename to calc_correction_temperature;
		
				
		CREATE OR REPLACE FUNCTION public.fn_calc_temperature_interpolation(
			par_temperature numeric)
		    RETURNS numeric
		    LANGUAGE 'plpgsql'
		    COST 100
		    VOLATILE PARALLEL UNSAFE
		AS $BODY$
				        declare 
				                var_interpolation interpolation_type;
				                var_result numeric(8,2) default 0;
				                var_min_temparure numeric(8,2) default 0;
				                var_max_temperature numeric(8,2) default 0;
				                var_denominator numeric(8,2) default 0;
				        begin
				
				                                raise notice 'Расчет интерполяции для температуры %', par_temperature;
				
				                -- Проверим, возможно температура совпадает со значением в справочнике
				                if exists (select 1 from public.calc_correction_temperature where temperature = par_temperature ) then
				                begin
				                        select correction 
				                        into  var_result 
				                        from  public.calc_correction_temperature
				                        where 
				                                temperature = par_temperature;
				                end;
				                else    
				                begin
				                        -- Получим диапазон в котором работают поправки
				                        select min(temperature), max(temperature) 
				                        into var_min_temparure, var_max_temperature
				                        from public.calc_correction_temperature;
				
				                        if par_temperature < var_min_temparure or   
				                           par_temperature > var_max_temperature then
				
				                                raise exception 'Некорректно передан параметр! Невозможно рассчитать поправку. Значение должно укладываться в диаппазон: %, %',
				                                        var_min_temparure, var_max_temperature;
				                        end if;   
				
				                        -- Получим граничные параметры
				
				                        select x0, y0, x1, y1 
				                                                 into var_interpolation.x0, var_interpolation.y0, var_interpolation.x1, var_interpolation.y1
				                        from
				                        (
				                                select t1.temperature as x0, t1.correction as y0
				                                from public.calc_correction_temperature as t1
				                                where t1.temperature <= par_temperature
				                                order by t1.temperature desc
				                                limit 1
				                        ) as leftPart
				                        cross join
				                        (
				                                select t1.temperature as x1, t1.correction as y1
				                                from public.calc_correction_temperature as t1
				                                where t1.temperature >= par_temperature
				                                order by t1.temperature 
				                                limit 1
				                        ) as rightPart;
				
				                        raise notice 'Граничные значения %', var_interpolation;
				                        var_result :=  fn_calc_interpolation( par_temperature,  var_interpolation);
				                                                 
				                end;
				                end if;
				
				                                return var_result;
				
				end;
				
		$BODY$;
		
		COMMENT ON FUNCTION public.fn_calc_temperature_interpolation(numeric)
		    IS 'Функция для расчета интерполяции для метео приближенный';
	end;

	commit;
	
end $$;