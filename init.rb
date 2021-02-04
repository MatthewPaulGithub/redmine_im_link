  require 'redmine'

  require_dependency 'redmine_issue_model_patch'
  require_dependency 'redmine_im_link_hook'
  require_dependency 'redmine_im_link_watchers_patch'

  Redmine::Plugin.register :redmine_im_link do
  name 'Redmine Im Link'
  author 'Matthew Paul'
  description 'Adds link per watcher to call skype/slack/msteams'
  version '1.0.3'
  url 'https://github.com/MatthewPaulGithub/redmine_im_link'
  author_url 'https://github.com/MatthewPaulGithub'


  settings :default => 
  {
  :addwatchers => true,
  :showpeople => false,
  :footerhtml => '',
  :popupwindowsize => '1100,600',
  :linkname0 => 'Email',
  :linkcf0 => '',
  :linkurl0 => '',
  :linktype0 => '1',
  :includestring0 => 'domain1.com',
  :excludestring0 => 'email1@domain2.com',
  :linkname1 => 'Skype',
  :linkcf1 => '',
  :linkurl1 => 'sip:%email%',
  :linktype1 => '1',
  :includestring1 => 'domain1.com',
  :excludestring1 => 'email1@domain2.com',
  :linkname2 => 'Slack',
  :linkcf2 => '',
  :linkurl2 => 'slack://open',
  :linktype2 => '1',
  :includestring2 => 'domain1',
  :excludestring2 => 'email1@domain2.com',
  :meetinglinkname => 'Meet now',
  :meetingurl => '',
  :meetingtopic => '',
  :meetinginitmessage => '',
  :meetinglinktype => '1',
  :meetinginclude => 'domain1.com',
  :meetingexclude => 'email1@domain2.com'
  }, 
  :partial => 'redmine_im_link/settings'
  
  permission :view_im_links, :redmine_im_link => :view_im_links
  permission :view_im_link_footer, :redmine_im_link => :view_im_link_footer
  
end
