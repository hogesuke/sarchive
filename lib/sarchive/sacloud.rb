require 'saklient/cloud/api'

module Sarchive
  class Sacloud

    def initialize(token, secret, logger)
      @sarchive_tag = 'sarchive_'
      @api          = Saklient::Cloud::API::authorize(token, secret)
      @logger       = logger
    end

    def set_zone(zone)
      @api = @api.in_zone(zone)
    end

    def create_archive(disk_id)

      disk = get_disk(disk_id)

      unless disk
        @logger.error("アーカイブ対象のディスク[id=#{disk_id}]が見つかりません。アーカイブの作成をスキップします")
        return nil
      end

      created_at          = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      archive             = @api.archive.create
      archive.name        = disk.name
      archive.description = "created by sarchive at #{created_at}"
      archive.tags        = [@sarchive_tag]
      archive.source      = disk
      archive.save

      unless archive.sleep_while_copying
        @logger.error("ディスク[id=#{disk.id}, name=#{disk.name}]からアーカイブへのコピーがタイムアウトまたは失敗しました。コンパネでステータスを確認してください")
        return nil
      end

      archive
    end

    def delete_archive(disk_id)
      archive = @api.archive.get_by_id(disk_id.to_s) rescue nil

      unless archive
        @logger.error("削除対象のアーカイブ[id=#{disk_id}]が見つかりません。アーカイブの削除をスキップします")
        return nil
      end

      archive.destroy
    end

    def find_stored_archives(disk_id)
      @api.archive.
          filter_by('SourceDisk.ID', disk_id.to_s).
          with_tag(@sarchive_tag).
          find
    rescue
      nil
    end

    private

    def get_disk(disk_id)
      @api.disk.get_by_id(disk_id.to_s) rescue nil
    end
  end
end
