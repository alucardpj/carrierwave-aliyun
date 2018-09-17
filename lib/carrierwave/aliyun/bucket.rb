module CarrierWave
  module Aliyun
    class Bucket
      PATH_PREFIX = %r{^/}

      def initialize(uploader)
        @aliyun_access_key_id    = uploader.aliyun_access_key_id
        @aliyun_access_key_secret   = uploader.aliyun_access_key_secret
        @aliyun_endpoint     = uploader.aliyun_endpoint
        @aliyun_bucket       = uploader.aliyun_bucket
        @aliyun_region         = uploader.aliyun_region

        # Host for get request
        @aliyun_host = uploader.aliyun_host || "https://#{@aliyun_bucket}.#{@aliyun_endpoint}"

        unless @aliyun_host.include?('//')
          raise "config.aliyun_host requirement include // http:// or https://, but you give: #{@aliyun_host}"
        end
      end

      # 上传文件
      # params:
      # - path - remote 存储路径
      # - file - 需要上传文件的 File 对象
      # - opts:
      #   - content_type - 上传文件的 MimeType，默认 `image/jpg`
      #   - content_disposition - Content-Disposition
      # returns:
      # 图片的下载地址
      def put(path, file, opts = {})
        path.sub!(PATH_PREFIX, '')

        headers = { file: file }
        headers['Content-Type'] = opts[:content_type] || 'image/jpg'
        content_disposition = opts[:content_disposition]
        if content_disposition
          headers['Content-Disposition'] = content_disposition
        end

        res = bucket.put_object(path, headers)
        if res
          path_to_url(path)
        else
          raise 'Put file failed'
        end
      end

      # 下载文件
      # params:
      # - path - remote 存储路径
      # returns:
      # file data
      def get(path, file, opts = {})
        opts[:file] = file
        path.sub!(PATH_PREFIX, '')
        res = bucket.get_object(path, opts)
        if res
          return res
        else
          raise 'Get content faild'
        end
      end

      # 删除 Remote 的文件
      #
      # params:
      # - path - remote 存储路径
      #
      # returns:
      # 图片的下载地址
      def delete(path)
        path.sub!(PATH_PREFIX, '')
        res = bucket.delete_object(path)
        if res
          return path_to_url(path)
        else
          raise 'Delete failed'
        end
      end

      ##
      # 根据配置返回完整的上传文件的访问地址
      def path_to_url(path, opts = {})
        if opts[:thumb]
          thumb_path = [path, opts[:thumb]].join('')
          [@aliyun_host, thumb_path].join('/')
        else
          [@aliyun_host, path].join('/')
        end
      end

      private

      def oss_client
        @oss_client ||= ::Aliyun::OSS::Client.new(
          endpoint: @aliyun_endpoint,
          access_key_id: @aliyun_access_key_id,
          access_key_secret: @aliyun_access_key_secret,
        )
      end

      def bucket
        @bucket ||= oss_client.get_bucket(@aliyun_bucket)
      end
    end
  end
end
