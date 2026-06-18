$(document).on('click', '[data-form-nested-fields]', function(e) {
  e.preventDefault();
  var obj = $($(this).attr('data-form-nested-fields'));
  obj.find("input, select, textarea").each(function() {
    var now = new Date().getTime();
    $(this).attr("name", function() {
      return $(this)
        .attr("name")
        .replace("new_record", now);
    });
  });
  obj.insertBefore(this);
  
  // Check if this is a tax or service fee "New" button and add completed forms to select
  var buttonLink = $(this);
  if (buttonLink.closest('.row').find('.price_tax_fields, .price_service_fee_fields').length > 0) {
    console.log('New tax/service fee button clicked, checking for completed forms');
    setTimeout(function() {
      checkAndAddCompletedFormToSelect(buttonLink);
    }, 100);
  }
  
  return false;
});

// Check if there's a completed form and add it to the select dropdown
function checkAndAddCompletedFormToSelect(buttonLink) {
  // Find the parent container that has the select and forms
  var container = buttonLink.closest('.row').parent();
  var isTaxContainer = container.find('.price_tax_fields').length > 0;
  var isServiceFeeContainer = container.find('.price_service_fee_fields').length > 0;
  
  if (!isTaxContainer && !isServiceFeeContainer) {
    console.log('Not a tax or service fee container');
    return;
  }
  
  console.log('Container type:', isTaxContainer ? 'tax' : 'service fee');
  
  // Find all fieldsets in this container
  var fieldsets = container.find(isTaxContainer ? '.price_tax_fields' : '.price_service_fee_fields');
  
  // Process each fieldset to see if it's complete and not yet in the dropdown
  fieldsets.each(function() {
    var fieldset = $(this);
    var titleField = fieldset.find('input[name*="[title]"]');
    var percentField = fieldset.find('input[name*="[percent]"]');
    var title = titleField.val() ? titleField.val().trim() : '';
    var percent = percentField.val() ? percentField.val().trim() : '';
    
    // Only add if both fields are filled with actual content (not just whitespace)
    if (title && percent && title.length > 0 && percent.length > 0) {
      // Extract unique ID
      var nameAttr = titleField.attr('name');
      var matches = nameAttr.match(/\[(\d+)\]/);
      var uniqueId = matches ? matches[1] : new Date().getTime();
      
      // Skip forms that were just created (have very recent timestamps)
      var currentTime = new Date().getTime();
      var formTime = parseInt(uniqueId);
      var timeDiff = currentTime - formTime;
      
      // If form was created less than 5 seconds ago, it's probably the new empty form - skip it
      if (timeDiff < 5000) {
        console.log('Skipping recently created form (likely empty):', uniqueId, 'time diff:', timeDiff);
        return;
      }
      
      // Check if this form is already in the dropdown
      var selectId = isTaxContainer ? 'listing_tax_ids' : 'listing_service_fee_ids';
      var select = $('#' + selectId);
      
      if (select.length) {
        var existingOption = select.find('option[data-temp-id="' + uniqueId + '"]');
        
        if (existingOption.length === 0) {
          console.log('Adding completed form to select:', title, percent);
          addFormToSelect(select, title, percent, uniqueId, !isTaxContainer);
        } else {
          console.log('Form already in select dropdown');
        }
      }
    } else {
      console.log('Skipping incomplete form - title:', title, 'percent:', percent);
    }
  });
}

// Add a completed form to the select dropdown
function addFormToSelect(select, title, percent, uniqueId, isServiceFee) {
  // Remove the "Add tax/service fee" placeholder if it exists
  select.find('option[disabled]:first').each(function() {
    if ($(this).val() === '' && $(this).text().indexOf('Add') === 0) {
      $(this).remove();
    }
  });
  
  var optionText = title + ' ' + percent + ' (new)';
  
  // Add new option - selected but with empty value to avoid form submission issues
  var newOption = $('<option>', {
    value: '', // Empty value so it doesn't interfere with form submission
    text: optionText,
    'data-temp-id': uniqueId,
    'disabled': false,
    'selected': true
  });
  
  // Add visual styling to distinguish new items
  newOption.css('font-style', 'italic');
  newOption.css('color', '#333'); // Darker color since it's now selectable
  
  select.append(newOption);
  // The option is already marked as selected, no need to manually set val()
  console.log('Added and selected option:', optionText);
}

