module ApplicationHelper
  def random_hacker_name
    @unix_name ||= ['nobody', 'root', 'daemon', 'tux', 'beastie', 'h4x0r', '1337', 'oneko'].sample
  end
end
