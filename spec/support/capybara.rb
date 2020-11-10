# frozen_string_literal: true

require "capybara/rspec"
require "capybara-screenshot/rspec"
require "selenium-webdriver"
require "webdrivers"
require "webdrivers/edgedriver"

Webdrivers.logger.level = :DEBUG if ENV["DEBUG"]

Sniffybara::Driver.run_configuration_file = File.expand_path("VA-axe-run-configuration.json", __dir__)

download_directory = Rails.root.join("tmp/downloads_#{ENV['TEST_SUBCATEGORY'] || 'all'}")
cache_directory = Rails.root.join("tmp/browser_cache_#{ENV['TEST_SUBCATEGORY'] || 'all'}")

Dir.mkdir download_directory unless File.directory?(download_directory)
if File.directory?(cache_directory)
  FileUtils.rm_r cache_directory
else
  Dir.mkdir cache_directory
end

Capybara.register_driver(:parallel_sniffybara) do |app|
  browser_options = ::Selenium::WebDriver::Edge::Options.new

  browser_options.add_preference(:download,
                                 prompt_for_download: false,
                                 default_directory: download_directory)

  browser_options.add_preference(:browser,
                                 disk_cache_dir: cache_directory)

  options = {
    service: ::Selenium::WebDriver::Service.edge(args: { port: 51_674 }),
    browser: :edge,
    options: browser_options
  }
  Sniffybara::Driver.register_specialization(
    :edge, Capybara::Selenium::Driver::EdgeDriver
  )
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end

Capybara.register_driver(:sniffybara_headless) do |app|
  browser_options = ::Selenium::WebDriver::Edge::Options.new

  browser_options.add_preference(:download,
                                 prompt_for_download: false,
                                 default_directory: download_directory)

  browser_options.add_preference(:browser,
                                 disk_cache_dir: cache_directory)

  browser_options.args << "--headless"
  browser_options.args << "--disable-gpu"
  browser_options.args << "--window-size=1200,1200"

  options = {
    service: ::Selenium::WebDriver::Service.edge(args: { port: 51_674 }),
    browser: :edge,
    options: browser_options
  }

  Sniffybara::Driver.register_specialization(
    :edge, Capybara::Selenium::Driver::EdgeDriver
  )
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end

Capybara::Screenshot.register_driver(:parallel_sniffybara) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara::Screenshot.register_driver(:sniffybara_headless) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara.default_driver = ENV["CI"] ? :sniffybara_headless : :parallel_sniffybara
# the default default_max_wait_time is 2 seconds
Capybara.default_max_wait_time = 5
# Capybara uses puma by default, but for some reason, some of our tests don't
# pass with puma. See: https://github.com/teamcapybara/capybara/issues/2170
Capybara.server = :webrick
