require 'net/http'

module FileUtils
    class << self
      def get_remote_file_size(url)
        begin
          uri = URI.parse(url)
          request = Net::HTTP::Head.new(uri)
          request['User-Agent'] = 'TeahourApp/1.0'
          
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(request)
          end
          
          if response.code == '200'
            return response['content-length'].to_i
          else
            Rails.logger.error "HTTP 错误: #{response.code}"
            return 0
          end
        rescue => e
          Rails.logger.error "无法获取文件大小: #{e.message}"
          return 0
        end
      end
    end
  end