mongoose = require 'mongoose'

userSchema = new mongoose.Schema
  email: String
  hashedPassword: String
