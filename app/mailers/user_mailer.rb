class UserMailer < ApplicationMailer
  default from: "rl.pacht@gmail.com"

  def important_email(tweet)
    tweet.update({email_sent: true})
    @tweet = tweet
    mail(to: "rl.pacht@gmail.com", subject: 'sent from twitter triage')
    # mail(to: "david+tweets@melange.com", subject: 'sent from twitter triage')
  end
end
