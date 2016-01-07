class UserMailer < ApplicationMailer
  default from: "rl.pacht@gmail.com"

  def important_email(tweet)
    tweet.update({email_sent: true})
    @tweet = tweet
    mail(to: "david+tweets@melange.com", subject: 'sent from twitter triage')
  end
end
