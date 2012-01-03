require './poller'
require 'rubygems'
require 'pony'

# Example alert function that sends an e-mail via gmail.
def send_email_alert(sender_email, sender_pass, recipients, subject, body)
  log "Sending e-mail alert."
  recipients.each do |r|
    Pony.mail(:to => r, :via => :smtp, :via_options => {
        :address => 'smtp.gmail.com',
        :port => '587',
        :enable_starttls_auto => true,
        :user_name => sender_email,
        :password => sender_pass,
        :authentication => :plain,
        :domain => "HELO",
    }, :subject => subject, :body => body)
  end
end

def stdout_alert
  puts "ALERT: update found."
end

Notifier.new({
  # Mandatory
  :page_urls => ["http://www.example.com"],
  :update_check => lambda { |page|
    # Check the Hpricot docs for some condition.
    return false
  },
  :success_callback => lambda { |page|
    stdout_alert
  },

  # Optional
  :interval => 3,

  # If one is provided, the other must be provided.
  :max_attempts => 100,
  :failure_callback => lambda { |page| puts "no update found. :(" }

}).run
