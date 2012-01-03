require 'rubygems'
require 'hpricot'
require 'open-uri'

=begin
Contains the scraper and notifier.
=end


=begin
Basic scraper class that fetches web pages using Hpricot.
=end
class Scraper
  def get_page(url)
    open(url) { |f| Hpricot(f) }
  end
end

=begin
Contains the logic for polling the site and checking for updates.
=end
class Notifier

  DEFAULT_SCRAPER = Scraper

  DEFAULT_OPTIONS = {
    :interval => 15 * 60,
    # Unlimited.
    :max_attempts => -1
  }

=begin
options is a hash, with the following symbls as keys:

page_urls - an array of URLS for the page

update_check - a lambda that will be called whenever the page is fetched. It is
passed the return value of the scraper's get_page method.

success_callback - callback called when a match is found. It is passed the page.

# Optional
interval - interval for polling in seconds. Defaults to 15 minutes.

scraper - instance of a scraper to use. The scraper must have a get_page(url)
method. The return value is passed directly to the update_check lambda, so it
can return anything you like.

max_attempts - maximum number of times to check the site for an update before
giving up. If this is not provided, we never give up.

failure_callback - callback called when a match is not found and max_attempts
has been exceeded. It is passed the page.

TODO - fail on initialize when mandatory values not provided rather than on
access.
=end
  def initialize(options)
    options = DEFAULT_OPTIONS.merge(options)
    @interval = options[:interval]
    @page_urls = options[:page_urls]
    @update_check = options[:update_check]
    @success_callback = options[:success_callback]
    @failure_callback = options[:failure_callback]
    @max_attempts = options[:max_attempts]

    # We create the default scraper if the parameter is not provided here
    # instead of in DEFAULT_OPTIONS. This is because we want a unique scraper
    # object for each notifier. If notifiers share a scraper, this could cause
    # problems for scrapers that have state.
    @scraper = options[:scraper] || DEFAULT_SCRAPER.new
  end

  # Polls the sites and checks if any of them have updated.
  def run
    attempts = 0
    while (true)
      @page_urls.each do |page_url|
        begin
          log "Scraping page #{page_url}."
          page = @scraper.get_page(page_url)
          if @update_check.call(page)
            log "#{page_url} status changed."
            @success_callback.call(page)
            # Return after success - don't send the e-mail multiple times. Note
            # that it returns after a single page hs been updated.
            return
          else
            log "No update detected."
            if attempts == @max_attempts
              log "Too many attempts. Failure."
              @failure_callback.call(page)
              return
            end
          end
        rescue Exception => e
          # Catch exceptions when getting page
          log "Exception caught: #{e}"
        end
      end
      puts ""
      attempts += 1
      sleep(@interval)
    end
  end

  private

  # Prints a message to stdout with a timestamp.
  def log(msg)
    puts Time.now.strftime("%I:%M:%S %p: #{msg}")
  end

end
