class AddRunIntervalStylesTable < ActiveRecord::Migration
  def up
    execute <<-SQL
	    CREATE TABLE #{Naf.schema_name}.run_interval_styles
	    (
	    	id 							SERIAL NOT NULL PRIMARY KEY,
	    	created_at 			TIMESTAMP NOT NULL default now(),
	    	name 						TEXT NOT NULL
	    );

			INSERT INTO #{Naf.schema_name}.run_interval_styles (name)
				VALUES ('at beginning of day'), ('at beginning of hour'), ('after previous run'), ('keep running');

			ALTER TABLE #{Naf.schema_name}.application_schedules
				ADD COLUMN run_interval_style_id INTEGER NULL REFERENCES #{Naf.schema_name}.run_interval_styles;
			ALTER TABLE #{Naf.schema_name}.application_schedules
				DROP CONSTRAINT application_schedules_check1;
    SQL
  end

  def down
    execute <<-SQL
    	ALTER TABLE #{Naf.schema_name}.application_schedules ADD CONSTRAINT application_schedules_check1
    		CHECK (run_start_minute IS NULL OR run_interval IS NULL);
      ALTER TABLE #{Naf.schema_name}.application_schedules DROP COLUMN run_interval_style_id;
      DROP TABLE #{Naf.schema_name}.run_interval_styles;
    SQL
  end
end
