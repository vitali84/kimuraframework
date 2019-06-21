#https://collectiveidea.com/blog/archives/2012/01/27/testing-file-downloads-with-capybara-and-chromedriver
module Kimurai
  class Base
    class DownloadHelper
      attr_reader :path, :timeout

      def initialize(path, timeout = 30)
        #path for downloads
        @path = path
        @timeout = timeout
        @mutex = Mutex.new
      end

      def downloads
        @mutex.synchronize do
          Dir[path.join("*")]
        end
      end

      def download
        @mutex.synchronize do
          downloads.first
        end
      end

      def download_content
        @mutex.synchronize do
          wait_for_download
          File.read(download)
        end
      end

      def wait_for_download
        @mutex.synchronize do
          Timeout.timeout(timeout) do
            sleep 0.1 until downloaded?
          end
        end
      end

      def downloaded?
        @mutex.synchronize do
          !downloading? && downloads.any?
        end
      end

      def downloading?
        @mutex.synchronize do
          downloads.grep(/\.crdownload$/).any?
        end

      end

      def clear_downloads
        @mutex.synchronize do
          FileUtils.rm_f(downloads)
        end
      end
    end

  end
end
