require 'sarchive'
require 'sarchive/sacloud'
require 'thor'
require 'yaml'

module Sarchive
  class CLI < Thor

    desc 'init', '設定ファイルを作成します'
    option :path, :type => :string, :default => './sarchive.config.yml', :banner => '作成する設定ファイルのパス'
    def init()
      dest = File.expand_path(options[:path])

      STDOUT.puts('設定ファイルを作成します')

      operation = 'create'

      if File.exist?(dest)
        STDOUT.puts('すでに設定ファイルが存在します。上書きしますか？(y/n)')
        input = STDIN.gets.chomp

        case input
          when /^y(es)?$/i
            operation = 'overwrite'
          else
            operation = 'skip'
        end
      end

      STDOUT.puts("[#{operation}] #{dest}")

      unless operation == 'skip'
        FileUtils.cp(File.expand_path('../sarchive.config.yml.example', __FILE__), dest)
      end

      exit(true)
    end

    desc 'exec', 'ディスクをアーカイブします'
    option :path, :type => :string, :default => './sarchive.config.yml', :banner => '読み込む設定ファイルのパス'
    def exec()
      unless File.exist?(options[:path])
        STDERR.puts('設定ファイルが存在しません')
        exit(false)
      end

      config = YAML.load_file(options[:path])
      token  = config['token']
      secret = config['secret']
      disks  = config['disks']

      unless token and secret
        STDERR.puts('tokenまたはsecretが設定されていません')
        exit(false)
      end

      sacloud = Sarchive::Sacloud.new(token, secret)

      disks.each do |zone, disk_ids|
        unless disk_ids
          next
        end

        sacloud.set_zone(zone)

        disk_ids.each do |id|
          sacloud.create_archive(id)
        end
      end

      exit (true)
    end
  end

end