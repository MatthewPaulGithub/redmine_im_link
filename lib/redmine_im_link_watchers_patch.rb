require_dependency 'watchers_helper'
# patch the watchers list
module RedmineImLinkWatchersPatch
	def self.included(base)
		base.send(:include, InstanceMethods)
			base.class_eval do
				unloadable
				
				def dostring(user,issue,cf,p1,options={})
					p1 = p1.gsub('%email%',user.mail)
					p1 = p1.gsub('%firstname%',user.firstname)
					p1 = p1.gsub('%lastname%',user.lastname)
					p1 = p1.gsub('%username%',user.login)
					p1 = p1.gsub('%firstinitial%',user.firstname.chr)
					if issue.respond_to?(:subject)
						p1 = p1.gsub('%subject%',issue.subject)
					end
					p1 = p1.gsub('%id%',issue.id.to_s)
					p1 = p1.gsub('%cf%',cf)
					p1 = p1.gsub('%watcherlist%',options[:watcherlist]) unless options[:watcherlist].nil?
					p1 = p1.gsub('%meetingtopic%',options[:meetingtopic]) unless options[:meetingtopic].nil?
					p1 = p1.gsub('%meetinginitmessage%',options[:meetinginitmessage]) unless options[:meetinginitmessage].nil?
					p1.scan(/%cf_(\d+)%/).flatten.each { |id|
						cf_value = issue.custom_field_value(id.to_i) || ""
						p1 = p1.gsub("%cf_#{id}%",cf_value)
					}
					p1.scan(/%cf_\[(\d+)\]%/).flatten.each { |id|
						cf_value = issue.custom_field_value(id.to_i)
						enum_value = CustomFieldEnumeration.find_by_id(cf_value).to_s unless cf_value.nil?
						enum_value ||= ""
						p1 = p1.gsub("%cf_[#{id}]%",enum_value)
					}
					return p1
				end
				
				def build_im_link(user,issue,p1,p2,p3,p4,p5)
					p_name = Setting.plugin_redmine_im_link[p1].to_s
					p_url = Setting.plugin_redmine_im_link[p2].to_s
					p_inc = Setting.plugin_redmine_im_link[p3].to_s
					p_exc = Setting.plugin_redmine_im_link[p4].to_s
					retstring = nil

					if p_name.nil? || p_name.empty? || p_url.nil? || p_url.empty?
						return nil
					end
					
					cftext = ''
					cftextfield = user.custom_values.detect {|v| v.custom_field_id == Setting.plugin_redmine_im_link[p5].to_i}
					cftext = cftextfield.value if !cftextfield.nil?
					if (cftext == '') and (p_url.include? '%cf%') 
						return nil
					elsif (cftext != '') and ((p_url == '') or (!p_url.include? '%cf%'))
						return cftext
					else
						inc = p_inc.split(/[,\s]+/)
						foundinc = inc.any?{|s| user.mail.downcase.include?(s.downcase)}
						
						exc = p_exc.split(/[,\s]+/)
						foundexc = exc.any?{|s| user.mail.downcase.include?(s.downcase)}

						if (foundinc and not foundexc) or (p_url.include? '%cf%')
							retstring = dostring(user,issue,cftext,p_url)
						end
					end
					retstring
				end
				
				def buildlink0(user,issue)
					if user.is_a?(User)
					  name = h(user.name)
					  if user.active? || (User.current.admin? && user.logged?)
						s = ''.html_safe
						linkurl0 = build_im_link(user,issue,'linkname0','linkurl0','includestring0','excludestring0','linkcf0')
						if linkurl0.nil?
							s << link_to_user(user)
						else
							p_type = Setting.plugin_redmine_im_link['linktype0'].to_s
							case p_type
							when '2'
								s << link_to(name,linkurl0,:target => "_blank",:class => user.css_classes)
							else
								s << link_to(name,linkurl0,:class => user.css_classes)
							end
						end
						s
					  else
						name
					  end
					else
					  h(user.to_s)
					end
				end
				
				def buildlink1(user,issue,s)
					linkname1 = Setting.plugin_redmine_im_link['linkname1']
					linkurl1 = build_im_link(user,issue,'linkname1','linkurl1','includestring1','excludestring1','linkcf1')
					if !linkurl1.nil? 
						s << ' '
						p_type = Setting.plugin_redmine_im_link['linktype1'].to_s
						case p_type
						when '2'
							s << link_to(linkname1,linkurl1,:target => "_blank")
						when '3'
							popupwindowsize = Setting.plugin_redmine_im_link['popupwindowsize'].to_s
							popupwindowsize = '1100,600' unless popupwindowsize.include? ','
							s << ('<a href="javascript:void(0)" onclick="OpenPopup(' + "'" + linkurl1 +"'," + popupwindowsize + ")" + '">' + linkname1 + '</a>').html_safe
						when '4'
							popupwindowsize = '100,100'
							s << ('<a href="javascript:void(0)" onclick="OpenPopClose(' + "'" + linkurl1 +"'," + popupwindowsize + ")" + '">' + linkname1 + '</a>').html_safe
						else
							s << link_to(linkname1,linkurl1)
						end
					end
					s
				end

				def buildlink2(user,issue,s)
					linkname2 = Setting.plugin_redmine_im_link['linkname2']
					linkurl2 = build_im_link(user,issue,'linkname2','linkurl2','includestring2','excludestring2','linkcf2')
					if !linkurl2.nil? 
						s << ' '
						p_type = Setting.plugin_redmine_im_link['linktype2'].to_s
						case p_type
						when '2'
							s << link_to(linkname2,linkurl2,:target => "_blank")
						when '3'
							popupwindowsize = Setting.plugin_redmine_im_link['popupwindowsize'].to_s
							popupwindowsize = '1100,600' unless popupwindowsize.include? ','
							s << ('<a href="javascript:void(0)" onclick="OpenPopup(' + "'" + linkurl2 + "'," + popupwindowsize + ")" + '">' + linkname2 + '</a>').html_safe
						when '4'
							popupwindowsize = '1100,600'
							s << ('<a href="javascript:void(0)" onclick="OpenPopClose(' + "'" + linkurl2 + "'," + popupwindowsize + ")" + '">' + linkname2 + '</a>').html_safe
						else
							s << link_to(linkname2,linkurl2)
						end
					end
					s
				end

				def buildmeetinglink(watcher_email_list,issue)
					s = ''.html_safe

					## Currently support MSTeams only
					p_name = Setting.plugin_redmine_im_link['meetinglinkname'].to_s
					p_url = Setting.plugin_redmine_im_link['meetingurl'].to_s
					p_topic = dostring(User.current,issue,'',Setting.plugin_redmine_im_link['meetingtopic'].to_s)
					p_message = dostring(User.current,issue,'',Setting.plugin_redmine_im_link['meetinginitmessage'].to_s)
					p_watchers = watcher_email_list.join(",")

					linkurl = dostring(User.current,issue,'',p_url,{:watcherlist=>p_watchers,:meetingtopic=>p_topic,:meetinginitmessage=>p_message})
					linkurl = URI.escape(linkurl)
					p_type = Setting.plugin_redmine_im_link['meetinglinktype'].to_s
					case p_type
					when '2'
						s << link_to(p_name,linkurl,:target => "_blank")
					when '3'
						popupwindowsize = Setting.plugin_redmine_im_link['popupwindowsize'].to_s
						popupwindowsize = '1100,600' unless popupwindowsize.include? ','
						s << ('<a href="javascript:void(0)" onclick="OpenPopup(' + "'" + linkurl + "'," + popupwindowsize + ")" + '">' + p_name + '</a>').html_safe
					when '4'
						popupwindowsize = '1100,600'
						s << ('<a href="javascript:void(0)" onclick="OpenPopClose(' + "'" + linkurl + "'," + popupwindowsize + ")" + '">' + p_name + '</a>').html_safe
					else
						s << link_to(p_name,linkurl)
					end
					s
				end

				# alias_method_chain :watchers_list, :im_link   -- was this for 3
				alias_method :watchers_list, :watchers_list_with_im_link
				
			end
		end


		module InstanceMethods
			def watchers_list_with_im_link(object)
			remove_allowed = User.current.allowed_to?("delete_#{object.class.name.underscore}_watchers".to_sym, object.project)
			content = ''.html_safe
			watcher_email_list = []
			show_meeting_link = Setting.plugin_redmine_im_link['meetinglinkname'].to_s.eql?('') ? false : true
			show_meeting_link &= Setting.plugin_redmine_im_link['meetingurl'].to_s.eql?('') ? false : true
			show_meeting_link &= object.is_a?(Issue)
			if show_meeting_link
				p_inc = Setting.plugin_redmine_im_link['meetinginclude'].to_s
				p_exc = Setting.plugin_redmine_im_link['meetingexclude'].to_s
				inc = p_inc.split(/[,\s]+/)
				exc = p_exc.split(/[,\s]+/)
			end
			
			lis = object.watcher_users.preload(:email_address).collect do |user|
				if show_meeting_link
					foundinc = inc.any?{|s| user.mail.downcase.include?(s.downcase)}
					foundexc = exc.any?{|s| user.mail.downcase.include?(s.downcase)}
					if (foundinc and not foundexc) or (p_url.include? '%cf%')
						watcher_email_list << user.mail.to_s
					end
				end
				s = ''.html_safe
				s << avatar(user, :size => "16").to_s
				if User.current.allowed_to?(:view_im_links, @project, :global => true)
					s << buildlink0(user,object)
				else
					s << link_to_user(user, :class => 'user')
				end

				# add in rm version for correct display of delete button
				if remove_allowed
					s << ' '
					url = {:controller => 'watchers',
					   :action => 'destroy',
					   :object_type => object.class.to_s.underscore,
					   :object_id => object.id,
					   :user_id => user}
					rmv = (Redmine::VERSION::MAJOR).to_s + '.' + (Redmine::VERSION::MINOR).to_s
					case rmv
					when ('0.0'..'3.3')
						s << link_to(image_tag('delete.png'), url,
						:remote => true, :method => 'delete', :class => "delete")
					else
						s << link_to(l(:button_delete), url,
						:remote => true, :method => 'delete',
						:class => "delete icon-only icon-del",
						:title => l(:button_delete))
					end
				end

	
				if User.current.allowed_to?(:view_im_links, @project, :global => true)
					s = buildlink1(user,object,s)
					s = buildlink2(user,object,s)
				end

				content << content_tag('li', s, :class => "user-#{user.id}")
		    end

			# add in author/assignee if required
			showpeople = Setting.plugin_redmine_im_link['showpeople'].to_s.eql?('true') ? true : false
			if showpeople
				if object.respond_to?(:author)
					if object.respond_to?(:assigned_to)
					  content << ('<h3>'+l(:im_people)+'</h3>').html_safe
					else
					  content << ('<h3>'+l(:im_author)+'</h3>').html_safe
					end
					# author
					s = ''.html_safe
					s << avatar(object.author, :size => "16").to_s
					s << buildlink0(object.author,object)
					s << ' '
					s << image_tag('author.png', :plugin => 'redmine_im_link', :class => 'delete')
					if User.current.allowed_to?(:view_im_links, @project, :global => true)
						s = buildlink1(object.author,object,s)
						s = buildlink2(object.author,object,s)
					end
					content << content_tag('li', s, :class => "user-#{object.author.id}")
				end
			
				# assignee
				if object.respond_to?(:assigned_to)
					unless object.assigned_to.nil? || object.assigned_to.type != 'User'
						s = ''.html_safe
						s << avatar(object.assigned_to, :size => "16").to_s
						s << buildlink0(object.assigned_to,object)
						s << ' '
						s << image_tag('assignee.png', :plugin => 'redmine_im_link', :class => 'delete')
						if User.current.allowed_to?(:view_im_links, @project, :global => true)
							s = buildlink1(object.assigned_to,object,s)
							s = buildlink2(object.assigned_to,object,s)
						end
						content << content_tag('li', s, :class => "user-#{object.assigned_to.id}")
					end
				end
			end

			# Meeting link
			if show_meeting_link and !watcher_email_list.empty?
				content << ('<h3>'+l(:im_meeting)+'</h3>').html_safe
				content << image_tag('icons8-microsoft-teams-2019-48.png', :plugin => 'redmine_im_link')
				content << buildmeetinglink(watcher_email_list,object)
			end

			#footer
			if User.current.allowed_to?(:view_im_link_footer, @project, :global => true)
				footerhtml = Setting.plugin_redmine_im_link['footerhtml'].to_s
				if !footerhtml.blank?
					footer = dostring(User.current,object,'',footerhtml)
					content << ('<br>' + footer).html_safe
				end
			end
			
		    content.present? ? content_tag('ul', content, :class => 'watchers') : content
		end
    end

end

WatchersHelper.send(:include, RedmineImLinkWatchersPatch)
