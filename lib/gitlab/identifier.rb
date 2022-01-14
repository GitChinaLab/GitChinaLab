# frozen_string_literal: true

# Detect user based on identifier like
# key-13 or user-36
module Gitlab
  module Identifier
    def identify(identifier)
      if identifier =~ /\Auser-\d+\Z/
        # git push over http
        identify_using_user(identifier)
      elsif identifier =~ /\Akey-\d+\Z/
        # git push over ssh
        identify_using_ssh_key(identifier)
      end
    end

    # Tries to identify a user based on a user identifier (e.g. "user-123").
    # rubocop: disable CodeReuse/ActiveRecord
    def identify_using_user(identifier)
      user_id = identifier.gsub("user-", "")

      identify_with_cache(:user, user_id) do
        User.find_by(id: user_id)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # Tries to identify a user based on an SSH key identifier (e.g. "key-123").
    def identify_using_ssh_key(identifier)
      key_id = identifier.gsub("key-", "")

      identify_with_cache(:ssh_key, key_id) do
        User.find_by_ssh_key_id(key_id)
      end
    end

    def identify_with_cache(category, key)
      if identification_cache[category].key?(key)
        identification_cache[category][key]
      else
        identification_cache[category][key] = yield
      end
    end

    def identification_cache
      @identification_cache ||= {
        email: {},
        user: {},
        ssh_key: {}
      }
    end
  end
end
