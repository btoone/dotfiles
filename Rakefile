require 'rake'

task :default => "install"

# TODO: update this similar to homebin rakefile
desc "Installs dotfiles to user's home directory"
task :install do
  Dir['*'].each do |file|
    next if %w[bash Rakefile README.md zsh vendor].include?(file)
    
    original = File.join(ENV['HOME'], ".#{file}")
    
    if File.exists?(original)
      print "File ~/.#{file} exists, replace? [ynq] "  # prompt user
      case $stdin.gets.chomp  # get the user's input
      when 'a'
        # ...
      when 'y'
        puts "Backing up ~/.#{file}\n\n"
        File.rename(original, original+"~")
        # system %Q{rm "$HOME/.#{file}"}
        puts "linking ~/.#{file}\n\n"
        system %Q{ln -s "$PWD/#{file}" "$HOME/.#{file}"}
      when 'q'
        exit
      else
        puts "skipping ~/.#{file}\n\n"
      end
    else
      # no pre-existing file so just create the link
      puts "linking ~/.#{file}\n\n"
      system %Q{ln -s "$PWD/#{file}" "$HOME/.#{file}"}
    end
  end
  
  # Symlink vim files
  puts "Creating symlinks for vim dotfiles\n\n"
  
  puts "... linking .vimrc\n\n"
  system %Q{ln -s "$PWD/vim/vimrc" "$HOME/.vimrc"}
  system %Q{ln -s "$PWD/vim/vimrc.bundles" "$HOME/.vimrc.bundles"}
  
  puts "... linking .gvimrc\n\n"
  system %Q{ln -s "$PWD/gvimrc" "$HOME/.gvimrc"}
end

