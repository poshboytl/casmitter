class Api::PresignedUrlsController < ApplicationController
  before_action :authenticate_user!
  
  # Generate a presigned URL for uploading a file to S3
  def upload
    key = params[:key]
    content_type = params[:content_type] || 'application/octet-stream'
    expires_in = parse_expires_in(params[:expires_in])
    
    if key.blank?
      render json: { success: false, error: 'File key is required' }, status: :bad_request
      return
    end

    service = PresignedUploadUrlService.new
    result = service.generate_post_upload_url(key, content_type, expires_in: expires_in)
    
    if result[:success]
      render json: result
    else
      render json: result, status: :internal_server_error
    end
  end

  private

  def parse_expires_in(expires_in)
    return 1.hour if expires_in.blank?
    
    case expires_in.to_s
    when /^(\d+)h$/
      $1.to_i.hours
    when /^(\d+)m$/
      $1.to_i.minutes
    when /^(\d+)s$/
      $1.to_i.seconds
    when /^(\d+)$/
      expires_in.to_i.seconds
    else
      1.hour
    end
  end
end
