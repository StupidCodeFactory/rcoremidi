module RCoreMidi
  class AppPathname < Pathname

    def valid?
      children.select(&:file?).any? do |file|
        file.basename.to_s == RCoreMidi::Commands::New::LIVE
      end
    end

    def connections_file
      config_dir.children.select(&:file?).detect do |file|
        file.basename.to_s == RCoreMidi::Commands::New::CONNECTIONS
      end
    end

    def files

    end

    def config_dir
      children.select(&:directory?).detect do |dir|
        dir.basename.to_s == RCoreMidi::CLI::CONFIG_DIR
      end
    end

    def clips_dir
      children.select(&:directory?).detect do |dir|
        dir.basename.to_s == RCoreMidi::CLI::CLIPS_DIR
      end
    end

    def instruments_dir
      children.select(&:directory?).detect do |dir|
        dir.basename.to_s == RCoreMidi::CLI::INSTRUMENTS_DIR
      end
    end
  end
end
