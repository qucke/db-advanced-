DO $$
BEGIN
    BEGIN
        CREATE TYPE test_result AS (
            x decimal(7,2),
            calced_y decimal(7,2),
            target_y decimal(7,2),
            is_pass bool		
        );
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END;
END $$;

CREATE OR REPLACE FUNCTION tests()
RETURNS SETOF test_result AS $$
DECLARE
    v_bounds calc_point;
    interpol decimal(7,2);
BEGIN
    v_bounds := get_temp_bounds_from_table(23);
    interpol := calc_interpolation(23, v_bounds);
    RETURN NEXT ROW(23, interpol, 1.8, interpol = 1.8)::test_result;

    v_bounds := get_temp_bounds_from_table(25);
    interpol := calc_interpolation(25, v_bounds);
    RETURN NEXT ROW(25, interpol, 2.0, interpol = 2.0)::test_result;

    v_bounds := get_temp_bounds_from_table(12);
    interpol := calc_interpolation(12, v_bounds);
    RETURN NEXT ROW(12, interpol, 1.0, interpol = 1.0)::test_result;

    v_bounds := get_temp_bounds_from_table(-5);
    interpol := calc_interpolation(-5, v_bounds);
    RETURN NEXT ROW(-5, interpol, 0.0, interpol = 0.0)::test_result;

    v_bounds := get_temp_bounds_from_table(35);
    interpol := calc_interpolation(35, v_bounds);
    RETURN NEXT ROW(35, interpol, 4.0, interpol = 4.0)::test_result;

    RETURN;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM tests();