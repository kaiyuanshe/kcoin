module WebsiteHelpers

  def asset_path(source)
    '/assets/' + settings.sprockets.find_asset(source).digest_path
  end

  def add_sub_template(directory, template)
    # https://stackoverflow.com/questions/10236049/including-one-erb-file-into-another
    ERB.new(File.read("views/#{directory}/#{template}.erb"), nil, nil, '_sub01').result(binding)
  end

  def escape_html(text)
    Rack::Utils.escape_html(text)
  end

end