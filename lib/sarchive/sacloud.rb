require 'saklient/cloud/api'

module Sarchive
  class Sacloud

    def initialize(token, secret)
      @api = Saklient::Cloud::API::authorize(token, secret)
    end

    def set_zone(zone)
      pp zone
      @api = @api.in_zone(zone)
    end

    def create_archive(disk_id)

      disk = get_disk(disk_id)

      unless disk
        STDERR.puts("ディスク[id=#{disk_id}]が見つかりません。アーカイブの作成を中止します")
        return nil
      end

      archive             = @api.archive.create
      archive.name        = disk.name
      archive.description = 'created by sarchive'
      archive.source      = disk
      archive.save

      unless archive.sleep_while_copying
        STDERR.puts('ディスクからアーカイブへのコピーがタイムアウトまたは失敗しました')
        return nil
      end

      archive
    end

    def delete_archive(disk_id)

    end

    private

    def get_disk(disk_id)
      @api.disk.get_by_id(disk_id.to_s) rescue nil
    end
  end
end
