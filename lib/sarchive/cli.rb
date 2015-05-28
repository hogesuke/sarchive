require 'sarchive'
require 'sarchive/sacloud'
require 'sarchive/plogger'
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

      config       = YAML.load_file(options[:path])
      token        = config['token']
      secret       = config['secret']
      disks        = config['disks']
      auto_delete  = config['auto_delete']
      log_path     = config['log_path'] ? config['log_path'] : './log/sarchive.log'
      err_log_path = config['err_log_path'] ? config['err_log_path'] : './log/sarchive.err.log'

      logger      = PLogger.new(File.expand_path(log_path), File.expand_path(err_log_path))

      unless token and secret
        logger.error('tokenまたはsecretが設定されていません')
        exit(false)
      end

      if auto_delete['enable']

        counts = auto_delete['store']['counts']
        hours  = auto_delete['store']['hours']

        if counts
          unless counts.is_a?(Integer) and 0 < counts
            logger.error('countsには正の整数を指定してください')
            exit(false)
          end
        end

        if hours
          unless hours.is_a?(Integer) and 0 < hours
            logger.error('hoursには正の整数を指定してください')
            exit(false)
          end
        end

        if counts and hours
          logger.error('auto_deleteのcountsとhoursはどちらか一方のみを指定してください')
          exit(false)
        end
      end

      sacloud = Sarchive::Sacloud.new(token, secret, logger)

      disks.each do |zone, disk_ids|
        unless disk_ids
          next
        end

        sacloud.set_zone(zone)

        disk_ids.each do |disk_id|
          # 作成パート
          archive = sacloud.create_archive(disk_id)

          unless archive
            next
          end

          # 削除パート
          if auto_delete['enable']
            archives = sacloud.find_stored_archives(disk_id)

            items = []
            archives.each do |a|
              a.description.match(/(\d{4})\-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) do |m|
                items.push({ :archive => a, :created_at => m[1] + m[2] + m[3] + m[4] + m[5] + m[6] })
              end
            end

            sorted_items = items.sort do |a, b|
              a[:created_at] <=> b[:created_at]
            end

            counts = auto_delete['store']['counts']
            hours  = auto_delete['store']['hours']

            if counts

              if counts < sorted_items.length
                (sorted_items.length - counts).times do |i|
                  sacloud.delete_archive(sorted_items[i][:archive].id)
                end
              end

            elsif hours

              sorted_items.each do |a|
                at = a[:created_at]
                time = Time.local(at[0, 4], at[4, 2], at[6, 2], at[8, 2], at[10, 2], at[12, 2])

                # 秒に換算し加算
                time += hours * 60 * 60

                if time < Time.now
                  sacloud.delete_archive(a[:archive].id)
                end
              end
            end
          end
        end
      end

      exit (true)
    end
  end

end