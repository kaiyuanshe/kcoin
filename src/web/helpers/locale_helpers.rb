module LocaleHelpers
  # Override this if you need to, say, check for the user's preferred locale.
  def current_locale
    locale = session[:locale] || settings.default_locale
    unless available_locales.include? locale.to_sym
      locale = settings.default_locale
    end
    locale
  end

  def available_locales
    I18n.available_locales
  end

  def l(what, options={})
    I18n.l what, {:locale => current_locale}.merge(options)
  end

  def t(what, options={})
    I18n.t what, {:locale => current_locale}.merge(options)
  end
end