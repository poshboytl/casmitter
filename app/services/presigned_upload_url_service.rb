# Explicitly require AWS SDK components to avoid autoload issues
require 'aws-sdk-s3'
require 'base64'
require 'openssl'

class PresignedUploadUrlService
  def initialize
    @storage = Rails.application.config.active_storage.service
    begin
      @s3_client = create_s3_client
      @bucket = Rails.application.credentials.dig(:s3, :bucket)
    rescue => e
      Rails.logger.error "Failed to initialize PresignedUploadUrlService: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      raise e
    end
  end

  def generate_post_upload_url(key, content_type, expires_in: 1.hour, size_limit: 100.megabytes)
    begin
      Rails.logger.info "Generating POST upload URL for key: #{key}, content_type: #{content_type}"
      
      # Create presigned POST manually to avoid SDK compatibility issues
      policy_document = {
        expiration: (Time.current + expires_in).iso8601,
        conditions: [
          { bucket: @bucket },
          { key: key },
          { 'Content-Type' => content_type },
          ['content-length-range', 0, size_limit]
        ]
      }.to_json

      policy_base64 = Base64.strict_encode64(policy_document)
      signature = Base64.strict_encode64(
        OpenSSL::HMAC.digest('sha1', 
          Rails.application.credentials.dig(:s3, :secret_access_key), 
          policy_base64)
      )

      upload_url = Rails.application.credentials.dig(:s3, :endpoint) + "/#{@bucket}"
      
      {
        success: true,
        upload_url: upload_url,
        method: 'POST',
        fields: {
          key: key,
          'Content-Type' => content_type,
          AWSAccessKeyId: Rails.application.credentials.dig(:s3, :access_key_id),
          policy: policy_base64,
          signature: signature
        },
        expires_at: Time.current + expires_in
      }
    rescue => e
      Rails.logger.error "Failed to generate POST upload presigned URL: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      { success: false, error: e.message }
    end
  end

  private

  def create_s3_client    
    # Create explicit credentials object to avoid autoload issues
    credentials = Aws::Credentials.new(
      Rails.application.credentials.dig(:s3, :access_key_id),
      Rails.application.credentials.dig(:s3, :secret_access_key)
    )
    
    Aws::S3::Client.new(
      region: Rails.application.credentials.dig(:s3, :region),
      endpoint: Rails.application.credentials.dig(:s3, :endpoint),
      credentials: credentials,
      force_path_style: false
    )
  rescue => e
    Rails.logger.error "Failed to create S3 client: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    raise e
  end
end