module TopbarHelper

  module_function

  def topbar_props(community:, path_after_locale_change:, user: nil, search_placeholder: nil,
                   locale_param: nil, current_path: nil, landing_page: false, host_with_port:,
                   person_white_label:, view_type:)

    if user && user.guest?
      user = nil
    end
    links = links(community: community, user: user, locale_param: locale_param, host_with_port: host_with_port, person_white_label: person_white_label)

    main_search =
      if FeatureFlagHelper.location_search_available
        MarketplaceService::API::Api.configurations.get(community_id: community.id).data[:main_search]
      else
        :keyword
      end

    search_path_string = PathHelpers.search_url(
      community_id: community.id,
      opts: {
        only_path: true,
      }
    )

    given_name, family_name = *PersonViewUtils.person_display_names(user, community)

    suffix = user && user.is_vendor ? "_vendor" : ""

    white_label = person_white_label&.show
    signup_group_id = SignupGroup.get_default&.id
    no_top_search = landing_page || white_label.try('[]', :no_top_search)
    show_menu = !(person_white_label && view_type == 'custom-list')

    {
      logo: {
        href: show_menu ? PathHelpers.landing_page_path(
          community_id: community.id,
          default_locale: community.default_locale,
          logged_in: user.present?,
          locale_param: locale_param,
          person_white_label: person_white_label,
        ) : nil,
        text: community.name(I18n.locale),
        image: white_label.try('[]', :image_map).try('[]', :wide_logo_lowres) || (community.wide_logo.present? ? community.stable_image_url(:wide_logo, :header) : nil),
        image_highres: white_label.try('[]', :image_map).try('[]', :wide_logo_highres) || (community.wide_logo.present? ? community.stable_image_url(:wide_logo, :header_highres) : nil)
      },
      search: no_top_search ? nil : {
        search_placeholder: search_placeholder,
        mode: main_search.to_s,
      },
      search_path: search_path_string,
      menu: show_menu ? {
        links: links,
        limit_priority_links: Maybe(MarketplaceService::API::Api.configurations.get(community_id: community.id).data)[:limit_priority_links].or_else(nil)
      } : nil,
      locales: landing_page ? nil : locale_props(community, I18n.locale, path_after_locale_change, user.present?),
      avatarDropdown: {
        avatar: {
          image: user&.image.present? ? { url: user.image.url(:thumb) } : { url: ActionController::Base.helpers.image_path("profile_image/thumb/missing#{suffix}.png") },
          givenName: given_name,
          familyName: family_name,
        },
      },
      newListingButton: person_white_label ? nil : {
        text: I18n.t("homepage.index.post_new_listing"),
      },
      i18n: {
        locale: I18n.locale,
        defaultLocale: I18n.default_locale
      },
      marketplace: {
        marketplace_color1: white_label.try('[]', :color1) || CommonStylesHelper.marketplace_colors(community)[:marketplace_color1],
        location: current_path
      },
      user: {
        loggedInUsername: user&.username,
        isAdmin: user&.has_admin_rights?(community) || false,
      },
      unReadMessagesCount: MarketplaceService::Inbox::Query.notification_count(user&.id, community.id),
      signUpPath: signup_group_id && paths.signup_group_path(locale: locale_param, id: signup_group_id),
      showLoginLinks: !person_white_label,
    }
  end

  def links(community:, user:, locale_param:, host_with_port:, person_white_label:)
    user_links = Maybe(community.menu_links)
      .map { |menu_links|
        menu_links
          .map { |menu_link|
            {
              link: menu_link.url(I18n.locale),
              title: menu_link.title(I18n.locale),
              priority: menu_link.sort_priority,
              external: link_external?(menu_link.url(I18n.locale), host_with_port)
            }
          }
      }.or_else([])

    links = [
      {
        link: PathHelpers.landing_page_path(
          community_id: community.id,
          logged_in: user.present?,
          default_locale: community.default_locale,
          locale_param: locale_param,
          person_white_label: person_white_label,
        ),
        title: I18n.t("header.home"),
        priority: -1
      }
    ]
    if !person_white_label
      links << {
        link: paths.about_infos_path(locale: locale_param),
        title: I18n.t("header.about"),
        priority: 0
      }
    end
    if !person_white_label
      links << {
        link: paths.new_user_feedback_path(locale: locale_param),
        title: I18n.t("header.contact_us"),
        priority: !user_links.empty? ? user_links.last[:priority] + 1 : 1
      }
    end

    if !person_white_label && (user&.has_admin_rights?(community) || community.users_can_invite_new_users)
      links << {
        link: paths.new_invitation_path(locale: locale_param),
        title: I18n.t("header.invite"),
        priority: !user_links.empty? ? user_links.last[:priority] + 2 : 2
      }
    end

    if (community.premium_for_everyone && user) || user&.has_admin_rights?(community) || (user&.premium? && user&.premium_valid_date?)
      links << {
        link: "https://memberdeals.com/ownoutdoors/?login=1",
        title: I18n.t("header.exclusive_deals"),
        priority: !user_links.empty? ? user_links.last[:priority] + 2 : 2,
        external: true
      }
    end

    links + user_links
  end

  def locale_props(community, current_locale, path_after_locale_change, is_logged_in)
    community_locales = community.locales.map { |loc_ident|
      Sharetribe::AVAILABLE_LOCALES.find { |app_loc| app_loc[:ident] == loc_ident }
    }.compact.map { |loc|
      {
        locale_name: loc[:name],
        locale_ident: loc[:ident],
        change_locale_uri: PathHelpers.change_locale_path(is_logged_in: is_logged_in,
                                                          locale: loc[:ident],
                                                          redirect_uri: path_after_locale_change)
      }
    }

    { current_locale_ident: I18n.locale,
      current_locale: Maybe(Sharetribe::AVAILABLE_LOCALES.find { |l| l[:ident] == current_locale.to_s })[:language].or_else(current_locale).to_s,
      available_locales: community_locales }
  end

  def missing_profile_image_path
    ActionController::Base.helpers.image_path("profile_image/thumb/missing.png")
  end

  def paths
    @_url_herlpers ||= Rails.application.routes.url_helpers
  end

  def link_external?(url, host_with_port)
    /^(https?:\/\/)?#{host_with_port}((\/|\?).*)?$/.match(url).nil?
  end
end
