require_dependency 'watchers_helper'
# patch the watchers list
module RedmineImLinkWatchersPatch
	def self.included(base)
		base.send(:include, InstanceMethods)
			base.class_eval do
				unloadable
				
				def dostring(user,cf,p1)
					p1 = p1.gsub('%email%',user.mail)
					p1 = p1.gsub('%firstname%',user.firstname)
					p1 = p1.gsub('%lastname%',user.lastname)
					p1 = p1.gsub('%username%',user.login)
					p1 = p1.gsub('%firstinitial%',user.firstname.chr)
					p1 = p1.gsub('%cf%',cf)
					return p1
				end
				
				def build_im_link(user,p1,p2,p3,p4,p5)
					p_name = Setting.plugin_redmine_im_link[p1].to_s
					p_url = Setting.plugin_redmine_im_link[p2].to_s
					p_inc = Setting.plugin_redmine_im_link[p3].to_s
					p_exc = Setting.plugin_redmine_im_link[p4].to_s
					retstring = nil

					if p_name.nil?
						return nil
					end
					
					cftext = ''
					cftextfield = user.custom_values.detect {|v| v.custom_field_id == Setting.plugin_redmine_im_link[p5].to_i}
					cftext = cftextfield.value if !cftextfield.nil?
					if (cftext == '') and (p_url.include? '%cf%') 
						return nil
					elsif (cftext != '') and (p_url == '')
						return cftext
					else
						inc = p_inc.split(/[,\s]+/)
						foundinc = inc.any?{|s| user.mail.downcase.include?(s.downcase)}
						
						exc = p_exc.split(/[,\s]+/)
						foundexc = exc.any?{|s| user.mail.downcase.include?(s.downcase)}

						if (foundinc and not foundexc) or (p_url.include? '%cf%')

							# p_url = p_url.gsub('%email%',user.mail)
							# p_url = p_url.gsub('%firstname%',user.firstname)
							# p_url = p_url.gsub('%lastname%',user.lastname)
							# p_url = p_url.gsub('%username%',user.login)
							# p_url = p_url.gsub('%firstinitial%',user.firstname.chr)
							# p_url = p_url.gsub('%cf%',cftext)
							# retstring = p_url
							retstring = dostring(user,cftext,p_url)
						end
					end
					retstring
				end
				
				def buildlink1(user,s)
					linkname1 = Setting.plugin_redmine_im_link['linkname']
					linkurl1 = build_im_link(user,'linkname','linkurl','includestring','excludestring','linkcf')
					if !linkurl1.nil? 
						s << ' '
						s << link_to(linkname1,linkurl1)
					end
					s
				end

				def buildlink2(user,s)
					linkname2 = Setting.plugin_redmine_im_link['linkname2']
					linkurl2 = build_im_link(user,'linkname2','linkurl2','includestring2','excludestring2','linkcf2')
					if !linkurl2.nil? 
						s << ' '
						s << link_to(linkname2,linkurl2)
					end
					s
				end

				alias_method_chain :watchers_list, :im_link
				
			end
		end


		module InstanceMethods
			def watchers_list_with_im_link(object)
			remove_allowed = User.current.allowed_to?("delete_#{object.class.name.underscore}_watchers".to_sym, object.project)
			content = ''.html_safe
			
			lis = object.watcher_users.preload(:email_address).collect do |user|
			  s = ''.html_safe
			  s << avatar(user, :size => "16").to_s
			  s << link_to_user(user, :class => 'user')

			  if remove_allowed
				url = {:controller => 'watchers',
					   :action => 'destroy',
					   :object_type => object.class.to_s.underscore,
					   :object_id => object.id,
					   :user_id => user}
				s << ' '
				s << link_to(l(:button_delete), url,
							 :remote => true, :method => 'delete',
							 :class => "delete icon-only icon-del",
							 :title => l(:button_delete))
			  end

	
			  if User.current.allowed_to?(:view_im_links, @project, :global => true)
			  s = buildlink1(user,s)
			  # linkname1 = Setting.plugin_redmine_im_link['linkname']
			  # linkurl1 = build_im_link(user,'linkname','linkurl','includestring','excludestring','linkcf')
			  # if !linkurl1.nil? 
				# s << ' '
				# s << link_to(linkname1,linkurl1)
			  # end

			  s = buildlink2(user,s)
			  # linkname2 = Setting.plugin_redmine_im_link['linkname2']
			  # linkurl2 = build_im_link(user,'linkname2','linkurl2','includestring2','excludestring2','linkcf2')
			  # if !linkurl2.nil? 
				# s << ' '
				# s << link_to(linkname2,linkurl2)
			  # end
			  end

			  content << content_tag('li', s, :class => "user-#{user.id}")
		    end

# add in author/assignee if required

			showpeople = Setting.plugin_redmine_im_link['showpeople'].to_s.eql?('true') ? true : false

			if showpeople
			content << ('<h3>'+l(:im_people)+'</h3>').html_safe

# author
		    content << avatar(object.author, :size => "16").to_s
			content << link_to_user(object.author, :class => 'user')
			content << ' '
			content << image_tag('author.png', :plugin => 'redmine_im_link')

			# content << ' '+l(:im_author)+' '


			if User.current.allowed_to?(:view_im_links, @project, :global => true)
				  content = buildlink1(object.author,content)

			# linkname1 = Setting.plugin_redmine_im_link['linkname']
			# linkurl1 = build_im_link(object.author,'linkname','linkurl','includestring','excludestring','linkcf')
			# if !linkurl1.nil? 
				# content << ' '
				# content << link_to(linkname1,linkurl1)
			# end
			
				  content = buildlink2(object.author,content)
			
			# linkname2 = Setting.plugin_redmine_im_link['linkname2']
			# linkurl2 = build_im_link(object.author,'linkname2','linkurl2','includestring2','excludestring2','linkcf2')
			# if !linkurl2.nil? 
				# content << ' '
				# content << link_to(linkname2,linkurl2)
			#end
			end
			
# assignee
			unless object.assigned_to.nil? || object.assigned_to.type != 'User'
			content << '<br>'.html_safe
		    content << avatar(object.assigned_to, :size => "16").to_s
			content << link_to_user(object.assigned_to, :class => 'user')
			content << ' '
			content << image_tag('assignee.png', :plugin => 'redmine_im_link')
			if User.current.allowed_to?(:view_im_links, @project, :global => true)
				  content = buildlink1(object.assigned_to,content)


			# linkname1 = Setting.plugin_redmine_im_link['linkname']
			# linkurl1 = build_im_link(object.assigned_to,'linkname','linkurl','includestring','excludestring','linkcf')
			# if !linkurl1.nil? 
				# content << ' '
				# content << link_to(linkname1,linkurl1)
			# end
				  content = buildlink2(object.assigned_to,content)

			# linkname2 = Setting.plugin_redmine_im_link['linkname2']
			# linkurl2 = build_im_link(object.assigned_to,'linkname2','linkurl2','includestring2','excludestring2','linkcf2')
			# if !linkurl2.nil? 
				# content << ' '
				# content << link_to(linkname2,linkurl2)
			#end
			end
			end
			end
			
#footer
			if User.current.allowed_to?(:view_im_links, @project, :global => true)
				footerhtml = Setting.plugin_redmine_im_link['footerhtml'].to_s
				if !footerhtml.nil?
					footer = dostring(User.current,'',footerhtml)
					content << ('<br>' + footer).html_safe
				end
			end
			
		    content.present? ? content_tag('ul', content, :class => 'watchers') : content

		end
    end

end

WatchersHelper.send(:include, RedmineImLinkWatchersPatch)

