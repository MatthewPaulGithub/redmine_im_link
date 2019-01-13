  require 'redmine'

  require_dependency 'redmine_issue_model_patch'
  require_dependency 'redmine_im_link_hook'
  require_dependency 'redmine_im_link_watchers_patch'

  Redmine::Plugin.register :redmine_im_link do
  name 'Redmine Im Link'
  author 'Matthew Paul'
  description 'Adds link per watcher to call skype/slack/msteams'
  version '1.0.1'
  url 'https://github.com/MatthewPaulGithub/redmine_im_link'
  author_url 'https://github.com/MatthewPaulGithub'


  settings :default => 
  {
  :addwatchers => true,
  :showpeople => false,
  :footerhtml => '',
  :linkname => 'Skype',
  :linkcf => '',
  :linkurl => 'sip:%email%',
  :linktype => '1',
  :includestring => 'domain1.com',
  :excludestring => 'email1@domain2.com',
  :linkname2 => 'Slack',
  :linkcf2 => '',
  :linkurl2 => 'slack://open',
  :linktype2 => '1',
  :includestring2 => 'mpaul@cityassets.com',
  :excludestring2 => 'Include All'
  }, 
  :partial => 'redmine_im_link/settings'
  
  permission :view_im_links, :redmine_im_link => :view_im_links
  permission :view_im_link_footer, :redmine_im_link => :view_im_link_footer
  
end
