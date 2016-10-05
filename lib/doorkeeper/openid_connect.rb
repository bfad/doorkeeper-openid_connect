require 'doorkeeper/openid_connect/version'
require 'doorkeeper/openid_connect/engine'

require 'doorkeeper/openid_connect/models/id_token'
require 'doorkeeper/openid_connect/models/user_info'
require 'doorkeeper/openid_connect/models/claims/claim'
require 'doorkeeper/openid_connect/models/claims/normal_claim'

require 'doorkeeper/openid_connect/claims_builder'
require 'doorkeeper/openid_connect/config'

require 'doorkeeper/openid_connect/rails/routes'

require 'doorkeeper'
require 'json/jwt'

module Doorkeeper
  class << self
    prepend OpenidConnect::DoorkeeperConfiguration
  end

  module OpenidConnect
    # TODO: make this configurable
    SIGNING_ALGORITHM = 'RS256'

    def self.configured?
      @config.present?
    end

    def self.installed?
      configured?
    end

    def self.signing_key
      JSON::JWK.new(OpenSSL::PKey.read(configuration.jws_private_key))
    end
  end
end

module Doorkeeper
  module OAuth
    class PasswordAccessTokenRequest
      private

      def after_successful_response
        id_token = Doorkeeper::OpenidConnect::Models::IdToken.new(access_token)
        @response.id_token = id_token
      end
    end
  end
end

module Doorkeeper
  module OAuth
    class AuthorizationCodeRequest
      private

      def after_successful_response
        id_token = Doorkeeper::OpenidConnect::Models::IdToken.new(access_token)
        @response.id_token = id_token
      end
    end
  end
end

module Doorkeeper
  module OAuth
    class TokenResponse
      attr_accessor :id_token
      alias_method :original_body, :body

      def body
        original_body.
          merge({:id_token => id_token.try(:as_jws_token)}).
          reject { |_, value| value.blank? }
      end
    end
  end
end