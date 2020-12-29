# frozen_string_literal: true

require 'discordrb'

require_relative 'secrets'
require_relative 'storage'
require_relative 'bot/extensions'
require_relative 'bot/commands/exclude'
require_relative 'bot/commands/info'
require_relative 'bot/commands/init'
require_relative 'bot/commands/watch'
require_relative 'bot/emoticons'

# Forumlancer's bot.
module Bot
  HOME_SERVER = 713_179_742_978_834_452  # Planet Gammu
  COLOUR = 0xc80f55

  class Bot < Discordrb::Commands::CommandBot
    def initialize
      super token: Secrets::TOKEN, client_id: Secrets::TOKEN, prefix: 'f/'
      run true
      self.watching = 'the forums. f/help'
      servers.values { |s| Storage.ensure_config_ready(s.id) }
    end

    def colour
      COLOUR
    end

    def home
      HOME_SERVER
    end
  end

  BOT = Bot.new
  BOT.include! Exclude
  BOT.include! Info
  BOT.include! Init
  BOT.include! Emoticons
  BOT.include! Watch

  def self.start
    puts 'Starting bot'
    BOT.join
  end
end
