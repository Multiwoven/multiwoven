# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :password, 
  :password_confirmation,  
  :secret, 
  :token, 
  :_key, 
  :crypt, 
  :salt, 
  :certificate, 
  :otp, 
  :ssn,
  :credit_card_number,      
  :card_number,             
  :cvv,                     
  :card_verification,       
  :expiration_date,         
  :authenticity_token,      
  :api_key,                 
  :access_token,            
  :refresh_token,          
  :pin,                     
  :current_password,        
  :new_password,            
  :ssn_last4,               
]
