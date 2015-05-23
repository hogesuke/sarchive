require 'sarchive'
require 'sarchive/sacloud'
require 'thor'
require 'yaml'

module Sarchive
  class CLI < Thor

    desc 'init', '設定ファイルを作成します'
    option :path, :type => :string, :default => './sarchive.config.yml', :banner => '作成する設定ファイルのパス'
    def init()
    end

    desc 'exec', 'ディスクをアーカイブします'
    option :path, :type => :string, :default => './sarchive.config.yml', :banner => '読み込む設定ファイルのパス'
    def exec()
      unless File.exist?(options[:path])
        STDERR.print('設定ファイルが存在しません')
        exit(false)
      end

      config = YAML.load_file(options[:path])
      token  = config['token']
      secret = config['secret']
      disks  = config['disks']

      unless token and secret
        STDERR.print("tokenまたはsecretが設定されていません\n")
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