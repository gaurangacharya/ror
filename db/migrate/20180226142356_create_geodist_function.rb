class CreateGeodistFunction < ActiveRecord::Migration[5.1]
  def up
    connection.execute <<-SQL
    CREATE FUNCTION FD_GEODIST(src_lat float, src_lon float, dst_lat float, dst_lon float) RETURNS FLOAT DETERMINISTIC
    BEGIN
      SET @dist := 6371 * 2 * ASIN(SQRT(POWER(SIN((src_lat - ABS(dst_lat)) * PI()/180 / 2), 2) +
          COS(src_lat * PI()/180) * COS(ABS(dst_lat) * PI()/180) * POWER(SIN((src_lon - dst_lon) * PI()/180 / 2), 2))) * 1000;
       RETURN @dist;
    END
    SQL
  end

  def down
    connection.execute "DROP FUNCTION IF EXISTS FD_GEODIST"
  end
end
