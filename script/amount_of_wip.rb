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
    gmail = Gmail.new(mailbox_config['username'], mailbox_config['password'])
    record_wip_count("Unread messages", gmail.inbox.count(:unread))
    record_wip_count("Messages in inbox", gmail.inbox.count)
    record_wip_count("Starred messages", gmail.starred.count)
    record_wip_count("Drafts", gmail.in_mailbox("Drafts").count)
  end
end

def record_wip_count(category, count)
  @wip ||= Hash.new(0)
  @wip[category] += count
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
