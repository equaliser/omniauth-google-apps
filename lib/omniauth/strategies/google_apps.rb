require 'rack/openid'
require 'omniauth-openid'
require 'openid/gapps'
require 'omniauth-oauth'

module OmniAuth
  module Strategies
    class GoogleApps < OmniAuth::Strategies::OpenID
      option :name, "google_apps"
      option :domain, nil

      def get_identifier
        f = OmniAuth::Form.new(:title => 'Google Apps Authentication')
        f.label_field('Google Apps Domain', 'domain')
        f.input_field('url', 'domain')
        f.to_response
      end

      def identifier
        options[:domain] || request['domain']
      end
      
      protected

       def dummy_app
         lambda{|env| [401, {"WWW-Authenticate" => Rack::OpenID.build_header(
           :identifier => identifier,
           :return_to => callback_url,
           :required => @options[:required],
           :optional => @options[:optional],
           :"oauth[consumer]" => @options[:consumer_key],
           :"oauth[scope]" => @options[:scope], 
           :method => 'post'
         )}, []]}
       end

       def auth_hash
         # Based on https://gist.github.com/569650 by nov
         oauth_response = ::OpenID::OAuth::Response.from_success_response(@openid_response)
         
         consumer = ::OAuth::Consumer.new(
           @options[:consumer_key],
           @options[:consumer_secret],
           :site => 'https://www.google.com',
           :access_token_path  => '/accounts/OAuthGetAccessToken'
         )
         request_token = ::OAuth::RequestToken.new(
           consumer,
           oauth_response.request_token,
           "" # OAuth request token secret is also blank in OpenID/OAuth Hybrid
         )
         @access_token = request_token.get_access_token
         
         OmniAuth::Utils.deep_merge(super(), {
           'uid' => @openid_response.display_identifier,
           'credentials' => {
             'scope' => @options[:scope], 
             'token' => @access_token.token,
             'secret' => @access_token.secret
           }
         })
       
       end
   
      
      
    end
  end
end
