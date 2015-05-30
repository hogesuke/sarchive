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

    desc 'exec', 'ディスクのアーカイブを作成します'
    option :path, :type => :string, :default => './sarchive.config.yml', :banner => '読み込む設定ファイルのパス'
    def exec()
      unless File.exist?(options[:path])
        STDERR.puts('設定ファイルが存在しません')
        exit(false) # ログ出力できないのでここで終了する
      end

      config       = YAML.load_file(options[:path])
      token        = config['token']
      secret       = config['secret']
      disks        = config['disks']
      auto_delete  = config['auto_delete']
      log_path     = config['log_path'] ? config['log_path'] : './log/sarchive.log'
      err_log_path = config['err_log_path'] ? config['err_log_path'] : './log/sarchive.err.log'

      logger      = PLogger.new(File.expand_path(log_path), File.expand_path(err_log_path))

      logger.info("Sarchive start.")

      unless token and secret
        fail('tokenまたはsecretが設定されていません')
      end

      if auto_delete['enable']

        counts = auto_delete['store']['counts']
        hours  = auto_delete['store']['hours']

        if counts
          unless counts.is_a?(Integer) and 0 < counts
            fail('countsには正の整数を指定してください')
          end
        end

        if hours
          unless hours.is_a?(Integer) and 0 < hours
            fail('hoursには正の整数を指定してください')
          end
        end

        if counts and hours
          fail('auto_deleteのcountsとhoursはどちらか一方のみを指定してください')
        end
      end

      sacloud = Sarchive::Sacloud.new(token, secret, logger)

      disks.each do |zone, disk_ids|

        unless disk_ids
          next
        end

        sacloud.set_zone(zone)

        disk_ids.each do |disk_id|

          logger.info("Target zone=[#{zone}] disk_id=[#{disk_id}]")

          # 作成パート
          logger.info("Making...")
          archive = sacloud.create_archive(disk_id)

          unless archive
            logger.error("Making failed. disk_id=[#{disk_id}]")
            next
          end

          logger.info("Making success! archive_id=[#{archive.id}]")

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

              logger.info("Removing... threshold_counts=[#{counts}]")

              if counts < sorted_items.length
                (sorted_items.length - counts).times do |i|
                  ret = sacloud.delete_archive(sorted_items[i][:archive].id)

                  if ret
                    logger.info("Removing success! archive_id=[#{sorted_items[i][:archive].id}]")
                  else
                    logger.error("Removing failed. archive_id=[#{sorted_items[i][:archive].id}]")
                  end
                end
              else
                logger.info("A target doesn't exist.")
              end

            elsif hours

              logger.info("Removing... threshold_hours=[#{hours}]")

              target_items = []
              sorted_items.each do |a|
                at = a[:created_at]
                time = Time.local(at[0, 4], at[4, 2], at[6, 2], at[8, 2], at[10, 2], at[12, 2])

                # 秒に換算し加算
                time += hours * 60 * 60

                if time < Time.now
                  target_items.push(a)
                end
              end

              if target_items.empty?
                logger.info("A target doesn't exist.")
              end

              target_items.each do |a|
                ret = sacloud.delete_archive(a[:archive].id)

                if ret
                  logger.info("Removing success! archive_id=[#{a[:archive].id}]")
                else
                  logger.error("Removing failed. archive_id=[#{a[:archive].id}]")
                end
              end
            end
          end
        end
      end

      logger.info("Sarchive normal end.")
      exit(true)

    rescue => e
      logger.error(e.message)
      logger.info("Sarchive abnormal end.")
      exit(false)
    end
  end

end