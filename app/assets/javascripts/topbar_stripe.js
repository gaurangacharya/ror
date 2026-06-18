// Adds Stripe icon to topbar.
var topbar_stripe_icon = {
    init: function () {
        this.cacheDOM();
        this.addIcon();
    },

    cacheDOM: function () {
        this.$container = $('#topbar-container');
        this.$login_links = this.$container.find('.Topbar > .LoginLinks');
        this.$stripe_icon = $('<a href="https://stripe.com/en-US/accept-payments/ownoutdoors" target="_blank" class="topbar__stripe" title="Stripe Verified Partner"></a>');
    },

    addIcon: function () {
        this.$stripe_icon.insertBefore(this.$login_links);
    }
};

