nodemailer = require 'nodemailer'

mailer = nodemailer.createTransport 'SMTP',
  host: 'smtp.mandrillapp.com',
  port: 587,
  authentication: 'login',
  enable_starttls_auto: true,
  auth:
    user: process.env.SHIBE_MANDRILL_USERNAME
    pass: process.env.SHIBE_MANDRILL_PASSWORD

mailer.default_from = 'good@shibe.io'
module.exports = mailer
