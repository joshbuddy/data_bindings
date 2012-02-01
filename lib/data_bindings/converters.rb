module DataBindings

  # Exception raised by invalid #*_http calls.
  class HttpError < RuntimeError
    # The HTTParty::Response object underlying this exception
    attr_reader :response

    def initialize(m, response)
      super m
      @response = response
    end
  end

  # This defines the default readers used.
  module Readers
    include GemRequirement

    # Takes an IO object and reads it's contents.
    # @param [IO] i The IO object to read from
    # @return The contents of the IO object
    def io(i)
      i.rewind
      i.read
    end

    # Takes a file path and returns it's contents.
    # @param [String] path The file path
    # @return The contents of the file
    def file(path)
      File.read(path)
    end

    # Takes a URL and returns it's contents. Uses HTTPParty underlyingly.
    # @param [String] url The URL to request from
    # @param [Hash] opts The options to pass in to HTTPParty
    # @return The body of the response from the URL as a String
    # @see https://github.com/jnunemaker/httparty
    def http(url, opts = {})
      method = opts[:method] || :get
      response = HTTParty.send(method, url, opts)
      if (200..299).include?(response.code)
        response.body
      else
        raise HttpError.new("Bad response: #{response.code} #{response.body}", response)
      end
    end
    gentle_require_gem :http, 'httparty'
  end

  # This defines the default writers used.
  module Writers
    include GemRequirement

    # Takes data and an IO object and writes it's contents to it.
    # @param [String] data The data to be written
    # @param [IO] i The IO object to write to
    def io(data, io)
      io.write(obj)
    end

    # Takes data and a file path and writes it's contents to it.
    # @param [String] data The data to be written
    # @param [String] path The IO object to write to
    def file(data, path)
      File.open(path, 'w') { |f| f << data }
    end

    # Takes a URL and posts the contents of your data to it. Uses HTTPParty underlyingly.
    # @param [String] data The data to send to
    # @param [String] url The URL to send your request to
    # @param [Hash] opts The options to pass in to HTTPParty
    # @see https://github.com/jnunemaker/httparty
    def http(data, url, opts = {})
      method = opts[:method] || :post
      opts[:data] = data
      response = HTTParty.send(method, url, opts)
      unless (200..299).include?(response.code)
        raise HttpError.new("Bad response: #{response.code} #{response.body}", response)
      end
    end
    gentle_require_gem :http, 'httparty'
  end
end