module Air
  Revision = `git log --pretty=format:'%h' -n 1`

  def self.config
    Settings
  end

  @@cloud_clients = {}

  def self.cloud_clients
    @@cloud_clients
  end

  def self.register_cloud_client(site_id, cloud_client)
    @@cloud_clients[site_id] = {timestamp: Time.now, client: cloud_client}
  end

  def self.get_cloud_client(site_id)
    (@@cloud_clients[site_id] and (Time.now - @@cloud_clients[site_id][:timestamp]) < 23.hours) ? @@cloud_clients[site_id][:client] : nil
  end
end