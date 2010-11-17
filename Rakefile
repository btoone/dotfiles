require 'rake'

# TODO Add more intelligent functionality that creates symlinks for
#      the vim dotfiles (keep it DRY)

desc "Backup and link dotfiles to user's home directory"
task :install do
  Dir['*'].each do |file|
    next if %w[Rakefile README.md].include?(file) || File::directory?(file)
    
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
      end  # case
    else
      # no pre-existing file so just create the link
      puts "linking ~/.#{file}\n\n"
      system %Q{ln -s "$PWD/#{file}" "$HOME/.#{file}"}
    end
  end  # file
  
  # Symlink vim files
  puts "Creating symlinks for vim dotfiles\n\n"
  
  puts "... linking .vim directory\n\n"
  system %Q{ln -s "$PWD/vim" "$HOME/.vim"}
  
  puts "... linking .vimrc\n\n"
  system %Q{ln -s "$PWD/vim/vimrc" "$HOME/.vimrc"}
  
  puts "... linking .gvimrc\n\n"
  system %Q{ln -s "$PWD/gvimrc" "$HOME/.gvimrc"}
end  # task
