class CreateHarmonyTables < ActiveRecord::Migration[5.1]
  def up
    connection.execute <<-SQL
    CREATE TABLE `harmony_bookables` (
      `id` binary(16) NOT NULL,
      `marketplace_id` binary(16) NOT NULL,
      `ref_id` binary(16) NOT NULL,
      `author_id` binary(16) NOT NULL,
      `unit_type` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'day',
      `active_plan_id` binary(16) DEFAULT NULL,
      `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      UNIQUE KEY `index_bookables_marketplace_refid` (`marketplace_id`,`ref_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    SQL

    connection.execute <<-SQL
    CREATE TABLE `harmony_bookings` (
      `id` binary(16) NOT NULL,
      `marketplace_id` binary(16) NOT NULL,
      `bookable_id` binary(16) NOT NULL,
      `customer_id` binary(16) NOT NULL,
      `status` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'initial',
      `seats` int(11) NOT NULL DEFAULT '1',
      `start` datetime NOT NULL,
      `end` datetime NOT NULL,
      `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      KEY `index_bookings_bookable_status` (`bookable_id`,`status`),
      KEY `index_bookings_marketplace_bookable` (`bookable_id`,`marketplace_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    SQL

    connection.execute <<-SQL
    CREATE TABLE `harmony_exceptions` (
      `id` binary(16) NOT NULL,
      `marketplace_id` binary(16) NOT NULL,
      `type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
      `bookable_id` binary(16) NOT NULL,
      `seats_override` int(11) DEFAULT NULL,
      `start` datetime NOT NULL,
      `end` datetime NOT NULL,
      `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted` tinyint(1) NOT NULL DEFAULT '0',
      PRIMARY KEY (`id`),
      KEY `index_bookings_marketplace_exceptions` (`bookable_id`,`marketplace_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    SQL

    connection.execute <<-SQL
    CREATE TABLE `harmony_plans` (
      `id` binary(16) NOT NULL,
      `marketplace_id` binary(16) NOT NULL,
      `bookable_id` binary(16) NOT NULL,
      `seats` int(11) NOT NULL DEFAULT '1',
      `plan_mode` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'available',
      `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      KEY `index_plans_marketplace_bookable` (`marketplace_id`,`bookable_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    SQL
  end

  def down
    drop_table :harmony_bookables
    drop_table :harmony_bookings
    drop_table :harmony_exceptions
    drop_table :harmony_plans
  end
end
