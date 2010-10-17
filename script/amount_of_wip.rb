#!/usr/bin/env ruby
require 'gmail'
require 'yaml'
require 'restfulie'

class Gmail
  def starred
    @starred_mailbox_name ||= imap.list("", "[%]/Starred").first.name
    in_mailbox(@starred_mailbox_name)
  end
end

def main
  sources_file = File.expand_path("../../config/sources.yml", __FILE__)
  sources = YAML.load_file(sources_file)
  log_url = sources['log_to_url']

  record_wip_for_mailboxes(sources)
  print_wip
  post_wip_to_url(log_url) if log_url
end

def record_wip_for_mailboxes(sources)
  sources['Mailboxes'].each do |mailbox_config|
    begin
      gmail = Gmail.new(mailbox_config['username'], mailbox_config['password'])
      source = mailbox_config['username']
      record_wip_count(source, "Unread messages", gmail.inbox.count(:unread))
      record_wip_count(source, "Messages in inbox", gmail.inbox.count)
      record_wip_count(source, "Starred messages", gmail.starred.count)
      record_wip_count(source, "Drafts", gmail.in_mailbox("Drafts").count)
    rescue Net::IMAP::NoResponseError
      STDERR.puts "No response for #{source}. Check the details in config/sources.yml"
    end
  end
end

def record_wip_count(source, category, count)
  @wip ||= {"sampled_at", Time.current}
  @wip[source] ||= Hash.new(0)
  @wip[source][category] += count
end

def print_wip
  puts @wip.inspect
end

def post_wip_to_url(log_url)
  Restfulie.at(log_url).as('application/json').post(@wip)
end

if __FILE__ == $PROGRAM_NAME
  main
end
