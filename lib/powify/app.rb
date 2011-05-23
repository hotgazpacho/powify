require 'fileutils'

module Powify
  class App
    class << self
      AVAILABLE_METHODS = %w(create link new destroy unlink remove restart browse open rename help)
      
      def run(args)
        method = args[0].strip.to_s.downcase
        return help unless AVAILABLE_METHODS.include?(method)
        self.send(method, args[1..-1])
      end
      
      def create(args = [])
        return unless is_powable?
        app_name = args[0] ? args[0].strip.to_s.downcase : File.basename(current_path)
        symlink_path = "#{POWPATH}/#{app_name}"
        FileUtils.ln_s(current_path, symlink_path)
        $stdout.puts "Successfully created pow app #{app_name}!"
        $stdout.puts "Type `pow browse #{app_name}` to open the application in your browser."
      end
      alias_method :link, :create
      alias_method :new, :create
      
      def destroy(args = [])
        return if args[0].nil? && !is_powable?
        app_name = args[0] ? args[0].strip.to_s.downcase : File.base_name(current_path)
        symlink_path = "#{POWPATH}/#{app_name}"
        FileUtils.rm(symlink_path)
        $stdout.puts "Successfully destroyed pow app #{app_name}!"
        $stdout.puts "If this was an accident, type `pow create #{app_name}` to re-create the app."
      end
      alias_method :unlink, :destroy
      alias_method :remove, :destroy
      
      def restart(args = [])
        return unless is_powable?
        app_name = args[0] ? args[0].strip.to_s.downcase : File.basename(current_path)
        symlink_path = "#{POWPATH}/#{app_name}"
        if File.exists?(symlink_path)
          FileUtils.mkdir_p("#{symlink_path}/tmp")
          %x{touch #{symlink_path}/tmp/restart.txt}
          $stdout.puts "Successfully restarted #{app_name}!"
        else
          $stdout.puts "Powify could not find an app to restart with the name #{app_name}"
          Powify::Server.list
        end
      end
      
      def browse(args = [])
        app_name = args[0] ? args[0].strip.to_s.downcase : File.basename(current_path)
        ext = args[1] || extension
        symlink_path = "#{POWPATH}/#{app_name}"
        if File.exists?(symlink_path)
          %x{open http://#{app_name}.#{ext}}
        else
          $stdout.puts "Powify could not find an app to browse with the name #{app_name}"
          Powify::Server.list
        end
      end
      alias_method :open, :browse
      
      def rename(args = [])
        return help if args.empty?
        original_app_name, new_app_name = File.basename(current_path), args[0].strip.to_s.downcase       
        original_app_name, new_app_name = args[0].strip.to_s.downcase, args[1].strip.to_s.downcase if args.size > 1
        original_symlink_path, new_symlink_path = "#{POWPATH}/#{original_app_name}", "#{POWPATH}/#{new_app_name}"
        
        FileUtils.rm(original_symlink_path)
        FileUtils.ln_s(current_path, new_symlink_path)
        
        $stdout.puts "Succesfully renamed #{original_app_name} to #{new_app_name}."
        $stdout.puts "Type `pow browse #{new_app_name}` to open the application in your browser."
      end
      
      private
      def is_powable?
        return true if File.exists?('config.ru') || File.exists?('public/index.html')
       
        $stdout.puts "This does not appear to be a rack app as there is no config.ru."
        $stdout.puts "If you are in a Rails 2 application, try https://gist.github.com/909308"
        $stdout.puts "Pow can also host static apps if there is an index.html in the public dir"
        return false
      end
      
      def current_path
        %x{pwd}.strip
      end
      
      def extension
        return %x{echo $POW_DOMAIN}.strip unless %x{echo $POW_DOMAIN}.strip.empty?
        return %x{echo $POW_DOMAINS}.strip.split(',').first unless %x{echo $POW_DOMAINS}.strip.empty?
        return 'dev'
      end
    end
  end
end