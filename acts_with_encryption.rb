require 'rubygems'
require 'active_resource'
require 'active_support'
require 'openssl'
require 'base64'

module Acts
   module Encryption
      def self.included(base)
         base.extend ClassMethods
      end

      module ClassMethods
         def acts_with_encryption(options = { })
            cattr_accessor :encryption_key
            self.encryption_key = 'R2D2C3PO'
            cattr_accessor :default_options
            self.default_options = { :cipher => 'AES', :block_mode => 'CBC', :keylength => 128 }

            class << self
               alias_method :find_activeresource, :find

               def find(*arguments)
                  results           = find_activeresource(*arguments)
                  attrs             = results.attributes
                  decrypted_results = HashWithIndifferentAccess.new
                  attrs.map do |attr|
                     name  = attr.first
                     value = attr.last
                     unless (name == primary_key || name == "created_at" || name == "updated_at")
                        decrypted_val = decrypt(value)
                        value         = Marshal::load(decrypted_val)
                     end
                     decrypted_results[name] = value
                  end
                  results.attributes = decrypted_results
                  results
               end

               def algorithm(opts)
                  "#{opts[:cipher]}-#{opts[:keylength]}-#{opts[:block_mode]}"
               end

               protected

               def decrypt(value)
                  cipher               = OpenSSL::Cipher::Cipher.new(algorithm(self.default_options))
                  decoded_cipher_value = Base64.decode64(value)
                  cipher.decrypt(self.encryption_key, decoded_cipher_value.slice!(0..15))
                  out = cipher.update(decoded_cipher_value)
                  out << cipher.final
               end
            end
            include InstanceMethods
         end
      end

      module InstanceMethods
         def save
            attrs             = @attributes
            encrypted_results = HashWithIndifferentAccess.new
            attrs.map do |attr|
               name                    = attr.first
               value                   = Marshal::dump(attr.last)
               encrypted_val           = encrypt(value)
               encrypted_results[name] = encrypted_val
            end
            self.attributes = encrypted_results
            super
         end

         protected

         def encrypt(value)
            cipher = OpenSSL::Cipher::Cipher.new(self.class.algorithm(self.default_options))
            iv     = cipher.random_iv
            cipher.encrypt(self.encryption_key, iv)
            cipher_value = cipher.update(value)
            cipher_value << cipher.final
            cipher_value.insert(0, iv)
            Base64.encode64(cipher_value)
         end
      end

   end
end

ActiveResource::Base.send :include, Acts::Encryption

ID = 1

ActiveResource::Formats[:json]
class Story < ActiveResource::Base
   acts_with_encryption
   self.site = "http://localhost:3000"
end

# ActiveResource::HttpMock.respond_to do |mock|
# mock.post   "/services/v3/projects/1/stories.json", {"Accept" => "application/json"}, {:story => { :id => 1, :name => "Matz" }}.to_json, 201, "Location" => "/stories/1.json"
# mock.get    "/services/v3/projects/1/stories/1.json", {"Accept" => "application/json"}, {:story => { :id => 1, :name => "eZYMTFMWC9TzcemOyKxFN64H9Tx3gzYYeLD1ir6hfzU= " }}.to_json
# mock.put    "/services/v3/projects/1/stories/1.json", {"Accept" => "application/json"}, nil, 204
# mock.delete "/stories/1.json", {}, nil, 200
# end

st1             = Story.new
st1.first_name  = "abc"
st1.middle_name = "def"
st1.last_name   = "ghi"
st1.save

st2             = Story.new
st2.first_name  = "klw"
st2.middle_name = "xyz"
st2.last_name   = "pop"
st2.save

fst1 = Story.find(1)
fst2 = Story.find(2)

puts "done"

=begin
module Encryptable
  def included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    (class << self; self; end).class_eval do
      attr_accessor :encryption_options
    end
    
    def encrypt *columns
      self.encryption_options = columns.last.is_a?(Hash) ? columns.pop : {}
      
      (class << self; self; end).class_eval do
        columns.each do |column|
          define_method :"#{column}_with_encryption" do
            decrypt self.send( :"#{column}_without_encryption" )
          end
          alias_method "#{column}_with_encryption", column
          alias_method column, :"#{column}_without_encryption" 
          
          define_method :"#{column}_with_encryption=" do |new_val|
            self.send( :"#{column}_without_encryption=", encrypt new_val )
          end
          alias_method :"#{column}_with_encryption=", :"#{column}="
          alias_method :"#{column}=", :"#{column}_without_encryption=" 
        end
      end
    end
  end
  
  module InstanceMethods
    def decrypt(data)
      rot13(data)
    end
    
    def encrypt(data)
      rot13(data)
    end
    
    def rot13(data)
      data.tr("abcedfghijklmnopqrstuvwxyz",
              "nopqrstuvwxyzabcedfghijklm").tr(
              "ABCEDFGHIJKLMNOPQRSTUVWXYZ",
              "NOPQRSTUVWXYZABCEDFGHIJKLM")
    end
  end=end

