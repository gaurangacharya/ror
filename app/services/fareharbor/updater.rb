require 'multi_logger'
require 'terminal_formatter'
require 'sentry_helper'

module Fareharbor
  class Updater
    attr_reader :person_fareharbor

    def initialize()
      @import_stats = {
        errors: [],
        created_listings: [],
        updated_listings: [],
        failed_listings: [],
        processed_companies: 0,
        failed_companies: 0
      }
    end

    def import_listings_active_companies
      TerminalFormatter.print_blank
      TerminalFormatter.print_header("STARTING FAREHARBOR IMPORT")
      TerminalFormatter.print_time("Starting at: #{Time.current}")
      TerminalFormatter.print_separator
      
      logger.info "=== STARTING IMPORT OF LISTINGS FOR ACTIVE COMPANIES ==="
      logger.info "Starting at: #{Time.current}"
      
      active_companies = FareharborCompany.active
      TerminalFormatter.print_chart("Found #{active_companies.count} active companies to process")
      logger.info "Found #{active_companies.count} active companies to process"
      
      processed_count = 0
      failed_count = 0
      start_time = Time.current
      
      active_companies.each_with_index do |company_to_import, index|
        TerminalFormatter.print_blank
        TerminalFormatter.print_progress(index + 1, active_companies.count, "Processing: #{company_to_import.shortname} (#{company_to_import.currency})")
        
        logger.info "[#{index + 1}/#{active_companies.count}] Processing company: #{company_to_import.shortname} (Currency: #{company_to_import.currency})"
        
        company = find_company(company_to_import.shortname, company_to_import.currency)
        if company
          TerminalFormatter.print_success("Found company via API")
          logger.info "✓ Successfully found company via API: #{company.shortname}"
          update_by_company(company)
          processed_count += 1
          @import_stats[:processed_companies] += 1
        else
          TerminalFormatter.print_error("Failed to find company via API")
          logger.warn "✗ Failed to find company via API: #{company_to_import.shortname}"
          
          # Track company-level error
          @import_stats[:errors] << {
            type: 'company_not_found',
            entity: 'company',
            entity_id: company_to_import.id,
            entity_name: company_to_import.shortname,
            error: "Company not found in FareHarbor API",
            currency: company_to_import.currency,
            timestamp: Time.current
          }
          
          # Report to Sentry
          SentryHelper.report_fareharbor_company_error(
            company_to_import.shortname,
            "Company not found in FareHarbor API",
            { currency: company_to_import.currency, company_id: company_to_import.id }
          )
          
          failed_count += 1
          @import_stats[:failed_companies] += 1
        end
      end
      
      duration = Time.current - start_time
      
      # Display detailed summary
      display_import_summary(processed_count, failed_count, active_companies.count, duration)
      
      # Report import statistics to Sentry
      SentryHelper.report_fareharbor_import_stats({
        processed: processed_count,
        failed: failed_count,
        total: active_companies.count,
        duration_seconds: duration.round(2),
        created_listings: @import_stats[:created_listings].count,
        updated_listings: @import_stats[:updated_listings].count,
        failed_listings: @import_stats[:failed_listings].count,
        errors: @import_stats[:errors].count
      })

      return nil
    end

    def import_companies(currency)
      logger.info "=== STARTING IMPORT OF COMPANIES (Currency: #{currency}) ==="
      logger.info "Starting at: #{Time.current}"
      
      begin
        api_companies = companies(currency)
        logger.info "Found #{api_companies.count} companies from FareHarbor API"
        
        processed_count = 0
        failed_count = 0
        
        api_companies.each_with_index do |company_to_import, index|
          logger.info "[#{index + 1}/#{api_companies.count}] Processing company: #{company_to_import.shortname}"
          
          company = find_company(company_to_import.shortname, currency)
          if company
            logger.info "✓ Successfully found company via API: #{company.shortname}"
            company_updater = ::Fareharbor::CompanyUpdater.new(
              logger: logger,
              fareharbor_company: company,
            )
            result = company_updater.run
            if result
              logger.info "✓ Successfully imported company: #{company.shortname}"
              processed_count += 1
            else
              logger.error "✗ Failed to import company: #{company.shortname}"
              failed_count += 1
            end
          else
            logger.warn "✗ Failed to find company via API: #{company_to_import.shortname}"
            failed_count += 1
          end
        end
        
        logger.info "=== COMPANY IMPORT COMPLETED ==="
        logger.info "Processed: #{processed_count}, Failed: #{failed_count}, Total: #{api_companies.count}"
        logger.info "Completed at: #{Time.current}"
        
      rescue => e
        logger.error "=== COMPANY IMPORT FAILED ==="
        logger.error "Error: #{e.message}"
        logger.error "Backtrace: #{e.backtrace.join($/)}"
        raise e
      end

      return nil
    end

    def import_single_company(shortname = nil, currency)
      target_shortname = shortname || single_company_name
      logger.info "=== STARTING SINGLE COMPANY IMPORT ==="
      logger.info "Target company: #{target_shortname} (Currency: #{currency})"
      logger.info "Starting at: #{Time.current}"
      
      company = find_company(target_shortname, currency)
      if company
        logger.info "✓ Successfully found company via API: #{company.shortname}"
        company_updater = ::Fareharbor::CompanyUpdater.new(
          logger: logger,
          fareharbor_company: company,
        )
        result = company_updater.run
        if result
          logger.info "✓ Successfully imported single company: #{company.shortname}"
        else
          logger.error "✗ Failed to import single company: #{company.shortname}"
        end
        logger.info "Completed at: #{Time.current}"
        return result
      else
        logger.error "✗ Failed to find single company via API: #{target_shortname}"
        logger.info "Completed at: #{Time.current}"
        return false
      end
    end

    def import_listings_single_company(shortname = nil, currency)
      target_shortname = shortname || single_company_name
      logger.info "=== STARTING SINGLE COMPANY LISTINGS IMPORT ==="
      logger.info "Target company: #{target_shortname} (Currency: #{currency})"
      logger.info "Starting at: #{Time.current}"
      
      company = find_company(target_shortname, currency)
      if company
        logger.info "✓ Successfully found company via API: #{company.shortname}"
        update_by_company(company)
        logger.info "✓ Completed single company listings import: #{company.shortname}"
      else
        logger.error "✗ Failed to find single company via API: #{target_shortname}"
      end
      
      logger.info "Completed at: #{Time.current}"
      return nil
    end

    def update_by_company(company)
      TerminalFormatter.print_subheader("Updating company: #{company.shortname}")
      
      logger.info "=== STARTING COMPANY UPDATE ==="
      logger.info "Company: #{company.shortname} (Currency: #{company.currency})"
      logger.info "Starting at: #{Time.current}"
      
      begin
        TerminalFormatter.print_api("Fetching items from FareHarbor API...")
        logger.info "Fetching items from FareHarbor API for company: #{company.shortname}"
        items = company.items
        items_count = items.count
        TerminalFormatter.print_success("Found #{items_count} items")
        logger.info "✓ Successfully fetched #{items_count} items from API"
      rescue => e
        TerminalFormatter.print_error("Failed to fetch items: #{e.message}")
        logger.error "✗ Failed to fetch items for company '#{company.shortname}': #{e.message}"
        logger.error "API Error Details: #{e.class.name} - #{e.inspect}"
        logger.error "Backtrace: #{e.backtrace.join($/)}"
        
        # Report to Sentry
        SentryHelper.report_fareharbor_error(e, {
          company_shortname: company.shortname,
          company_currency: company.currency,
          operation: "fetch_items"
        })
        
        return
      end
      
      logger.info "Creating PersonFareharbor record for tracking"
      create_person_fareharbor(company.shortname, items_count)
      
      updated_count = 0
      failed_count = 0
      
      TerminalFormatter.print_list("Processing #{items_count} items...")
      logger.info "Processing #{items_count} items for company: #{company.shortname}"
      items.each_with_index do |item, index|
        TerminalFormatter.print_step("[#{index + 1}/#{items_count}] #{item.name}")
        logger.info "[#{index + 1}/#{items_count}] Processing item: #{item.pk} - #{item.name}"
        
        begin
          listing_updater = ::Fareharbor::ListingUpdater.new(
            logger: logger,
            company: company,
            item: item,
          )
          listing_result = listing_updater.run
          
          if listing_result
            TerminalFormatter.print_success("Success")
            logger.info "✓ Successfully processed item: #{item.pk} - #{item.name}"
            unless person_fareharbor.person
              person_fareharbor.person = listing_updater.author
              person_fareharbor.save
              logger.info "✓ Associated person with FareHarbor company: #{listing_updater.author.username}"
            end
            person_fareharbor.increment(:updated)
            updated_count += 1
            
            # Track listing statistics
            track_listing_result(listing_result, company.shortname, item.pk, item.name)
          else
            TerminalFormatter.print_error("Failed")
            logger.warn "✗ Failed to process item: #{item.pk} - #{item.name}"
            
            # Track failed listing
            @import_stats[:failed_listings] << {
              company: company.shortname,
              item_id: item.pk,
              item_name: item.name,
              error: "Failed to process item",
              timestamp: Time.current
            }
            
            # Report to Sentry
            SentryHelper.report_fareharbor_item_error(
              company.shortname,
              item.pk,
              "Failed to process item",
              { item_name: item.name, currency: company.currency }
            )
            
            person_fareharbor.increment(:failed)
            failed_count += 1
          end
          person_fareharbor.save
        rescue => e
          TerminalFormatter.print_failed("Exception: #{e.message}")
          logger.error "✗ Exception processing item #{item.pk} - #{item.name}: #{e.message}"
          logger.error "Exception details: #{e.class.name} - #{e.inspect}"
          logger.error "Backtrace: #{e.backtrace.join($/)}"
          
          # Track error
          @import_stats[:errors] << {
            type: 'item_processing_error',
            entity: 'listing',
            entity_name: item.name,
            error: e.message,
            company: company.shortname,
            item_id: item.pk,
            listing_id: nil,
            image_id: nil,
            timestamp: Time.current
          }
          
          # Track failed listing
          @import_stats[:failed_listings] << {
            company: company.shortname,
            item_id: item.pk,
            item_name: item.name,
            error: e.message,
            timestamp: Time.current
          }
          
          # Report to Sentry
          SentryHelper.report_fareharbor_error(e, {
            company_shortname: company.shortname,
            item_id: item.pk,
            item_name: item.name,
            operation: "process_item"
          })
          
          FareharborFailure.create(
            fareharbor_shortname: company.shortname,
            fareharbor_item: item.pk,
            exception: e.inspect,
            backtrace: e.backtrace.join($/),
          )
          logger.info "✓ Logged failure to FareharborFailure table"
          
          person_fareharbor.increment(:failed)
          person_fareharbor.save
          failed_count += 1
        end
      end
      
      TerminalFormatter.print_step("Cleaning up non-existing listings...")
      logger.info "Cleaning up non-existing listings for company: #{company.shortname}"
      deleted = delete_non_existing_in_fareharbor(company)
      
      person_fareharbor.update_columns(
        deleted: deleted,
        end_at: Time.current
      )
      
      TerminalFormatter.print_success("Company update completed: #{updated_count} updated, #{failed_count} failed, #{deleted} deleted")
      logger.info "=== COMPANY UPDATE COMPLETED ==="
      logger.info "Company: #{company.shortname}"
      logger.info "Items processed: #{items_count}"
      logger.info "Successfully updated: #{updated_count}"
      logger.info "Failed: #{failed_count}"
      logger.info "Deleted: #{deleted}"
      logger.info "Completed at: #{Time.current}"
    end

    def delete_non_existing_in_fareharbor(company)
      logger.info "Starting cleanup of non-existing listings for company: #{company.shortname}"
      
      begin
        logger.info "Fetching current items from FareHarbor API for cleanup"
        items = company.items
        fareharbor_item_ids = items.map{|x| x.pk}
        logger.info "✓ Found #{fareharbor_item_ids.count} current item IDs from API"
      rescue => e
        logger.error "✗ Failed to fetch items for deletion check for company '#{company.shortname}': #{e.message}"
        logger.error "API Error Details: #{e.class.name} - #{e.inspect}"
        return 0
      end
      
      logger.info "Finding listings to delete for company: #{company.shortname}"
      listings_to_delete = Listing.by_fareharbor_company(company).where.not(fareharbor_item_id: fareharbor_item_ids)
      count = listings_to_delete.count
      
      if count > 0
        logger.info "Found #{count} listings to delete: #{listings_to_delete.map(&:id)}"
        logger.info "Deleting listings that no longer exist in FareHarbor"
        listings_to_delete.delete_all
        logger.info "✓ Successfully deleted #{count} listings"
      else
        logger.info "✓ No listings need to be deleted"
      end

      count
    end


    def companies(currency)
      logger.info "Fetching companies from FareHarbor API (Currency: #{currency})"
      begin
        companies = fareharbor_company_class(currency).all
        logger.info "✓ Successfully fetched #{companies.count} companies from API"
        companies
      rescue => e
        logger.error "✗ Failed to fetch companies from FareHarbor API: #{e.message}"
        logger.error "API Error Details: #{e.class.name} - #{e.inspect}"
        logger.error "Backtrace: #{e.backtrace.join($/)}"
        raise e
      end
    end

    def find_company(shortname, currency)
      logger.info "Looking up company: #{shortname} (Currency: #{currency})"
      begin
        company = fareharbor_company_class(currency).find(shortname)
        logger.info "✓ Successfully found company: #{shortname}"
        company
      rescue => e
        logger.error "✗ Failed to find FareHarbor company '#{shortname}': #{e.message}"
        logger.error "API Error Details: #{e.class.name} - #{e.inspect}"
        logger.error "This may indicate the company no longer exists in FareHarbor or API credentials are invalid"
        
        # Check if this is a COMPANY_NOT_FOUND error
        if company_not_found_error?(e.message)
          deactivate_company_in_database(shortname, currency, e.message)
        end
        
        # Report to Sentry
        SentryHelper.report_fareharbor_api_error(
          e.message,
          shortname,
          { currency: currency, operation: "find_company" }
        )
        
        nil
      end
    end

    def single_company_name
      ENV['FAREHARBOR_SINGLE_COMPANY_NAME']
    end

    def logger
      @logger ||= begin
        # Create a multi-output logger that writes to both file and console
        file_logger = Logger.new(Rails.root.join('log', "fareharbor_updater.log"), 10, 1000000)
        console_logger = Logger.new(STDOUT)
        
        # Create a custom logger that outputs to both
        MultiLogger.new([file_logger, console_logger])
      end
    end

    def create_person_fareharbor(fareharbor_shortname, fareharbor_items)
      logger.info "Creating PersonFareharbor tracking record for: #{fareharbor_shortname}"
      @person_fareharbor = PersonFareharbor.create(
        fareharbor_shortname: fareharbor_shortname,
        fareharbor_items: fareharbor_items,
        start_at: Time.current,
      )
      if @person_fareharbor.persisted?
        logger.info "✓ Successfully created PersonFareharbor record (ID: #{@person_fareharbor.id})"
      else
        logger.error "✗ Failed to create PersonFareharbor record: #{@person_fareharbor.errors.full_messages}"
      end
    end

    def fareharbor_company_class(currency)
      "::Fareharbor::Company#{currency.downcase.capitalize}".constantize
    end

    def display_import_summary(processed_count, failed_count, total_count, duration)
      TerminalFormatter.print_blank
      TerminalFormatter.print_separator
      TerminalFormatter.print_completed("IMPORT COMPLETED")
      TerminalFormatter.print_success("Processed: #{processed_count}")
      TerminalFormatter.print_error("Failed: #{failed_count}")
      TerminalFormatter.print_chart("Total: #{total_count}")
      TerminalFormatter.print_time("Completed at: #{Time.current}")
      TerminalFormatter.print_time("Duration: #{duration.round(2)} seconds")
      TerminalFormatter.print_separator
      
      # Display detailed statistics
      display_detailed_statistics
      
      logger.info "=== IMPORT COMPLETED ==="
      logger.info "Processed: #{processed_count}, Failed: #{failed_count}, Total: #{total_count}"
      logger.info "Completed at: #{Time.current}"
      logger.info "Duration: #{duration.round(2)} seconds"
    end

    def display_detailed_statistics
      TerminalFormatter.print_blank
      TerminalFormatter.print_header("DETAILED STATISTICS")
      
      # Listing statistics
      TerminalFormatter.print_chart("📊 LISTING STATISTICS")
      TerminalFormatter.print_success("Created: #{@import_stats[:created_listings].count}")
      TerminalFormatter.print_info("Updated: #{@import_stats[:updated_listings].count}")
      TerminalFormatter.print_error("Failed: #{@import_stats[:failed_listings].count}")
      
      # Created listings details
      if @import_stats[:created_listings].any?
        TerminalFormatter.print_blank
        TerminalFormatter.print_header("🆕 CREATED LISTINGS")
        @import_stats[:created_listings].each do |listing|
          TerminalFormatter.print_success("ID: #{listing[:id]} | #{listing[:title]}")
          TerminalFormatter.print_info("URL: #{listing[:url]}")
          TerminalFormatter.print_info("Company: #{listing[:company]} | Item: #{listing[:item_id]}")
        end
      end
      
      # Updated listings details
      if @import_stats[:updated_listings].any?
        TerminalFormatter.print_blank
        TerminalFormatter.print_header("🔄 UPDATED LISTINGS")
        @import_stats[:updated_listings].each do |listing|
          TerminalFormatter.print_info("ID: #{listing[:id]} | #{listing[:title]}")
          TerminalFormatter.print_info("URL: #{listing[:url]}")
          TerminalFormatter.print_info("Company: #{listing[:company]} | Item: #{listing[:item_id]}")
        end
      end
      
      # Error details
      if @import_stats[:errors].any?
        TerminalFormatter.print_blank
        TerminalFormatter.print_header("❌ ERRORS SUMMARY")
        @import_stats[:errors].each do |error|
          TerminalFormatter.print_error("#{error[:type].upcase}: #{error[:entity]} - #{error[:entity_name]}")
          TerminalFormatter.print_warning("Error: #{error[:error]}")
          if error[:entity_id]
            TerminalFormatter.print_info("Entity ID: #{error[:entity_id]}")
          end
          if error[:listing_id]
            TerminalFormatter.print_info("Listing ID: #{error[:listing_id]}")
          end
          if error[:image_id]
            TerminalFormatter.print_info("Image ID: #{error[:image_id]}")
          end
        end
      end
      
      TerminalFormatter.print_separator
    end

    def track_listing_result(listing_result, company_shortname, item_id, item_name)
      if listing_result.is_a?(Hash) && listing_result[:action]
        case listing_result[:action]
        when 'created'
          @import_stats[:created_listings] << {
            id: listing_result[:listing]&.id,
            title: listing_result[:listing]&.title,
            url: listing_result[:listing]&.url,
            company: company_shortname,
            item_id: item_id,
            item_name: item_name,
            timestamp: Time.current
          }
        when 'updated'
          @import_stats[:updated_listings] << {
            id: listing_result[:listing]&.id,
            title: listing_result[:listing]&.title,
            url: listing_result[:listing]&.url,
            company: company_shortname,
            item_id: item_id,
            item_name: item_name,
            timestamp: Time.current
          }
        end
      elsif listing_result.is_a?(Listing)
        # Fallback for direct Listing object
        @import_stats[:updated_listings] << {
          id: listing_result.id,
          title: listing_result.title,
          url: listing_result.url,
          company: company_shortname,
          item_id: item_id,
          item_name: item_name,
          timestamp: Time.current
        }
      end
    end

    private

    def company_not_found_error?(error_message)
      # Check for various COMPANY_NOT_FOUND error patterns
      error_message.include?("not a valid company shortname") ||
      error_message.include?("Invalid application") ||
      error_message.include?("company-shortname-invalid") ||
      error_message.include?("COMPANY_NOT_FOUND")
    end

    def deactivate_company_in_database(shortname, currency, error_message)
      begin
        # Find the company in the database
        db_company = FareharborCompany.find_by(shortname: shortname, currency: currency)
        
        if db_company
          if db_company.active?
            # Deactivate the company
            db_company.update!(active: false)
            logger.warn "⚠️  Deactivated company '#{shortname}' in database due to COMPANY_NOT_FOUND error"
            TerminalFormatter.print_warning("⚠️  Deactivated company '#{shortname}' - no longer exists in FareHarbor API")
            
            # Track this action in import stats
            @import_stats[:errors] << {
              type: "COMPANY_DEACTIVATED",
              entity: "company",
              entity_name: shortname,
              entity_id: db_company.id,
              error: "Company deactivated due to COMPANY_NOT_FOUND error",
              timestamp: Time.current
            }
            
            # Report to Sentry
            SentryHelper.report_fareharbor_company_error(
              shortname,
              "Company deactivated due to COMPANY_NOT_FOUND error",
              { 
                currency: currency, 
                company_id: db_company.id,
                error_message: error_message,
                action: "deactivated"
              }
            )
          else
            logger.info "ℹ️  Company '#{shortname}' is already inactive in database"
          end
        else
          logger.warn "⚠️  Company '#{shortname}' not found in database - cannot deactivate"
        end
      rescue => e
        logger.error "✗ Failed to deactivate company '#{shortname}' in database: #{e.message}"
        TerminalFormatter.print_error("✗ Failed to deactivate company '#{shortname}': #{e.message}")
      end
    end
  end
end
