ActionMailer::Base.delivery_method = :smtp

ActionMailer::Base.smtp_settings = {
  :address              => "smtp.gmail.com",
  :port                 => 587,
  :domain               => "gmail.com",
  :user_name            => "rl.pacht@gmail.com",
  :password             => ENV["ps_word"],
  :authentication       => "plain",
  :enable_starttls_auto => true
}


# if Rails.env != 'test'
#   email_settings = YAML::load(File.open("#{Rails.root.to_s}/config/email.yml"))
#   ActionMailer::Base.smtp_settings = email_settings[Rails.env] unless email_settings[Rails.env].nil?
# end