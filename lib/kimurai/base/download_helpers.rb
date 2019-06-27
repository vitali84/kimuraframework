#https://collectiveidea.com/blog/archives/2012/01/27/testing-file-downloads-with-capybara-and-chromedriver
# its not thread safe, use with caution
module Kimurai
  class Base
    class DownloadHelper
      attr_reader :path, :timeout

      def initialize(path, timeout = 120)
        #path for downloads
        @path = path
        @timeout = timeout
        @mutex = Mutex.new
      end

      def downloads
          Dir[File.join(path,"*")]
      end

      def before_download_start
        @dir_before_download = downloads
      end

      def downloaded_filename
          downloaded = downloads - @dir_before_download
          if downloaded.size > 1
            raise "more than one file appeared after download"
          elsif  downloaded.size  == 0
            raise "Nothing was downloaded"
          end
          downloaded.first
      end

      def download_content
        file = nil
        filename = nil
        @mutex.synchronize do
          wait_for_download_start #wait until download started
          wait_for_download
          filename = downloaded_filename
          file = File.read(filename)
        end
        {file_name: filename, file_content: file}
      end

      def delete_downloaded
        filename = downloaded_filename
        FileUtils.rm_f(filename)
        filename
      end

      #this means any file appeared
      def wait_for_download_start
        Timeout.timeout(timeout) do
          sleep 0.1 until (downloads - @dir_before_download).size > 0
        end
      end



      def wait_for_download
        Timeout.timeout(timeout) do
          sleep 0.1 until downloaded?
        end
      end

      def downloaded?
        !downloading? && downloads.any?
      end

      def downloading?
          downloads.grep(/\.crdownload$/).any?
      end

      def clear_downloads
        @mutex.synchronize do
          FileUtils.rm_f(downloads)
        end
      end
    end

  end
end
