#!/usr/bin/env ruby
require 'gmail'
require 'yaml'

class Gmail
  def starred
    @starred_mailbox_name ||= imap.list("", "[%]/Starred").first.name
    in_mailbox(@starred_mailbox_name)
  end
end

def main
  sources_file = File.expand_path("../../config/sources.yml", __FILE__)
  sources = YAML.load_file(sources_file)

  record_wip_for_mailboxes(sources)
  print_wip
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

if __FILE__ == $PROGRAM_NAME
  main
end