// Initialize existing forms on page load and populate select dropdown
$(document).ready(function() {
  console.log('Page loaded - processing existing tax and service fee forms');
  
  // Find existing tax and service fee fieldsets and add them to select dropdowns
  $('.price_tax_fields, .price_service_fee_fields').each(function() {
    var fieldset = $(this);
    var titleField = fieldset.find('input[name*="[title]"]');
    var percentField = fieldset.find('input[name*="[percent]"]');
    var title = titleField.val() ? titleField.val().trim() : '';
    var percent = percentField.val() ? percentField.val().trim() : '';
    
    // Only add if both fields are filled
    if (title && percent && title.length > 0 && percent.length > 0) {
      // Extract unique ID from name attribute
      var nameAttr = titleField.attr('name');
      var matches = nameAttr.match(/\[(\d+)\]/);
      var uniqueId = matches ? matches[1] : 'existing_' + new Date().getTime();
      
      // Skip forms that were rendered by Rails (have database IDs - they're already visible as forms)
      // Only process dynamically created forms (created by JavaScript with timestamps)
      if (uniqueId && !isNaN(parseInt(uniqueId)) && parseInt(uniqueId) < 1000000000000) {
        console.log('Skipping Rails-rendered form with database ID:', uniqueId, title, percent);
        return; // Skip this form - it's already visible as a form field
      }
      
      var isServiceFee = fieldset.hasClass('price_service_fee_fields');
      var selectId = isServiceFee ? 'listing_service_fee_ids' : 'listing_tax_ids';
      var select = $('#' + selectId);
      
      if (select.length) {
        console.log('Adding dynamically created form to select:', title, percent);
        
        // Remove the "Add a tax/service fee" placeholder if it exists
        select.find('option[disabled]:first').each(function() {
          if ($(this).val() === '' && $(this).text().indexOf('Add') === 0) {
            $(this).remove();
          }
        });
        
        var optionText = title + ' ' + percent + ' (new)';
        
        // Add option for dynamically created form
        var newOption = $('<option>', {
          value: '', // Empty value to avoid form submission conflicts
          text: optionText,
          'data-temp-id': uniqueId,
          'disabled': false,
          'selected': false
        });
        
        // Styling for new items (created by JavaScript)
        newOption.css('font-style', 'italic');
        newOption.css('color', '#333');
        
        select.append(newOption);
        console.log('Added dynamically created form to select:', optionText);
      }
    }
  });
});

// Handle delete for taxes and service fees only (NOT add-ons)
$(document).on('click', '.price_service_fee_delete, .price_tax_delete', function(e) {
  e.preventDefault();
  e.stopPropagation();
  
  console.log('Delete button clicked - preventing double submission');
  
  var deleteButton = $(this);
  var fieldset = deleteButton.closest('fieldset');
  
  // Prevent multiple clicks during processing
  if (deleteButton.data('processing')) {
    console.log('Already processing, ignoring click');
    return false;
  }
  
  // Mark as processing
  deleteButton.data('processing', true);
  
  // Get confirm message from data attribute or use default
  var confirmMessage = deleteButton.data('confirm_message') || 'Are you sure?';
  
  console.log('Showing confirmation dialog:', confirmMessage);
  
  // Show confirmation dialog
  if (confirm(confirmMessage)) {
    console.log('User confirmed deletion, proceeding');
    // Remove corresponding option from select dropdown if it exists
    removeFromSelectDropdown(fieldset);
    
    // Mark for deletion and hide
    fieldset.find('input.destroy').val('1');
    fieldset.addClass('hidden');
    
    console.log('Fieldset marked for deletion and hidden');
    
    // Check if we need to restore the placeholder
    restorePlaceholderIfNeeded(fieldset);
  } else {
    console.log('User cancelled deletion');
  }
  
  // Reset processing flag
  setTimeout(function() {
    deleteButton.data('processing', false);
  }, 100);
  
  return false;
});

// Remove option from select dropdown when deleting
function removeFromSelectDropdown(fieldset) {
  var titleField = fieldset.find('input[name*="[title]"]');
  if (titleField.length) {
    var nameAttr = titleField.attr('name');
    var uniqueId = null;
    
    // Extract unique ID from the field name
    var matches = nameAttr.match(/\[(\d+)\]/);
    if (matches) {
      uniqueId = matches[1];
      
      // Determine if it's service fee or tax
      var isServiceFee = fieldset.hasClass('price_service_fee_fields');
      var selectId = isServiceFee ? 'listing_service_fee_ids' : 'listing_tax_ids';
      var select = $('#' + selectId);
      
      if (select.length) {
        // Remove the temporary display option
        select.find('option[data-temp-id="' + uniqueId + '"]').remove();
        select.val(''); // Reset to blank selection
        console.log('Removed option from select dropdown');
      }
    }
  }
}

// Restore placeholder option if no items remain
function restorePlaceholderIfNeeded(deletedFieldset) {
  var isServiceFee = deletedFieldset.hasClass('price_service_fee_fields');
  var selectId = isServiceFee ? 'listing_service_fee_ids' : 'listing_tax_ids';
  var select = $('#' + selectId);
  
  if (select.length) {
    // Count remaining visible forms (not deleted/hidden)
    var container = deletedFieldset.closest('.row').parent();
    var fieldsetSelector = isServiceFee ? '.price_service_fee_fields' : '.price_tax_fields';
    var visibleFieldsets = container.find(fieldsetSelector).not('.hidden').not('[style*="display: none"]');
    
    // If no visible fieldsets remain, add placeholder
    if (visibleFieldsets.length <= 1) { // <= 1 because the current one is being deleted
      var placeholderText = isServiceFee ? 'Add a service fee' : 'Add a tax';
      var placeholderOption = $('<option>', {
        value: '',
        text: placeholderText,
        'disabled': true,
        'selected': true
      });
      
      // Only add if no placeholder exists
      if (select.find('option[disabled]:first').length === 0) {
        select.prepend(placeholderOption);
        console.log('Restored placeholder option:', placeholderText);
      }
    }
  }
}

// Keep the original add-on delete handler separate and untouched
$(document).on('click', '.price_add_on_delete', function(e) {
  e.preventDefault();
  var el = $(this);
  var par = el.parent();
  par.find('.destroy').val('1');
  par.addClass('hidden');
});

