class UserMailer < ApplicationMailer
  default from: "rl.pacht@gmail.com"

  def follower_email(tweet)
    tweet.update({email_sent: true})
    @follower_count = tweet.users_followers
    mail(to: "david+tweets@melange.com", subject: 'sent from twitter triage')
  end

  def retweet_email(tweet)
    tweet.update({email_sent: true})
    @retweet_count = tweet.retweet_count
    mail(to: "david+tweets@melange.com", subject: 'sent from twitter triage')
  end

  def favorites_email(tweet)
    tweet.update({email_sent: true})
    @favorite_count = tweet.favorite_count
    mail(to: "david+tweets@melange.com", subject: 'sent from twitter triage')
  end
end
