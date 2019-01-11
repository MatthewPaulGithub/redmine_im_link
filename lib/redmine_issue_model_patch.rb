module RedmineImLink
	module IssuePatch
		def self.included(base)
			base.class_eval do
				unloadable

				def im_link_add_watcher(watcher)
					addwatchers = Setting.plugin_redmine_im_link['addwatchers'].to_s.eql?('true') ? true : false
					return if watcher.nil? || !watcher.is_a?(User) || watcher.anonymous? || !watcher.active? || !addwatchers
					self.add_watcher(watcher) unless self.watched_by?(watcher)
				end

				def im_link_hook
					im_link_add_watcher(self.author)
					im_link_add_watcher(self.assigned_to)
				end

				def im_link_aroundsave_hook
					im_link_hook
					yield
					im_link_hook
				end

				around_save :im_link_aroundsave_hook
			end
		end
	end
end

Issue.send(:include, RedmineImLink::IssuePatch)
